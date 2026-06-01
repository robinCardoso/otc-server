# Estoque OTCv8 — servidor (opcode 205)

## Arquivos

| Arquivo | Função |
|---------|--------|
| `data/lib/otcv8_stock.lua` | Catálogo depot, withdraw/deposit, JSON |
| `data/creaturescripts/scripts/otcv8_stock.lua` | Handler extended opcode |
| `data/talkactions/scripts/estoque_debug.lua` | `!estoque` |

## Integração

- `creaturescripts.xml` → `ExtendedOpcodeStock`
- `login.lua` → `registerEvent("ExtendedOpcodeStock")`
- `lib.lua` → `dofile('lib/otcv8_stock.lua')`

## Ações (JSON)

| action | Descrição |
|--------|-----------|
| `request` | Envia `catalog` |
| `withdraw` / `deposit` | `{ itemId, invSlot\|depotBox, path[], index, count }` — posicao no inventario/depot (nao usar `uid` entre pacotes) |
| `depositAll` | Stackáveis da mochila → depot |
| `sort` | `{ mode: name\|id\|count }` reordena lista |

Cliente: `otcv8-dev-orig/modules/game_stock/` — **Ctrl+Shift+E**

## Bloqueio PK (skull branco+)

Jogador com **PK** (`player:getSkull() >= SKULL_WHITE`) pode **abrir** o Estoque e ver o catalogo, mas **nao** depositar/retirar.

| Camada | Onde |
|--------|------|
| **Servidor (autoridade)** | `Otcv8Stock.canModify()` em `data/lib/otcv8_stock.lua` — bloqueia `withdraw`, `deposit`, `depositAll` |
| **Visualizacao** | `Otcv8Stock.canView()` — `request` e `sort` continuam funcionando |
| **Cliente (UX)** | `modules/game_stock/stock.lua` — `readOnly` no JSON do catalogo; banner `pkBlockLabel`; botoes/drag desabilitados |

Config no lib:

```lua
BLOCK_PK_SKULL = true,
PK_BLOCK_MESSAGE = "Voce nao pode usar o estoque com skull de PK.",
```

JSON do catalogo inclui `readOnly` e `blockReason` quando PK.

**Nao bloqueia:** skull verde (party), amarelo, sem skull. **Nao usa** `isPzLocked()` nesta regra.

Acao bloqueada retorna `result` com `ok=false` → cliente exibe `displayInfoBox(tr("Estoque"), message)`.

## Retirar item — "Mochila cheia" com espaco visivel

**Causa:** `backpackHasRoomForItem` so contava slot vazio na **primeira camada** da mochila; bags/containers cheios na raiz bloqueavam equipamentos e itens nao stackaveis, mesmo com espaco em bags internas. Slots de equipamento livres (ex. pernas) nao entravam na conta.

**Fix:** `getEmptySlots(true)`, busca recursiva em sub-containers, `playerHasFreeEquipSlot`, `moveTo(player)` antes da mochila.

### Retirar falha apos "Mochila cheia" corrigida (moveTo depot)

**Causa:** `item:moveTo` de item **dentro do depot** para player/mochila falha no TFS; fallback antigo so duplicava stackaveis via `container:addItem`.

**Fix:** `tryCreateItemsInCylinder` — `player:addItem` + `item:remove` do depot; fallback tambem para equipamentos. Cliente: drag `UIItem` restaurado; refresh apos retirar/depositar.

## Categorias (`getCategory`)

- **runes / containers / equipment:** `ItemType:isRune()`, `isContainer()`, `getSlotPosition()`.
- **food:** ids do `data/actions/scripts/others/consumables/food.lua` + fluid containers.
- **valuables:** moedas (2148/2152/2160) e gemas comuns por id — **nao** usa `getWorth()` (inexistente neste TFS).

## v2 opcional (C++)

Após validar v1 em jogo: otimizar enumeração em `src/player.cpp` mantendo opcode 205 e JSON iguais.

## Persistência (depot TFS)

O Estoque **nao** usa tabela propria. Depositos vao para `player:getDepotChest()` → MariaDB `player_depotitems` no logout/save.

**Documentacao tecnica completa:** [DEPOT-SYSTEM.md](./DEPOT-SYSTEM.md) (fluxo RAM/DB, `lastDepotId`, load/save, armadilhas para o agente).

### Bug historico: perda no relog (Estoque sem abrir depot no mapa)

**Sintoma:** `depositAll` (Ctrl+Shift+E) → logout → login → itens sumiram; UI mostrava catalogo grande so na sessao anterior.

**Causa:** `IOLoginData::savePlayer` so gravava `player_depotitems` se `player->lastDepotId != -1`. Esse flag so era setado ao abrir locker no mapa (`actions.cpp`). O opcode 205 preenchia `depotChests` em RAM mas o save ignorava o depot; `player_items` salvava mochila vazia.

**Fix (C++):** `src/iologindata.cpp` — salvar depot se `lastDepotId != -1 || !depotChests.empty()`.

**Requer:** recompilar `tfs.exe` apos alterar o `.cpp`.

## Checklist de regressao (obrigatorio apos mudanca no save)

1. **Teste A:** char **sem** abrir depot no mapa → Estoque → depositar tudo → logout → login → catalogo igual.
2. **Teste B:** SQL antes/depois do logout:
   ```sql
   SELECT COUNT(*) FROM player_depotitems WHERE player_id = <guid>;
   SELECT COUNT(*) FROM player_items WHERE player_id = <guid>;
   ```
   Contagem em `player_depotitems` deve **aumentar** apos deposit all.
3. **Teste C:** retirar item → relog → item no inventario persistido.
4. **Teste D:** depot cheio → deposit all retorna erro; itens permanecem na mochila.
5. **Teste E (PK):** char com skull branco/vermelho/preto → Estoque abre, banner visivel, deposit/withdraw bloqueados; skull verde → editavel.

Diagnostico in-game: `!estoque` (`data/talkactions/scripts/estoque_debug.lua`).
