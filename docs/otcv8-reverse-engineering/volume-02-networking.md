# Volume 2 — Networking

> **Status:** 🟡 Em progresso — primeira versão documentada
> **Protocolo alvo:** TFS 8.60 (client version 860)
> **Fonte primária:** `client/src/client/protocolgameparse.cpp`

---

## 1. Visão geral

O networking do OTCv8 divide-se em duas conexões TCP independentes:

```
┌─────────────┐     RSA + XTEA      ┌─────────────┐
│ Login Server│ ←─────────────────→ │ Protocol.gd │  porta 7171
│  (7171)     │   char list + IP    │  (login)    │
└─────────────┘                     └─────────────┘
                                           │
                                    XTEA key session
                                           ▼
┌─────────────┐     RSA + XTEA      ┌─────────────┐
│ Game Server │ ←─────────────────→ │ GameProtocol│  porta 7172
│  (7172)     │   opcodes de jogo   │  + Reader   │
└─────────────┘                     └─────────────┘
```

### Por que duas conexões?

O Tibia clássico separa autenticação (login server) do mundo (game server). O login server retorna IP/porta do game server e a sessão XTEA é reutilizada na segunda conexão.

### Classes OTC responsáveis

| Classe OTC | Responsabilidade | Godot equivalente |
|---|---|---|
| `ProtocolLogin` | Login RSA, lista de chars | `Protocol.gd` |
| `ProtocolGame` | Handshake, loop de opcodes | `GameProtocol.gd` |
| `InputMessage` | Leitura tipada de bytes | `StreamPeerBuffer` + `ProtocolReader.gd` |
| `OutputMessage` | Escrita de pacotes | `StreamPeerBuffer.put_*` |
| `parseMessage()` | Dispatcher central | `GameProtocol._parse_game_opcode()` + `OpcodeDispatcher` |

---

## 2. Fluxo de conexão completo

### 2.1 Login Server (porta 7171)

```
Cliente                              Servidor
   │── TCP connect ──────────────────→│
   │←── challenge (se GameChallengeOnLogin) ─│
   │── 0x01 + OS + version + dat/spr sig ──→│
   │── RSA block (XTEA + account + pass) ──→│
   │←── 0x14 erro OU 0x64 char list ────────│
```

**Godot:** `Protocol.gd` → `GlobalNetwork.connect_to_login_server()`

### 2.2 Game Server (porta 7172)

```
Cliente                              Servidor
   │── TCP connect ──────────────────→│
   │←── 0x1F challenge (timestamp + random) ─│
   │── 0x0A + RSA block (XTEA + acc + char + pass + challenge) ──→│
   │←── 0x0A login OK (player id, beat) ────│
   │←── 0x64 full map ──────────────────────│
   │←── 0x78 inventory, 0x83 effects... ──│
```

**Godot:** `GameProtocol.gd` → `GlobalNetwork.connect_to_game_server()`

### 2.3 Criptografia

| Camada | Algoritmo | Quando |
|---|---|---|
| Handshake | RSA 1024-bit (e=65537) | Primeiro pacote de login e game |
| Sessão | XTEA 128-bit (4× u32) | Todos os pacotes após handshake |
| Adler32 | Checksum opcional | `GameProtocolChecksum` (≥840) — ativo no 860 |

**Por que RSA só no primeiro pacote?** A chave XTEA é trocada de forma segura; depois disso a sessão usa simetria rápida.

**Godot:** `Rsa.gd`, `Xtea.gd`

---

## 3. Loop de mensagens — `parseMessage()`

**Arquivo:** `protocolgameparse.cpp:52`

```cpp
while (!msg->eof()) {
    opcode = msg->getU8();
    // 1. Opcode 0x00 = script Lua inline (ignorar em Godot)
    // 2. processGameStart() se opcode > FirstGameOpcode
    // 3. Tentar handler Lua (onOpcode) — restaurar posição se falhar
    // 4. switch(opcode) → parseXxx(msg)
}
```

### Decisões de design no OTC

| Decisão | Motivo |
|---|---|
| Handler Lua antes do C++ | Módulos podem interceptar opcodes custom (ex: `GameExtendedOpcode` ≥860) |
| `processGameStart()` automático | Inicializa UI de jogo no primeiro opcode pós-login |
| try/catch no loop | Desync não derruba o cliente — loga e continua |

### Godot equivalente

```
GameProtocol._handle_game_message()
  → decrypt XTEA
  → loop: _parse_game_opcode(opcode)
      → 0x0A/0x14/0x64: handlers diretos
      → demais: OpcodeDispatcher.dispatch() → GameOpcodeReader
```

**Diferença:** Godot não tem handler Lua; `GameExtendedOpcode` (0x32 / 50) não está implementado.

---

## 4. Features do protocolo 8.60

**Arquivo:** `client/modules/game_features/features.lua`

Features **ativas** em `version >= 860` (e dependências de versões anteriores):

| Feature | Desde | Impacto no parse |
|---|---|---|
| `GameLooktypeU16` | 770 | Outfit looktype = u16 |
| `GamePlayerAddons` | 780 | Outfit +1 byte addons |
| `GameLoginPacketEncryption` | 770 | RSA no login |
| `GameProtocolChecksum` | 840 | Adler32 nos pacotes |
| `GameChallengeOnLogin` | 841 | Challenge no login |
| `GameCreatureEmblems` | 854 | +1 byte emblem (criatura desconhecida) |
| `GameAttackSeq` | 860 | Sequência de ataque |
| `GameSpellList` | 860 | Cooldowns de spell |
| `GameBiggerMapCache` | 860 | Viewport 25×20 |
| `GameExtendedOpcode` | 860 | Opcodes estendidos (shop, etc.) |

Features **NÃO ativas** em 860 (relevantes para não ler bytes extras):

| Feature | Desde | Se lesse por engano... |
|---|---|---|
| `GameThingMarks` | 1000 | +1 byte mark em items/criaturas |
| `GameCountU16` | — | count seria u16 em vez de u8 |
| `GameNewWalking` | — | +groundSpeed/blocking no tile; +stepDuration no 0x6D |
| `GameEnvironmentEffect` | 910 | +u16 no tile description |
| `GameCreaturesMana` | — | +bytes de mana em criaturas |
| `GameTibia12Protocol` | 1200 | dezenas de campos extras |

> **Regra de ouro:** para 8.60, usar `features.lua` como filtro — não copiar `getItem()`/`getCreature()` completos do C++ sem verificar cada `if (g_game.getFeature(...))`.

---

## 5. Opcode `0x0A` — Login OK

**OTC:** `parseLogin()` — `protocolgameparse.cpp:600`

### Layout de bytes (8.60)

| Campo | Tipo | Notas |
|---|---|---|
| player_id | u32 | ID da criatura do jogador local |
| server_beat | u16 | ms por tick do servidor (tipicamente 50) |
| can_report_bugs | u8 | 0 ou 1 |

Campos **não lidos** em 860 (features posteriores desativadas):

- `GameNewSpeedLaw` (≥981): 3× double
- protocol ≥1054: can change pvp frame
- protocol ≥1058: expert mode
- `GameIngameStore` (≥1080): URL + coins packet size

### Godot

`GameOpcodeReader.parse_login()` → `PlayerController.bind_login()`

---

## 6. Opcode `0x64` — Full Map

**OTC:** `parseMapDescription()` — `protocolgameparse.cpp:1084`

### Sequência

```
1. applyWideAwareRange()     → 12,9,12,10 (primeira vez)
2. pos = getPosition(msg)    → u16 x, u16 y, u8 z
3. set player position (se primeiro mapa)
4. g_map.setCentralPosition(pos)
5. setMapDescription(msg, x-left, y-top, z, width, height)
6. m_mapKnown = true
```

### Viewport 25×20

**Por que não 18×14?** O TFS deste repositório e o OTCv8 com `GameBiggerMapCache` usam:

```
left=12, top=9, right=12, bottom=10
width  = left + right + 1 = 25
height = top + bottom + 1  = 20
```

**OTC:** `applyWideAwareRange()` em `protocolgameparse.cpp:41`
**TFS:** `server/src/map.h` → `clientMapWidth=25`, `clientMapHeight=20`
**Godot:** `MapState.gd` → `MAP_WIDTH=25`, `MAP_HEIGHT=20`

> Se o viewport estiver errado, o parser consome bytes a mais ou a menos → desync em cascata.

---

## 7. Parse do mapa — cadeia de funções

### 7.1 `setMapDescription()`

**Arquivo:** `protocolgameparse.cpp:3239`

```
Para cada andar z no range:
  setFloorDescription(msg, x, y, z, width, height, offset, skip)
```

**Lógica de andares:**

| Condição | start_z | end_z | z_step |
|---|---|---|---|
| z > 7 (underground) | z-2 | min(z+2, 15) | +1 |
| z ≤ 7 (surface) | 7 | 0 | -1 |

**Por que?** Em superfície o cliente vê andares 7→0 (descendo). Underground vê z-2 até z+2.

**Godot:** `MapParser.read_map_description()` — espelha esta lógica.

### 7.2 `setFloorDescription()`

```
Para nx em 0..width, ny em 0..height:
  tilePos = (x+nx+offset, y+ny+offset, z)
  Se skip == 0: skip = setTileDescription(msg, tilePos)
  Senão: cleanTile(tilePos); skip--
```

**Skip markers:** o servidor envia `0xFFxx` para pular N tiles vazios sem enviar dados. O contador `skip` propaga entre tiles.

### 7.3 `setTileDescription()` — **função crítica**

**Arquivo:** `protocolgameparse.cpp:3274`

```
1. cleanTile(position)
2. Se peekU16 >= 0xFF00: return getU16() & 0xFF   ← skip de tile inteiro
3. [860] NÃO lê groundSpeed/blocking (GameNewWalking off)
4. [860] NÃO lê environment effect (GameEnvironmentEffect off)
5. Loop stackPos 0..255:
     Se peekU16 >= 0xFF00: return getU16() & 0xFF  ← fim do tile
     Se stackPos > MAX_THINGS(10): traceError (continua!)
     thing = getThing(msg)
     g_map.addThing(thing, position, stackPos)
6. return 0
```

**Por que loop até 256?** O terminador é o marker `0xFFxx`, não um count. O OTC loga erro em stack > 10 mas **não para** — continua lendo até o marker.

**Godot:** `MapParser.read_tile_description()` — mesma lógica; `MAX_THINGS_PER_TILE = 10`.

---

## 8. `getThing()` — dispatcher de things

**Arquivo:** `protocolgameparse.cpp:3370`

```
id = getU16()
Se id == 0: throw (desync fatal)
Se id ∈ {0x61, 0x62, 0x63}: getCreature(msg, id)
Se id == 0x60: getStaticText(msg, id)    ← OTClient only
Senão: getItem(msg, id, false)
```

| Marker | Valor | Significado |
|---|---|---|
| `UnknownCreature` | 0x61 (97) | Criatura nova (id + nome + dados completos) |
| `OutdatedCreature` | 0x62 (98) | Criatura conhecida (só id + dados) |
| `Creature` | 0x63 (99) | Criatura vira (id + direction) |
| `StaticText` | 0x60 (96) | Texto estático no mapa |

**Godot:** `ThingReader.read_thing()` — mesmos markers.

---

## 9. `getItem()` — **fonte do desync ativo**

**Arquivo:** `protocolgameparse.cpp:3600`

### Layout OTC (código C++)

```cpp
if (id == 0) id = getU16();
// GameThingMarks (≥1000): +u8 mark          ← OFF em 860

if (stackable || chargeable)
    count = getU8();                          // GameCountU16 off → u8
else if (fluid || splash)
    count = getU8();

// GameItemAnimationPhase (≥910): ...        ← OFF em 860
// GameItemTooltip: ...                       ← OFF
// GameItemCustomAttributes: ...              ← OFF
```

### Layout TFS (o que o servidor **envia**)

**Arquivo:** `server/src/networkmessage.cpp:120`

```cpp
add<uint16_t>(clientId);
if (stackable)
    addByte(count);
else if (splash || fluidContainer)
    addByte(fluidType);
// NÃO envia byte para chargeable isolado
```

### Discrepância OTC vs TFS (chargeable)

Análise do `Tibia.dat` deste projeto (2026-07-30):

- **32 itens** têm `ATTR_CHARGEABLE` sem `ATTR_STACKABLE` (ex.: 1014, 1277, 3019…)
- **OTC** lê byte de count para `stackable || chargeable`
- **TFS** (`networkmessage.cpp`) envia count só para `stackable` ou fluid/splash

**Decisão Godot:** seguir **OTC** (mesmo `.dat` que o OTCv8 usa). O OTC conecta neste servidor; o cliente deve espelhar `getItem()` do OTC, não só o TFS.

```gdscript
# ThingReader.read_item — alinhado a protocolgameparse.cpp:3613
if stackable or chargeable: count = u8
elif fluid or splash: count = u8
```

### Diagnóstico do desync (`erro.md`)

Sintoma: `too many things` no tile do **player** `(32367, 32232, 0)` com stack 48+.

Interpretação: o parser não encontrou o marcador `0xFFxx` de fim de tile — leu lixo como thing IDs (ex.: 47520 = `0xB9A0`).

**Ferramentas adicionadas (Godot):**

| Arquivo | Função |
|---|---|
| `src/dev/MapDesyncDiagnostics.gd` | Log do primeiro desync: tile, stack, hex dump, último tile OK |
| `MapParser.gd` | Fail-fast em stack > 10; valida item id no `.dat`; consome marcador final do mapa |
| `ThingReader.gd` | Modo `strict` no parse do mapa; `is_valid_item_id()` |

**Próximo teste:** fazer login e copiar o bloco `MapDesync:` do console — indica o **primeiro** tile errado (não o 48º).

---

## 10. `getCreature()` — layout 8.60

**Arquivo:** `protocolgameparse.cpp:3414`

### 0x61 — UnknownCreature

| Campo | Tipo | 860? |
|---|---|---|
| remove_id | u32 | ✅ |
| id | u32 | ✅ |
| creature_type | u8 | ❌ (< 910, inferido do id) |
| name | string | ✅ |
| health_percent | u8 | ✅ |
| direction | u8 | ✅ |
| outfit | ver §10.1 | ✅ |
| light_level | u8 | ✅ |
| light_color | u8 | ✅ |
| speed | u16 | ✅ |
| skull | u8 | ✅ |
| shield | u8 | ✅ |
| emblem | u8 | ✅ (≥854, só unknown) |
| unpass | u8 | ✅ (≥854) |

### 0x62 — OutdatedCreature (known)

| Campo | Tipo |
|---|---|
| id | u32 |
| + mesmos campos de 0x61 exceto remove_id, name, emblem |

### 0x63 — Creature (turn only)

| Campo | Tipo |
|---|---|
| id | u32 |
| direction | u8 |

**Godot:** `ThingReader.read_creature()` — implementado conforme tabela acima.

### 10.1 `getOutfit()` — 8.60

| Campo | Tipo | Feature |
|---|---|---|
| look_type | u16 | GameLooktypeU16 (≥770) |
| head, body, legs, feet | u8 ×4 | se look_type ≠ 0 |
| addons | u8 | GamePlayerAddons (≥780) |
| look_type_ex | u16 | se look_type == 0 |

Sem mount, wings, aura, shader (≥870+).

---

## 11. `getMappedThing()` — referência a thing existente

**Arquivo:** `protocolgameparse.cpp:3388`

Usado em `0x6B`, `0x6C`, `0x6D` (change/delete/move).

```
x = getU16()
Se x != 0xFFFF:
    pos = (x, getU16(), getU8())
    stackpos = getU8()
    thing = g_map.getThing(pos, stackpos)
Senão:
    id = getU32()
    thing = g_map.getCreatureById(id)
```

**Por que 0xFFFF?** Criaturas se movem entre tiles; referenciar por ID é mais confiável que stackpos.

**Godot:** `ProtocolReader.read_mapped_thing()` + `CreatureManager.find_location()`

---

## 12. Opcodes pós-login — tabela 8.60

### Mapa

| Opcode | Nome OTC | Função | Godot |
|---|---|---|---|
| `0x64` | FullMap | Mapa completo | `MapParser.parse_full_map()` ✅ |
| `0x65` | MapTopRow | Scroll norte | `GameOpcodeReader` ✅ |
| `0x66` | MapRightRow | Scroll leste | ✅ |
| `0x67` | MapBottomRow | Scroll sul | ✅ |
| `0x68` | MapLeftRow | Scroll oeste | ✅ |
| `0x69` | UpdateTile | Tile único | `MapParser.read_update_tile()` ✅ |
| `0x6A` | CreateOnMap | Add thing | `MapManager.add_thing_to_tile()` ✅ |
| `0x6B` | ChangeOnMap | Transform thing | skip mapped + skip thing ⚠️ |
| `0x6C` | DeleteOnMap | Remove thing | `MapManager.remove_thing_at()` ✅ |
| `0x6D` | MoveCreature | Mover criatura | `CreatureManager.move()` ✅ |

### Inventário e containers

| Opcode | Nome | Godot |
|---|---|---|
| `0x78` | AddInventoryItem | `InventoryManager` ✅ |
| `0x79` | RemoveInventoryItem | ✅ |
| `0x6E` | OpenContainer | `ContainerManager.open()` ✅ |
| `0x6F` | CloseContainer | ✅ |
| `0x70` | CreateContainer | `add_item()` ✅ |
| `0x71` | ChangeInContainer | `update_item()` ✅ |
| `0x72` | DeleteInContainer | `remove_item()` ✅ |

### Efeitos e criaturas

| Opcode | Nome | Godot |
|---|---|---|
| `0x83` | GraphicalEffect | `EffectManager` ✅ |
| `0x84` | TextEffect | ✅ |
| `0x85` | MissileEffect | ✅ |
| `0x8C` | CreatureHealth | `CreatureManager.update_health()` ✅ |
| `0x8D` | CreatureLight | `update_light()` ✅ |
| `0x8E` | CreatureOutfit | `apply_outfit()` ✅ |
| `0x8F` | CreatureSpeed | `update_speed()` ✅ |
| `0x90` | CreatureSkull | skip u32+u8 ✅ |
| `0x91` | CreatureParty | skip u32+u8 ✅ |
| `0xA0` | PlayerStats | ⬜ |
| `0xB4` | CreatureTurn | ⬜ |
| `0xB5` | CancelWalk | `CreatureManager.cancel_walk()` ✅ |
| `0xBE` | FloorChangeUp | `MapParser.read_floor_change_up()` ✅ |
| `0xBF` | FloorChangeDown | `read_floor_change_down()` ✅ |

---

## 13. `0x6D` — MoveCreature

**OTC:** `parseCreatureMove()` — `protocolgameparse.cpp:1250`

```
thing = getMappedThing(msg)
newPos = getPosition(msg)
[860] SEM stepDuration (GameNewWalking off)
removeThing(thing) from old tile
addThing(thing, newPos)
```

**Por que remove + add em vez de atualizar posição?** O OTC mantém things indexados por tile/stackpos. Mover = remover da estrutura antiga e inserir na nova.

**Godot:** `CreatureManager.move()` — remove de `old_tile.creatures`, append em `new_tile.creatures`, atualiza `creature_index` e `player_pos`.

**Erro em cascata:** se o parse do mapa (`0x64`) desynca, criaturas não são registradas corretamente → `0x6D` falha com "tile antigo não encontrado".

---

## 14. Arquitetura Godot — fluxo atual

```
NetworkManager (TCP)
    ↓ packet_received
GameProtocol._handle_game_message()
    ↓ decrypt XTEA
    ↓ loop opcodes
OpcodeDispatcher.dispatch(opcode, buffer, world, move_context)
    ↓ move_context["world"] = world
GameOpcodeReader.consume_opcode()
    ↓ handlers delegam para managers quando world != null
TibiaGameWorld
    ├── MapManager      → MapState (tiles, player_pos)
    ├── CreatureManager → move, outfit, health
    ├── EffectManager
    ├── InventoryManager
    ├── ContainerManager
    └── PlayerController → player_id, can_walk()
```

### Sinais emitidos

| Evento | Signal | Consumidor |
|---|---|---|
| Mapa parseado | `map_parsed` | LoginScreen → GameHUD |
| Mundo pronto | `world_ready` | GlobalNetwork.session_world |
| Criatura moveu | `creature_moved` | MapView |
| Mapa atualizado | `map_updated` | MapView.render() |
| Inventário | `inventory_updated` | GameHUD slots |

---

## 15. Mapeamento completo OTC → Godot

| Função OTC | Arquivo Godot | Status |
|---|---|---|
| `parseMessage()` | `GameProtocol._parse_game_opcode()` | ✅ |
| `parseLogin()` | `GameOpcodeReader.parse_login()` | ✅ |
| `parseMapDescription()` | `MapParser.parse_full_map()` | ⚠️ desync |
| `setMapDescription()` | `MapParser.read_map_description()` | ⚠️ |
| `setTileDescription()` | `MapParser.read_tile_description()` | ⚠️ |
| `getThing()` | `ThingReader.read_thing()` | ⚠️ |
| `getItem()` | `ThingReader.read_item()` | ⚠️ |
| `getCreature()` | `ThingReader.read_creature()` | ✅ |
| `getMappedThing()` | `ProtocolReader` + managers | ✅ |
| `parseCreatureMove()` | `CreatureManager.move()` | ✅ (depende do mapa) |
| `parseAddInventoryItem()` | `InventoryManager.add_item()` | ✅ |
| `parseOpenContainer()` | `ContainerManager.open()` | ✅ |
| `parseMagicEffect()` | `EffectManager.add_magic_effect()` | ✅ |
| `getOutfit()` | `ThingReader.read_outfit()` | ✅ |
| `getPosition()` | `ProtocolReader.read_position()` | ✅ |

---

## 16. Checklist de validação (Volume 2)

- [ ] Login completo sem erro
- [ ] `0x64` consome exatamente os bytes do pacote (sem bytes sobrando com opcode inválido)
- [ ] Próximo byte após mapa ∈ `{0x78, 0x83, 0x6D, ...}`
- [ ] Tile count coerente com OTC no mesmo login
- [ ] `0x6D` move player sem "tile antigo não encontrado"
- [ ] Inventário `0x78` popula slots no HUD
- [ ] Scroll `0x65`–`0x68` sem desync

---

## 17. Referências cruzadas

- **Volume 4 (Gameplay):** walking, prediction, auto walk — `LocalPlayer`, `Creature::walk`
- **Volume 7 (Assets):** flags `.dat` que afetam `getItem()` — `ATTR_STACKABLE`, `ATTR_CHARGEABLE`
- **Volume 8 (Godot Mapping):** tabela consolidada de todos os módulos

---

## 18. Histórico

| Data | Alteração |
|---|---|
| 2026-07-30 | Primeira versão — fluxo de rede, mapa, getItem/getCreature, desync analysis |
