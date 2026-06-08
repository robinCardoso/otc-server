# Bestiary — servidor TFS (opcode 207)

Rastreamento de **abates por criatura** + sync OTCv8 via extended opcode **207**. O catálogo visual (HP, loot, categorias) fica no **cliente** (`bestiary_database.json`); o servidor é autoridade para **kills** e **looks oficiais**.

| Doc | Conteúdo |
|-----|----------|
| **UI, JSON, troubleshooting cliente** | [`../../client/docs/BESTIARY-MODULE.md`](../../client/docs/BESTIARY-MODULE.md) |
| **Extended opcodes (geral)** | [`STOCK-MODULE.md`](STOCK-MODULE.md), [`COMBAT-POWER.md`](COMBAT-POWER.md) |
| **Logs TFS** | [`LOGS.md`](LOGS.md) |

---

## Arquitetura

```
OTC game_bestiary  --JSON 207 requestSync-->  otcv8_bestiary.lua (creaturescript)
                                                  --> Otcv8Bestiary.sendFullSync
                                                  --> sendKills (storage)
                                                  --> sendLooks (MonsterType cache)

Player mata monstro  -->  BestiaryKill (onKill)
                          --> Otcv8Bestiary.addKill
                          --> sendSingleKillUpdate (action update)
```

| Camada | Arquivo |
|--------|---------|
| Lib principal | `data/lib/otcv8_bestiary.lua` |
| Charms (upgrades) | `data/lib/otcv8_bestiary_charms.lua` — trilhas, custos, compra |
| Combate C++ | `src/otcv8charms.cpp` — multiplicador % em `weapons.cpp` + `combat.cpp` |
| Lista de monstros | `data/lib/bestiary_monsters.lua` — `BestiaryMonsterNames` |
| Handler opcode | `data/creaturescripts/scripts/otcv8_bestiary.lua` |
| Kill tracker | `data/creaturescripts/scripts/bestiary_kill.lua` |
| Registro XML | `data/creaturescripts/creaturescripts.xml` |
| Login | `data/creaturescripts/scripts/others/login.lua` |
| Load libs | `data/lib/lib.lua` — dofile bestiary + otcv8_bestiary + otcv8_bestiary_charms |
| Cliente | `client/modules/game_bestiary/` |

**Não misturar** com Shop (201), Spell List (202), Combat Power (203), Stock, etc. — um creaturescript `extendedopcode` por número.

---

## Registro no login

Em `data/creaturescripts/scripts/others/login.lua`:

```lua
player:registerEvent("ExtendedOpcodeBestiary")
player:registerEvent("BestiaryKill")
if Otcv8Bestiary and Otcv8Bestiary.scheduleLoginSync then
  Otcv8Bestiary.scheduleLoginSync(player)
end
```

Em `creaturescripts.xml`:

```xml
<event type="extendedopcode" name="ExtendedOpcodeBestiary" script="otcv8_bestiary.lua" />
<event type="kill" name="BestiaryKill" script="bestiary_kill.lua" />
```

Reiniciar **tfs.exe** após alterar `data/lib/` ou `creaturescripts/`.

---

## Protocolo JSON (opcode 207)

### Cliente → servidor

```json
{ "action": "requestSync" }
{ "action": "charms_sync" }
{ "action": "charms_buy", "track": "melee" }
```

Handler (`otcv8_bestiary.lua`): `requestSync` → `sendFullSync`; `charms_sync` → `Otcv8BestiaryCharms.sendState`; `charms_buy` → `Otcv8BestiaryCharms.buyTrackLevel` + `sendBuyResult`.

**Debounce:** no máximo 1 `requestSync` processado por jogador a cada **1 s** (`SYNC_DEBOUNCE_SEC`).

### Servidor → cliente

| action | data | Quando |
|--------|------|--------|
| `sync` | `{ "Rotworm": 5, "Rat": 3 }` | Login sync, `requestSync`, `sendKills` |
| `update` | `{ "name": "Rotworm", "kills": 6 }` | Cada kill em tempo real |
| `items` | `{ "2148": { "c": 3031, "n": "gold coin" }, ... }` | Lotes (~70 entradas/lote), sem chunk S/P/E; 1× por sessão |
| `itemsDone` | `{ "total": 1234 }` | Após último lote `items`; cliente marca sync completo |
| `looks` | `{ "v": 1, "names": [...], "types": [...], "aux": [...] }` | Após todos os lotes `items`; pacote grande (chunked) |
| `charms_state` | `{ "totalPoints": 42, "tracks": { "melee": 8, "distance": 3, ... } }` | Resposta a `charms_sync` |
| `charms_buy_result` | `{ "ok": true, "track": "melee", "level": 9, "totalPoints": 33, "tracks": {...}, "message": "..." }` | Após `charms_buy` |
| `sync` (extra) | `totalPoints`, `charms` no payload | Junto com kills no login / `requestSync` |

O pacote `sync` também envia **`totalPoints`** (storage `149999`) e **`charms`** (níveis por trilha) para a UI do cliente.

Envelope sempre: `{ action = "...", data = ... }` via `Otcv8Bestiary.sendJSON`.

O pacote **`update`** também alimenta os **kill toasts** no mapa (cliente) — ver [`../../client/docs/BESTIARY-MODULE.md`](../../client/docs/BESTIARY-MODULE.md#kill-toasts-no-mapa). Nenhuma alteração extra no servidor é necessária.

### Chunking

`MAX_PACKET_SIZE = 6000` (abaixo do limite de **8192** bytes por string no `NetworkMessage`). Pacotes maiores:

```
S + json_part1
P + json_part2
...
E + json_last
```

Cliente remonta em `modules/gamelib/protocolgame.lua` — **um buffer por opcode**. Não enviar outro pacote 207 (ex. `sync`) enquanto um stream S/P/E está aberto — corrompe JSON (`Invalid data in extended JSON opcode (207)`).

**Regra:** mapa `items` usa **lotes pequenos** (< 6000 bytes cada, sem S/P/E). Só `looks` usa chunking, **depois** que todos os lotes `items` + `itemsDone` terminarem.

### Ordem em `sendFullSync` (pipeline serial)

1. **`sendKills`** — pacote pequeno, imediato.
2. **`sendItemsBatched`** — lotes de ~70 entradas, 30 ms entre lotes; termina com **`itemsDone`**; `_itemsSent` só após sucesso.
3. **`sendLooks`** — 200 ms após `itemsDone`; chunked S/P/E; uma vez por sessão (`_looksSent`).

Enquanto o pipeline roda (`_syncPipelinePending`), novos `requestSync` são ignorados (`canRequestSync` retorna false).

`scheduleLoginSync` envia **apenas kills** em 1,5 s após login (sem looks nem items).

### Action `items` — mapa de loot (lotes)

Montado em `buildItemLookup()`:

- Itera `BestiaryMonsterNames` → `MonsterType(name):getLoot()` (inclui `childLoot`)
- Coleta `itemId` (serverId) únicos
- Para cada id: `ItemType(id):getClientId()` + `getName()`

Payload compacto (chaves string = serverId):

```json
{
  "2148": { "c": 3031, "n": "gold coin" },
  "2696": { "c": 3607, "n": "cheese" }
}
```

O cliente usa esse mapa em `resolveDropItem()` — **não** tenta `findItemTypeByName` localmente (OTC carrega só DAT/SPR, sem OTB/items.xml). Ver [`../../client/docs/BESTIARY-MODULE.md`](../../client/docs/BESTIARY-MODULE.md#loot-ícones-e-nomes).

### Pré-build do cache (startup)

Em `data/globalevents/scripts/startup.lua` (final do `onStartup`):

```lua
Otcv8Bestiary.scheduleStartupLooksCache()   -- addEvent +5 s → buildLooksCache()
Otcv8Bestiary.scheduleStartupItemLookup() -- addEvent +5 s → buildItemLookup()
```

Evita bloquear o 1º `requestSync` com 1337× `MonsterType`. Log esperado ~5 s após boot:

```
[Otcv8Bestiary] Pre-build cache de looks no startup...
[Otcv8Bestiary] Cache de looks: 1337 entradas (N MonsterType ausente)
[Otcv8Bestiary] Pre-build cache de itens no startup...
[Otcv8Bestiary] Cache de itens: N serverIds (M monstros com loot)
```

---

## Persistência — player storage

### API (`otcv8_bestiary.lua`)

| Função | Descrição |
|--------|-----------|
| `getStorageKey(name)` | `STORAGE_BASE (150000) + hash(name:lower()) % 50000` |
| `getPlayerKills(player, name)` | `getStorageValue`; negativo → 0 |
| `addKill(player, name)` | incrementa storage, retorna novo total |
| `sendKills(player)` | Monta tabela só com kills &gt; 0 |
| `sendSingleKillUpdate` | Pacote `update` para um monstro |
| `buildLooksCache()` | 1337× `MonsterType(name):getOutfit()` — **uma vez** por uptime; `pcall` em cada monstro |
| `buildItemLookup()` | Loot de todos os monstros → `ItemType(id):getClientId()` + `getName()` |
| `sendItemsBatched(player)` | Action `items` em lotes + `itemsDone` |
| `startSyncPipeline(player)` | kills → items (lotes) → looks (serial) |
| `scheduleStartupLooksCache()` | Agenda pré-build **5 s** após boot (`startup.lua`) |
| `scheduleStartupItemLookup()` | Agenda pré-build de itens **5 s** após boot |
| `canRequestSync(player)` | Debounce 1 s entre `requestSync` por jogador |
| `sendLooks(player)` | JSON arrays paralelos; 1× por sessão via `sendFullSync` |
| `sendJSON(player, action, data)` | `pcall(json.encode)`; revalida `Player(id)` a cada chunk |

### Hash de storage

Algoritmo djb2 simplificado sobre **`name:lower()`** (fix 2026-06: antes era case-sensitive e kills antigas podiam “sumir” após correção).

**Importante:** storages gravadas **antes** do fix usam chave diferente — jogadores afetados precisam rematar ou rodar script de migração manual.

Não há tabela SQL dedicada; tudo em **`player_storage`** via `setStorageValue`.

### Charm Points

| Storage | Uso |
|---------|-----|
| **149999** | Saldo de Charm Points (`Otcv8Bestiary.POINTS_STORAGE`) |

Ganho: ao **completar** uma entrada do bestiary (`bestiary_kill.lua` — meta de kills da dificuldade). Pontos por dificuldade: 1 / 15 / 25 / 50 (Inofensivo → Difícil).

---

## Charms — upgrades permanentes

Lib: `data/lib/otcv8_bestiary_charms.lua`. Balanceamento **sem recompilar** (só Lua). Efeito no combate exige **rebuild TFS** (`otcv8charms.cpp`).

### Storages por trilha (151xxx)

| Storage | ID `track` | Categoria |
|---------|------------|-----------|
| 151001 | `melee` | attack |
| 151002 | `distance` | attack |
| 151010 | `magic_physical` | attack |
| 151011 | `magic_earth` | attack |
| 151012 | `magic_fire` | attack |
| 151013 | `magic_ice` | attack |
| 151014 | `magic_energy` | attack |
| 151015 | `magic_holy` | attack |
| 151016 | `magic_death` | attack |

Valor = nível (0–20). Cada nível = **+1%** dano na trilha (`BONUS_PER_LEVEL = 1`, `MAX_LEVEL = 20`).

### Custo escalonado (`COST_TIERS`)

| Próximo nível | Custo (pts) |
|---------------|-------------|
| 1–5 | 25 |
| 6–10 | 50 |
| 11–15 | 100 |
| 16–20 | 200 |

Total maxar 1 trilha: **1.875 pts**. Teto teórico catálogo completo: **~32.061 pts** — ver [`../../client/docs/ideias para BESTIARY.md`](../../client/docs/ideias%20para%20BESTIARY.md).

### API Lua (`Otcv8BestiaryCharms`)

| Função | Descrição |
|--------|-----------|
| `getTrackLevel(player, trackId)` | Nível 0–20 |
| `getCostForLevel(currentLevel)` | Custo do próximo +1% |
| `buyTrackLevel(player, trackId)` | Valida, deduz pontos, incrementa storage |
| `buildTracksState(player)` | Mapa `trackId → level` para JSON |
| `sendState(player)` | Action `charms_state` |
| `sendBuyResult(player, ok, trackId, message)` | Action `charms_buy_result` |
| `getMeleeBonusPercent` / `getDistanceBonusPercent` / `getMagicBonusPercent` | Helpers Lua (espelham C++) |

### Combate (C++)

| Arquivo | Hook |
|---------|------|
| `src/otcv8charms.cpp` | Lê storages 151001–151016; `applyOutgoingDamage` |
| `src/weapons.cpp` | Bônus melee e distance no hit |
| `src/combat.cpp` | Bônus magia por `CombatType_t` (`COMBAT_FORMULA_LEVELMAGIC`) |

Recompilar após alterar C++:

```powershell
$env:PATH = "C:\msys64\mingw64\bin;C:\msys64\usr\bin;" + $env:PATH
Set-Location C:\8.6\otserv_860\otc-server\server\build_win
cmake --build . -j8
```

---

## Kill tracking (`bestiary_kill.lua`)

```lua
function onKill(creature, target)
  -- creature = player (isPlayer)
  -- Ignora: players, summons (getMaster)
  -- Match: BestiaryMonsterSet[name:lower()] → nome canônico da lista
  -- addKill + sendSingleKillUpdate
end
```

| Regra | Detalhe |
|-------|---------|
| Monstro deve estar em `BestiaryMonsterNames` | Senão kill ignorado |
| Nome do spawn | `target:getName()` — deve bater com lista (case-insensitive) |
| Summons | Ignorados (`target:getMaster()`) |

---

## Lista de monstros — `bestiary_monsters.lua`

```lua
BestiaryMonsterNames = {
  "Rotworm",
  "Rat",
  -- ... ~1337 entradas
}
```

Comentário no arquivo: *gerado automaticamente — não editar manualmente*.

Para adicionar monstro:

1. Incluir nome **exato** (como no `monsters/*.xml`) na lista.
2. Adicionar entrada correspondente em `client/.../bestiary_database.json`.
3. Reiniciar TFS + cliente.

---

## Cache de looks

`buildLooksCache()` itera `BestiaryMonsterNames`:

```lua
local mtOk, mt = pcall(MonsterType, name)
if mtOk and mt then
  local outfitOk, outfit = pcall(function() return mt:getOutfit() end)
  -- lookType / lookTypeEx
end
```

Payload:

```lua
{
  v = LOOKS_VERSION,  -- 1
  names = { "Rotworm", ... },
  types = { 26, ... },      -- lookType
  aux = { 0, ... }          -- lookTypeEx (item/outfit ex)
}
```

Log esperado:

```
[Otcv8Bestiary] Cache de looks: 1337 entradas (0 MonsterType ausente)
```

### Performance — cache de looks

| Momento | Comportamento |
|---------|----------------|
| Boot (+5 s) | `scheduleStartupLooksCache()` — build em background |
| 1ª `requestSync` (se boot não terminou) | Pode ainda bloquear; aguardar log cache |
| Sessão do jogador | Looks enviados **1×** (`_looksSent`); kills a cada sync debounced |

**Melhoria aplicada (2026-06):** pré-build no `startup.lua`. Antes, a 1ª sync podia levar **minutos** e gerar warnings de monsters no console.

---

## Logs e debug

### Console TFS (`data/logs/tfs/`)

```
> [extopcode] Eu Sou Knight opcode=207 len=24
> [extopcode] handler: ExtendedOpcodeBestiary
[Otcv8Bestiary] sendKills Eu Sou Knight: 11 abates em 2 especies
> [extopcode] handler done: ExtendedOpcodeBestiary
[Otcv8Bestiary] Cache de looks: 1337 entradas (0 MonsterType ausente)
```

| Log | Significado |
|-----|-------------|
| `opcode=207 len=24` | Cliente enviou `requestSync` (~24 bytes JSON) |
| `sendKills ... 0 abates` | Storages vazias ou personagem novo |
| `sendKills ... N abates` | Sync OK; cliente deve logar `[Bestiary] sync:` |
| Sem `handler done` | Crash ou hang no handler (investigar `buildLooksCache`) |

### Cliente

Ver [`../../client/docs/BESTIARY-MODULE.md`](../../client/docs/BESTIARY-MODULE.md) — seção logs.

---

## Troubleshooting (servidor)

| Sintoma | Causa | Ação |
|---------|-------|------|
| Kills não sobem | Monstro fora de `BestiaryMonsterNames` | Adicionar nome |
| Kills sobem no relog mas não live | `BestiaryKill` não registrado | `login.lua` + XML |
| Cliente não recebe nada | `isUsingOtClient()` false | Cliente deve ser OTCv8 |
| `json library not loaded` | Falta `json.lua` em lib | Ver `data/lib/lib.lua` |
| Lag no 1º Bestiary | `buildLooksCache` ainda em progresso no boot | Aguardar log cache; reiniciar TFS se travou |
| `Invalid data` opcode 207 no cliente | Chunks looks sobrepostos / sync spam | Debounce 1 s; looks 1×/sessão; chunk 6000 |
| Crash `exit=-1073741819` | Access violation C++ (raro) | Ver [`LOGS.md`](LOGS.md) + [`COMBAT-POWER.md`](COMBAT-POWER.md); log `[extopcode]` |
| Kills “perdidas” após update | Storage key antiga (case) | Migração ou rematar |
| Handler roda para todo opcode | Loop TFS chama todos extended scripts | Normal; script retorna `false` se opcode ≠ 207 |

---

## Manutenção

| Tarefa | Arquivo |
|--------|---------|
| Alterar opcode | `Otcv8Bestiary.OPCODE` + cliente `207` |
| Tamanho máximo pacote | `MAX_PACKET_SIZE` (**6000**) |
| Debounce requestSync | `SYNC_DEBOUNCE_SEC` (**1.0**) |
| Pré-build looks | `startup.lua` → `scheduleStartupLooksCache()` |
| Base storage | `STORAGE_BASE = 150000` — cuidado com colisões |
| Versão payload looks | `LOOKS_VERSION` — cliente pode invalidar cache |
| Novo monstro rastreável | `bestiary_monsters.lua` + JSON cliente |
| Ignorar tipos de kill | `bestiary_kill.lua` filtros |

---

## Melhorias futuras (servidor)

1. ~~**`GlobalEvent` onStartup** — `buildLooksCache()` antes de players online.~~ **Feito** (`startup.lua`).
2. **Talkaction debug** — `/bestiarytest` (God): pontos + mob completo + trilha Charms max; ver `talkactions/scripts/bestiary_test.lua`.
3. **Talkaction debug kills** — `!bestiary` mostrar kills locais / storage key (como `!power`).
3. **Migrador de storage** — one-shot GM command para rehash case-insensitive.
4. **Opcode 208 dedicado** — looks separados de kills/updates (reduz corrida S/P/E no 207).
5. **Exportador JSON** — gerar/atualizar `bestiary_database.json` a partir de `MonsterType` + loot XML.
6. ~~**Bestiary charms / bonus**~~ — **Fase 1 ataque** (storages 151xxx, opcode 207, C++ damage); resist/loot/cap pendentes.
7. ~~**Rate limit** — throttle de `requestSync` por player.~~ **Feito** (`canRequestSync`, 1 s).
8. **Persistência SQL opcional** — tabela `player_bestiary_kills` se storages ficarem limitados.

---

## Teste rápido

1. Login OTC com personagem de teste.
2. Matar **Rotworm** (ou monstro listado).
3. Relog → log TFS `sendKills ... 1 abates em 1 especies`.
4. Cliente Bestiary → Total Kills ≥ 1.
5. Matar outro → log imediato + pacote `update` (sem relog).
6. Abrir Bestiary 1ª vez no uptime → looks já devem estar em cache (boot +5 s); senão aguardar log.
7. Cliente: kill toast ao matar + slider **Bestiary toast lines** (Opções → Game).
8. Bestiary → aba **Charms** → `charms_sync` → comprar Melee +1% → verificar storage 151001 e dano em combate (TFS recompilado).

---

## Referência — `Otcv8Bestiary` (constantes)

```lua
Otcv8Bestiary = {
  OPCODE = 207,
  STORAGE_BASE = 150000,
  MAX_PACKET_SIZE = 6000,
  LOOKS_VERSION = 1,
  SYNC_DEBOUNCE_SEC = 1.0,
}
```

Cliente espelha opcode **207** em `ProtocolGame.registerExtendedJSONOpcode(207, ...)`.
