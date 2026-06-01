# Módulo Shop (OTCv8) — `game_shop`

> **Para o agente:** pedidos de *adicionar item ao Shop* → editar no **servidor**  
> **`c:\8.6\otserv_860\otserv_860\data\creaturescripts\scripts\otcv8_shop.lua`** → função **`initShop()`**.  
> Ver também **`otserv_860/docs/SHOP-MODULE.md`**.

## O que é

O botão **Shop** no cliente **não** é a loja de NPC (comprar/vender com merchant). É a **loja premium OTCv8** (pontos da conta, categorias, ofertas), baseada em:

| Modo | Protocolo | Versão Tibia |
|------|-----------|--------------|
| **A) OTCv8 Shop (este projeto)** | Extended opcode **201** + JSON | Qualquer (860+) se servidor implementar |
| **B) Tibia Ingame Store oficial** | Pacotes `ClientOpenStore` / `GameServerStore` | Cliente **≥ 10.80** (não existe em 8.60) |

No **Fazendo Tibia 8.60** só o modo **A** é viável.

## Arquivos responsáveis (cliente — `otcv8-dev`)

| Arquivo | Função |
|---------|--------|
| `modules/game_shop/shop.otmod` | Carrega o módulo; depende de `client_topmenu` |
| `modules/game_shop/shop.lua` | Lógica: UI, opcode 201, eventos `onStore*` (modo B), `check()` / `show()` |
| `modules/game_shop/shop.otui` | Layout da janela (categorias, ofertas, pontos) |
| `modules/game_shop/transfer.otui` | Janela “Transfer Coins” (Tibia 10+) |
| `modules/gamelib/protocolgame.lua` | `sendExtendedJSONOpcode` / `registerExtendedJSONOpcode` |
| `modules/game_features/features.lua` | `GameExtendedOpcode` (deve estar **ligado** para 860) |
| `modules/client_topmenu/` | Botão Shop na barra superior |
| `modules/game_topbar/topbar.otui` | Outro atalho `@onClick: modules.game_shop.show()` |
| `modules/game_interface/interface.otmod` | Lista `game_shop` nos módulos do jogo |
| `src/client/protocolgamesend.cpp` | `sendOpenStore`, `sendBuyStoreOffer` (modo B) |
| `src/client/protocolgameparse.cpp` | `parseStore`, `onStoreInit` (modo B) |

**Não confundir com:** `modules/game_npctrade/` — trade com NPC no mapa.

## Arquivos responsáveis (servidor — `otserv_860`)

| Arquivo | Função |
|---------|--------|
| `src/protocolgame.cpp` | Pacote `0x32` extended opcode; envia opcode `0` ao login OTClient para **habilitar** envio no cliente |
| `src/game.cpp` | `parsePlayerExtendedOpcode` → evento Lua |
| `src/creatureevent.cpp` | Tipo `extendedopcode` → `onExtendedOpcode` |
| `data/lib/core/player.lua` | `Player.sendExtendedOpcode` |
| `data/lib/core/json.lua` | Encode/decode JSON (necessário para o shop) |
| **`data/creaturescripts/scripts/otcv8_shop.lua`** | **Catálogo (`initShop()`), preços, compra** — opcode **201** |
| `data/creaturescripts/creaturescripts.xml` | Registro do evento `ExtendedOpcode` |
| `data/creaturescripts/scripts/others/login.lua` | `player:registerEvent("ExtendedOpcode")` |
| `global.sql` / conta | Coluna **`accounts.coins`** (saldo da loja) |
| `docs/shop_history.sql` | Tabela opcional para histórico de compras |

## Por que a janela abre vazia (cinza)

Fluxo ao abrir o Shop:

1. Cliente chama `check()` → `sendAction("init")` (opcode 201, JSON).
2. Só envia se `g_game.getFeature(GameExtendedOpcode)` estiver ativo.
3. Servidor deve responder JSON `{ action: "categories", data: [...], status: {...} }`.
4. `onExtendedJSONOpcode` → `processCategories` preenche a UI.

**Falhas comuns:**

| Sintoma | Causa |
|---------|--------|
| Painéis vazios, sem erro | Servidor **não** responde ao `init` (sem script opcode 201) |
| Log: `Unable to send extended opcode 201...` | `GameExtendedOpcode` desligado no cliente (`features.lua`) |
| Categorias vazias | `init()` do servidor sem ofertas ou `ItemType(id):getClientId()` inválido |
| Modo Tibia Store | `GameIngameStore` só com cliente ≥ 1080; **860 não recebe** `onStoreInit` |

## Correção aplicada neste repo

1. **Cliente:** `GameExtendedOpcode` habilitado para versão **≥ 860** em `features.lua`.
2. **Servidor:** script `otcv8_shop.lua` + `json.lua` + registro em `creaturescripts.xml` e `login.lua`.
3. **Cliente:** mensagem na UI se o shop não estiver configurado.

## Configurar produtos (servidor) — arquivo único

**Arquivo:** `otserv_860/data/creaturescripts/scripts/otcv8_shop.lua`  
**Função:** `initShop()`

```lua
local cat = addCategory({
  type = "item",
  item = ItemType(2160):getClientId(), -- ícone da categoria (clientId)
  count = 1,
  name = "Items"
})
cat.addItem(custoCoins, itemIdServidor, quantidade, "Titulo", "Descricao")
```

- `addItem` usa **itemId do servidor**; o script gera o `clientId` para o cliente.
- Reiniciar **`tfs.exe`** após qualquer alteração.

## Saldo (coins)

- Lidos/gravados em **`accounts.coins`** (não `premium_points`).
- Conta `god` no dump: `coins = 9999`.
- UI do cliente mostra **Coins:** (campo JSON `status.points`).

```sql
UPDATE accounts SET coins = 100 WHERE name = 'god';
```

## Histórico de compras (opcional)

Executar uma vez:

```sql
-- ver docs/shop_history.sql no servidor
```

Sem a tabela, compras funcionam; só o botão “Transaction history” fica vazio.

## Teste rápido

1. Reiniciar **tfs.exe** e **otclient_gl.exe**.
2. Login `god` / personagem.
3. Abrir Shop → deve aparecer categoria **“Items”** com ofertas de exemplo.
4. `otclientv8.log`: não deve aparecer erro de extended opcode 201.

## Referências

- [OTLand — In Game Store OTClient v8 and TFS 1.3](https://otland.net/threads/in-game-store-ot-client-v8-and-tfs-1-3.273384/)
- Opcode cliente: `SHOP_EXTENTED_OPCODE = 201` em `shop.lua` (typo histórico “EXTENTED”)
