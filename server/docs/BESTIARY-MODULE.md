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
| Lista de monstros | `data/lib/bestiary_monsters.lua` — `BestiaryMonsterNames` |
| Handler opcode | `data/creaturescripts/scripts/otcv8_bestiary.lua` |
| Kill tracker | `data/creaturescripts/scripts/bestiary_kill.lua` |
| Registro XML | `data/creaturescripts/creaturescripts.xml` |
| Login | `data/creaturescripts/scripts/others/login.lua` |
| Load libs | `data/lib/lib.lua` — dofile bestiary + otcv8_bestiary |
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
```

Handler (`otcv8_bestiary.lua`): se `canRequestSync(player)`, chama `Otcv8Bestiary.sendFullSync(player)`.

**Debounce:** no máximo 1 `requestSync` processado por jogador a cada **1 s** (`SYNC_DEBOUNCE_SEC`).

### Servidor → cliente

| action | data | Quando |
|--------|------|--------|
| `sync` | `{ "Rotworm": 5, "Rat": 3 }` | Login sync, `requestSync`, `sendKills` |
| `update` | `{ "name": "Rotworm", "kills": 6 }` | Cada kill em tempo real |
| `items` | `{ "2148": { "c": 3031, "n": "gold coin" }, ... }` | Lotes (~70 entradas/lote), sem chunk S/P/E; 1× por sessão |
| `itemsDone` | `{ "total": 1234 }` | Após último lote `items`; cliente marca sync completo |
| `looks` | `{ "v": 1, "names": [...], "types": [...], "aux": [...] }` | Após todos os lotes `items`; pacote grande (chunked) |

O pacote **`update`** também alimenta os **kill toasts** no mapa (cliente) — ver [`../../client/docs/BESTIARY-MODULE.md`](../../client/docs/BESTIARY-MODULE.md#kill-toasts-no-mapa). Nenhuma alteração extra no servidor é necessária.

Envelope sempre: `{ action = "...", data = ... }` via `Otcv8Bestiary.sendJSON`.

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
2. **Talkaction debug** — `!bestiary` mostrar kills locais / storage key (como `!power`).
3. **Migrador de storage** — one-shot GM command para rehash case-insensitive.
4. **Opcode 208 dedicado** — looks separados de kills/updates (reduz corrida S/P/E no 207).
5. **Exportador JSON** — gerar/atualizar `bestiary_database.json` a partir de `MonsterType` + loot XML.
6. **Bestiary charms / bonus** — gameplay além de contador (storage ou coluna custom).
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
