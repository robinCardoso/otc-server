---
name: otclient-protocol-implementer
description: >
  Skill especialista para implementar funcionalidades no cliente Godot 4.7+
  baseado no protocolo OTServer/TFS 8.60. A fonte da verdade para leitura de
  bytes é SEMPRE o OTClient C++ em client/ — nunca improvisar resync, retry ou
  heurísticas. Garante que NENHUM arquivo, opcode ou ponto crucial de protocolo
  seja ignorado. Analisa cada camada (rede → parser → estado → renderização).
---

# SKILL: OTClient Protocol Implementer

> Esta skill deve ser lida na íntegra antes de qualquer implementação relacionada
> ao cliente Godot/OTServer. Ela define o processo obrigatório de análise e os
> padrões de qualidade a serem seguidos.

---

## Regra de Ouro: `client/` é a Fonte da Verdade

**Toda leitura de bytes do protocolo DEVE espelhar o OTClient C++ deste repositório.**

```
c:\8.6\otserv_860\otc-server\client\src\client\
```

| Prioridade | Fonte | Uso |
|---|---|---|
| **1ª (obrigatória)** | `client/src/client/protocolgameparse.cpp` | Ordem exata de bytes por opcode |
| **2ª (obrigatória)** | `client/modules/game_features/features.lua` | Quais `g_game.getFeature()` estão ativos no 860 |
| **3ª (referência)** | `server/src/protocolgame.cpp` | O que o TFS **envia** (AddCreature, addItem, GetFloorDescription) |
| **4ª (proibida como base)** | Lógica inventada em GDScript | Nunca usar como referência primária |

**Fluxo correto de implementação:**

```
1. Ler função equivalente em protocolgameparse.cpp
2. Verificar features.lua para condicionais do protocolo 860
3. Escrever GDScript que lê os MESMOS bytes na MESMA ordem
4. Se desync → corrigir o read específico (getItem, getCreature, etc.)
5. NUNCA mascarar desync com heurísticas
```

### O que o OTC faz (e o Godot DEVE fazer igual)

| Função OTC | Arquivo | Comportamento |
|---|---|---|
| `setMapDescription()` | `protocolgameparse.cpp` ~3239 | `skip=0`, percorre andares chamando `setFloorDescription` |
| `setFloorDescription()` | ~3258 | `skip==0` → `setTileDescription`; senão `skip--` e limpa tile |
| `setTileDescription()` | ~3274 | `peek>=0xFF00` → retorna skip; loop `getThing()` até `peek>=0xFF00` |
| `getThing()` | ~3370 | `id==0` → **`throw_exception`** (não recupera) |
| `getItem()` | ~3600 | bytes conforme flags do `.dat` + features do 860 |
| `getCreature()` | ~3414 | bytes conforme tipo (0x61/0x62/0x63) + features do 860 |
| `getOutfit()` | ~3304 | `lookType u16`; se !=0 → 5×u8; senão `lookTypeEx u16` |

### O que o OTC **NÃO** faz (proibido no Godot)

| Anti-padrão | Por que é errado | Sintoma no log |
|---|---|---|
| `_scan_skip_marker` / buscar `0xFF` no buffer | `0xFF` aparece dentro de outfits, strings, IDs — falso positivo | Tiles inflados (ex: 745→1237), opcode `0xFF` inválido |
| Retry de byte de count em item | OTC lê uma vez conforme `isStackable()\|\|isChargeable()` | Desync alternado, tiles fantasmas |
| `_consume_map_trailer` / `_consume_pending_skip` extras | OTC não tem; marcadores são consumidos no `peek` do loop do tile | Bytes sobrando ou faltando após `0x64` |
| `return 0` antecipado no stack 10 sem `peek` | OTC continua o loop até `peek>=0xFF00` na iteração seguinte | Desync ou leitura infinita |
| Ignorar `push_error` e continuar parse | OTC lança exceção e para | Cascata: scroll desync, `tile antigo não encontrado` |

> **Lição aprendida (Fase 1 — mapa):** quando aparece `thing id 0` ou `Proximos bytes: 68...`
> em vez de `78` (inventário), a causa é **1 byte errado** em `ThingReader.gd` —
> não falta de resync. Corrigir o read; não inventar recuperação.

### Mapeamento OTC → Godot (parse de mapa)

| OTC (`protocolgameparse.cpp`) | Godot | Notas |
|---|---|---|
| `setMapDescription` | `MapParser.read_map_description()` | `skip` inicial = **0** |
| `setFloorDescription` | `MapParser._read_floor()` | `skip==0` lê; `skip>0` pula célula |
| `setTileDescription` | `MapParser.read_tile_description()` | Loop 256; só termina em `peek>=0xFF00` |
| `getThing` | `ThingReader.read_thing()` | Delega para item/criatura/texto |
| `getItem` | `ThingReader.read_item()` | Espelhar `isStackable\|\|isChargeable` + fluid |
| `getCreature` | `ThingReader.read_creature()` | Emblem só em `CREATURE_UNKNOWN` (feature >=854) |
| `getOutfit` | `ThingReader.read_outfit()` | Sem mount/wings em 860 |

### Features obrigatórias do 860 (`client/modules/game_features/features.lua`)

Antes de implementar qualquer read condicional, verificar se a feature está ativa:

| Feature | Versão | Afeta |
|---|---|---|
| `GameLooktypeU16` | >=770 | outfit `lookType` como u16 |
| `GamePlayerAddons` | >=780 | byte `addons` no outfit |
| `GameCreatureEmblems` | >=854 | byte `emblem` em criatura desconhecida |
| `GameBiggerMapCache` | >=860 | viewport 25×20 (não 18×14) |
| `GameCreaturesMana` | >=910 | **NÃO** ativo em 860 — não ler mana |
| `GameThingMarks` | >=1000 | **NÃO** ativo em 860 — não ler mark em item |
| `GameCountU16` | — | **NÃO** ativo em 860 — count de item é u8 |

### Metodologia de debug quando há desync

1. Ativar em `ProtocolDebug.gd`: `DEBUG_PROTOCOL = true` e/ou `DEBUG_MAP_PARSE = true`
2. Reproduzir até o **primeiro** `thing id 0` — anotar tile `(x,y,z)` e `stack_pos`
3. Abrir `protocolgameparse.cpp` na função equivalente (`getItem` / `getCreature`)
4. Comparar byte a byte: qual campo foi lido a mais ou a menos?
5. Corrigir **apenas** `ThingReader.gd` ou `DatReader.gd` (flag errada)
6. Validar: após `0x64`, `Proximos bytes` deve começar com **`78`** (inventário)

**Indicadores de sucesso na Fase 1 (protocolo de mapa):**

| Métrica | Valor esperado |
|---|---|
| Tiles no `0x64` | ~745 (viewport 25×20 × andares visíveis, menos skips) |
| Bytes após mapa | Primeiro byte = `0x78` |
| Warnings | Zero `thing id 0`, zero `buffer curto` no login |
| Scrolls `0x65–0x68` | Sem desync após mapa correto |

---

## Processo Obrigatório de Implementação (Checklist de 5 Fases)

Toda nova funcionalidade **DEVE** percorrer estas 5 fases em ordem. Nunca pule uma fase.

### Fase 1 — Análise do Protocolo no OTClient C++ (Fonte da Verdade)

Antes de escrever uma linha de GDScript:

1. **Abrir** o equivalente em `client/src/client/protocolgameparse.cpp`
2. **Verificar** condicionais em `client/modules/game_features/features.lua` (protocolo 860)
3. **Opcional:** confirmar envio no TFS em `server/src/protocolgame.cpp`
4. **Espelhar** byte a byte — sem heurísticas, sem resync, sem retry

Os arquivos canônicos de referência estão em:
`c:\8.6\otserv_860\otc-server\client\src\client\`

**Arquivos obrigatórios a verificar por categoria:**

| Categoria | Arquivo(s) de referência |
|---|---|
| Opcodes de rede | `protocolgameparse.cpp` |
| Constantes de tempo/animação | `const.h` |
| Tabela de opcodes | `protocolcodes.h` |
| Lógica de efeitos mágicos | `effect.cpp`, `effect.h` |
| Lógica de mísseis | `missile.cpp`, `missile.h` |
| Texto animado | `animatedtext.cpp`, `animatedtext.h` |
| Movimento de criaturas | `creature.cpp`, `creature.h` |
| Renderização do mapa | `mapview.cpp`, `tile.cpp` |
| Fórmulas de velocidade | `creature.cpp` (getStepDuration) |
| Ordem de renderização | `tile.cpp` (drawGround → drawBottom → drawCreatures → drawTop) |

**Perguntas obrigatórias a responder durante a análise:**
1. Qual é a estrutura exata de bytes do opcode? (ordem, tipos: u8/u16/u32/string)
2. Existem condicionais de versão de protocolo? (`g_game.getFeature(...)`)
3. Qual é a duração/temporização exata? (constantes em `const.h`)
4. Onde o objeto é armazenado? (por tile, por andar, globalmente no mapa)
5. Qual é a ordem exata de renderização no `tile.cpp`?
6. Há opcodes correlatos que chegam em conjunto? (ex: `0x83` + `0x8C` no combate)

---

### Fase 2 — Mapeamento de Todos os Arquivos Godot Afetados

Nunca assuma que apenas um arquivo precisa ser alterado. Sempre mapear a cadeia completa:

```
Rede (receber bytes)
  └─ GameProtocol.gd         ← Verifica se o opcode precisa de acesso ao map_state/player_id
       └─ GameOpcodeReader.gd ← Parser do opcode (leitura de bytes + lógica de estado)
            ├─ MapState.gd    ← Estrutura de dados (adicionar campos? novo índice?)
            ├─ MapTile.gd     ← Novo array no tile? (effects, missiles, texts)
            ├─ MapParser.gd   ← Precisa registrar o novo dado no carregamento inicial?
            └─ ThingSpriteFactory.gd ← Nova função de textura necessária?

Renderização (frame a frame)
  └─ MapView.gd              ← _draw(), _process(), nova função _draw_*()
       └─ EffectAnimator.gd  ← Nova matemática pura de animação (sem Node2D)
```

**Regra crítica:** Se um dado é criado na rede, ele DEVE ser consumido/limpo na
renderização. Se é lido no MapParser, DEVE ser registrado nos índices. Nunca deixe
dados orfãos.

---

### Fase 3 — Verificação de Opcodes Correlatos

**Nunca implemente um opcode isoladamente.** Sempre verificar os opcodes que
chegam em conjunto ou dependem do mesmo estado:

**Grupos de opcodes que SEMPRE chegam juntos:**

| Gatilho | Opcodes correlatos obrigatórios |
|---|---|
| Criatura entra no mapa | `0x78` (AddThing) → deve registrar no `creature_index` |
| Criatura sai do mapa | `0x79` (RemoveThing) → deve remover do `creature_index` |
| Combate ocorre | `0x83` (Effect) + `0x8C` (CreatureHealth) |
| Criatura muda de aparência | `0x8D` (Outfit) → invalida cache de textura |
| Criatura acelera/paralisa | `0x8E` (Speed) → afeta `step_duration` do walking |
| Movimento de criatura | `0x6D` (MoveCreature) → atualiza `player_pos` se for o player |
| Mapa rola | `0xBE`/`0xBF`/`0xBC`/`0xBD` (FloorChange) → recarregar visibilidade |

---

### Fase 4 — Análise de Performance (Obrigatória)

Para cada implementação, responder e documentar:

**Padrão de dados (Data-Driven vs Node-Instancing):**
- ✅ **CORRETO:** Usar `Dictionary` + funções estáticas + `_draw()` matemático
- ❌ **INCORRETO:** Instanciar `Node2D`, `Sprite2D` ou `Tween` por criatura/efeito

**Perguntas de performance obrigatórias:**
1. **Frequência de chamada:** Esta operação ocorre a cada frame (60/s)? A cada opcode (variável)? Uma vez (load)?
2. **Escala:** Quantos objetos simultâneos? (ex: 50 criaturas × 60fps = problema se O(n²))
3. **Lookup de criatura:** Está usando `creature_index` (O(1)) ou `_find_creature_by_id` (O(n×m))?
4. **Cache de textura:** A textura está sendo recriada a cada frame? (`_texture_cache` em ThingSpriteFactory)
5. **Redraw desnecessário:** `queue_redraw()` é chamado apenas quando há animação ativa?
6. **Remoção de arrays:** Listas de efeitos/mísseis expirados são removidas em ordem reversa?

**Padrões de performance aprovados neste projeto:**

```gdscript
# ✅ Lookup O(1) de criatura
var creature = map_state.find_creature_by_id(id)

# ✅ Cache de textura (ThingSpriteFactory)
var cache_key := "%d:%d:%d:%d:%d:%d" % [category, id, px, py, pz, phase]
if _texture_cache.has(cache_key):
    return _texture_cache[cache_key]

# ✅ Redraw condicional
func _process(_delta):
    if active_missiles.size() > 0 or _has_walking_creatures():
        queue_redraw()

# ✅ Remoção de array em ordem reversa (preserva índices)
for i in range(to_remove.size() - 1, -1, -1):
    array.remove_at(to_remove[i])

# ✅ Animação matemática sem Tween
var progress := float(Time.get_ticks_msec() - start_ms) / float(duration_ms)
var offset := delta_pixels * progress
```

---

### Fase 5 — Checklist de Verificação Pré-Commit

Antes de finalizar qualquer implementação, verificar cada item:

**Rede / Parsing:**
- [ ] A implementação foi comparada com `client/src/client/protocolgameparse.cpp`?
- [ ] Features do 860 verificadas em `client/modules/game_features/features.lua`?
- [ ] Nenhuma heurística de resync/retry foi adicionada (proibido pela skill)?
- [ ] Todos os bytes do opcode são lidos? (nenhum byte deixado no buffer)
- [ ] Opcodes correlatos foram implementados ou ao menos "skipados" corretamente?
- [ ] Strings são lidas com `_ProtocolReaderScript.read_string()` (prefixo U16)?
- [ ] Posições são lidas com `protocol.read_position()` (x:U16 + y:U16 + z:U8)?
- [ ] O opcode foi adicionado ao `match` em `consume_opcode()`?

**Estado / Dados:**
- [ ] Criaturas novas são registradas em `map_state.creature_index`?
- [ ] Criaturas removidas são deletadas do `creature_index`?
- [ ] Novos campos de tile foram adicionados ao `MapTile.gd`?
- [ ] Novos campos globais foram adicionados ao `MapState.gd`?
- [ ] O `MapParser.gd` registra o novo dado no carregamento inicial do mapa?

**Renderização:**
- [ ] A ordem de renderização segue: Ground → Bottom → Creatures → Effects → Top?
- [ ] Efeitos expirados são removidos durante `_draw()` (não em `_process()`)?
- [ ] `queue_redraw()` é chamado apenas quando há algo animando?
- [ ] Missiles são filtrados pelo andar visível (`from_pos.z == _camera_pos.z`)?
- [ ] A câmera (`camera_offset`) é subtraída de TODOS os elementos dinâmicos?

**Performance:**
- [ ] Nenhum `Node2D`/`Sprite2D` é instanciado por efeito/criatura/míssil?
- [ ] Texturas são cacheadas por `cache_key` em `ThingSpriteFactory`?
- [ ] Lookups de criatura usam `creature_index` (O(1))?

---

## Mapa Completo de Opcodes do Protocolo 8.60

Referência rápida. Opcodes marcados com ✅ estão implementados, ⚠️ são skip, ❌ são ausentes.

### Opcodes de Mapa e Criaturas
| Opcode | Nome | Status |
|---|---|---|
| `0x64` / `100` | FullMap | ✅ MapParser |
| `0x65` / `101` | MapTopRow | ⚠️ skip |
| `0x66` / `102` | MapRightRow | ⚠️ skip |
| `0x67` / `103` | MapBottomRow | ⚠️ skip |
| `0x68` / `104` | MapLeftRow | ⚠️ skip |
| `0x69` / `105` | UpdateTile | ⚠️ skip |
| `0x6A` / `106` | CreateOnMap | ⚠️ skip (lê pos+stack+thing) |
| `0x6B` / `107` | ChangeOnMap | ⚠️ skip (lê pos+stack+thing) |
| `0x6C` / `108` | DeleteOnMap | ⚠️ skip |
| `0x6D` / `109` | MoveCreature | ✅ GameOpcodeReader |
| `0x71` / `113` | DeleteInContainer | ⚠️ skip |
| `0x78` / `120` | SetInventory | ⚠️ skip (lê slot+thing) |
| `0x79` / `121` | DeleteInventory | ⚠️ skip (lê slot) |

### Opcodes de Efeitos Visuais
| Opcode | Nome | Status |
|---|---|---|
| `0x82` / `130` | Ambient (World Light) | ⚠️ skip (lê 2 u8) |
| `0x83` / `131` | GraphicalEffect | ✅ |
| `0x84` / `132` | AnimatedText | ✅ |
| `0x85` / `133` | DistanceMissile | ✅ |

### Opcodes de Estado de Criatura
| Opcode | Nome | Status |
|---|---|---|
| `0x8C` / `140` | CreatureHealth | ✅ |
| `0x8D` / `141` | CreatureLight | ⚠️ skip (lê u32 + 2×u8) |
| `0x8D` / `142` | CreatureOutfit | ✅ |
| `0x8E` / `143` | CreatureSpeed | ✅ |
| `0x8F` / `144` | CreatureSkull | ⚠️ skip |
| `0x90` / `145` | CreatureParty | ⚠️ skip |
| `0x92` / `146` | CreatureUnpass | ⚠️ skip |

### Opcodes de Player
| Opcode | Nome | Status |
|---|---|---|
| `0x0A` | LoginSuccess | ✅ |
| `0xA0` / `160` | PlayerStats | ⚠️ skip |
| `0xA1` / `161` | PlayerSkills | ⚠️ skip |
| `0xA2` / `162` | PlayerState | ⚠️ skip |
| `0xB4` / `180` | TextMessage | ⚠️ skip |
| `0xB5` / `181` | CancelWalk | ⚠️ skip |
| `0xBE` / `190` | FloorChangeUp | ⚠️ CRÍTICO — não implementado |
| `0xBF` / `191` | FloorChangeDown | ⚠️ CRÍTICO — não implementado |

> [!WARNING]
> `0xBE` e `0xBF` (FloorChange) são críticos. Quando não implementados, ao descer
> escadas o cliente desincroniza completamente do servidor. Devem ser priorizados
> após os efeitos visuais.

---

## Arquitetura de Arquivos do Projeto Godot

```
godot-client/src/
├── autoload/
│   └── GlobalNetwork.gd          # Singleton de rede — conecta signals
├── core/
│   ├── cryptography/
│   │   ├── Rsa.gd                # RSA 1024-bit textbook (puro GDScript)
│   │   └── Xtea.gd               # XTEA encrypt/decrypt
│   └── network/
│       ├── GameProtocol.gd       # Handshake + loop de opcodes do Game Server
│       ├── GameOpcodeReader.gd   # Parser de todos os opcodes (consume_opcode)
│       └── ProtocolReader.gd     # Helpers: read_position, read_string, peek_u16
├── game/
│   ├── creature/
│   │   └── CreatureWalker.gd     # Fórmulas de walking (kSpeedA/B/C, step_duration)
│   ├── effects/
│   │   └── EffectAnimator.gd     # Fórmulas de effects, missiles, animated text
│   └── map/
│       ├── MapParser.gd          # Parse do opcode 0x64 (FullMap)
│       ├── MapState.gd           # Estado do mapa: tiles, creature_index, missiles...
│       ├── MapTile.gd            # Tile: items[], creatures[], effects[]
│       ├── MapView.gd            # Node2D: _draw() + _process() + render()
│       ├── MapVisibility.gd      # Cálculo de andares visíveis e culling
│       └── ThingSpriteFactory.gd # Factory de texturas com cache por chave
└── io/
    ├── DatReader.gd              # Parse do Tibia.dat (ThingType, flags, sprites)
    ├── SpriteReader.gd           # Parse do Tibia.spr (RLE decode → Image)
    └── ThingReader.gd            # Parse de Things da rede (items, criaturas)
```

---

## Constantes Críticas do Protocolo 8.60

```gdscript
# Velocidade de criaturas (creature.cpp — kSpeedA/B/C)
const SPEED_A := 857.36
const SPEED_B := 261.29
const SPEED_C := -4795.01
# Fórmula: floor(SPEED_A * log(speed/2 + SPEED_B) + SPEED_C + 0.5)
# Arredondar para múltiplo de server_beat (50ms)

# Animações (const.h)
const EFFECT_TICKS_PER_FRAME := 75    # ms por frame de efeito mágico
const ANIMATED_TEXT_DURATION := 1000  # ms total do texto flutuante
const MISSILE_DURATION_FACTOR := 150.0 # ms × √distância em tiles

# Mapa
const TILE_SIZE := 32           # pixels por tile
const MAP_WIDTH := 25           # tiles visíveis horizontal
const MAP_HEIGHT := 20          # tiles visíveis vertical
const MAP_LEFT := 12            # tiles à esquerda do player
const MAP_TOP := 9              # tiles acima do player
const SEA_FLOOR := 7            # z do chão do mar
const MAX_ELEVATION := 24       # elevação máxima acumulada

# Render
const OFFSET_FACTOR := 1        # fator de deslocamento por ponto de elevação
```

---

## Armadilhas Conhecidas e Soluções

### 0. Improvisar parse em vez de espelhar o OTC (ERRO CRÍTICO)
**Problema:** Adicionar resync (`_scan_skip_marker`), retry de count, trailers extras
(`_consume_map_trailer`) quando aparece `thing id 0`.
**Por que falha:** O OTC não faz isso; bytes `0xFF` existem dentro de dados de
criatura/item — o resync "encontra" marcadores falsos e corrompe o estado inteiro.
**Solução:** Ler `protocolgameparse.cpp`, corrigir o read exato em `ThingReader.gd`.
Ver seção **Regra de Ouro** no topo desta skill.

### 1. Buffer Desync (causa de crashes silenciosos)
**Problema:** Se um opcode lê bytes a mais ou a menos, todos os opcodes seguintes ficam errados.
**Sintoma:** `Proximos bytes: 68...` após `0x64` (deveria ser `78`); `tile antigo não encontrado`.
**Solução:** Comparar com `getItem()`/`getCreature()` no OTC; usar `DEBUG_PROTOCOL` em `ProtocolDebug.gd`.
**Proibido:** Mascarar com resync heurístico.

### 2. `_find_creature_by_id` O(n×m) em combate
**Problema:** Busca linear percorre todos os tiles para cada `0x8C`/`0x8D`/`0x8E`.
**Solução:** Sempre usar `map_state.creature_index` (O(1)) para opcodes de atualização.

### 3. Remoção de elementos de Array durante iteração
**Problema:** Remover `tile.effects[i]` durante o loop corrompe os índices.
**Solução:** Coletar índices em `to_remove: Array[int]` e remover em ordem reversa.

### 4. Textura recriada a cada frame
**Problema:** `_build_texture()` é O(n_sprites) — não pode ser chamada no `_draw()`.
**Solução:** Sempre passar pela `cache_key` em `_get_thing_texture()`.

### 5. Câmera não subtraída de efeitos
**Problema:** Efeitos ficam "presos" na tela enquanto o mapa rola.
**Solução:** Todo `draw_texture()` e `draw_string()` em MapView DEVE subtrair `camera_offset`.

### 6. Efeitos no andar errado
**Problema:** Efeitos de andares subterrâneos aparecem na superfície.
**Solução:** Sempre filtrar `tile_pos.z == _camera_pos.z` antes de renderizar.

### 7. `CREATURE_TURN` (0x63) vs `CREATURE_KNOWN` (0x62) no mapa
**Problema:** Confundir o caminho curto do opcode `0x6B` (ChangeOnMap) com o parse de
criatura dentro de `setTileDescription` (mapa `0x64`/scrolls).
**Solução:**
- No **tile do mapa**, `0x62` (known) envia dados completos: id + health + direction +
  outfit + light + speed + skull + shield + unpass (sem emblem).
- `0x63` (turn) no mapa: apenas `id(u32)` + `direction(u8)` — ver `getCreature()` no OTC.
- Caminho curto `id+direction` aplica-se a outros contextos (ex: `0x6B`), não ao `0x62` no tile.

### 8. FloorChange não implementado
**Problema:** Ao descer escadas, `player_pos.z` muda mas o mapa não é recarregado.
**Solução:** Opcodes `0xBE`/`0xBF` devem fazer novo parse de mapa e atualizar `map_state`.
