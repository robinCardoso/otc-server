# Combat Power — opcode 203 (-orig)

Modal **Poder de combate** no OTCv8: servidor calcula min/max de dano, defesa, armadura, magias e runas de cura; cliente exibe (`game_combatpower`).

Plano histórico (pasta dev): `otserv_860/docs/COMBAT-POWER-PLAN.md`.  
UI cliente: `otcv8-dev/docs/COMBAT-POWER-MODULE.md`.

---

## Arquitetura

```
OTC game_combatpower  --JSON opcode 203-->  otcv8_combatpower.lua
                                              --> player:getCombatPreview() [C++]
                                              --> CombatPreview::pushSpellPreviews / pushHealingRunePreviews
```

| Camada | Arquivo |
|--------|---------|
| C++ preview | `src/combatpreview.cpp`, `src/combatpreview.h` |
| Binding Lua | `player:getCombatPreview()` (luascript) |
| Lib servidor | `data/lib/otcv8_combatpower.lua`, `data/lib/otcv8_combatpower_spells.lua` |
| Handler opcode | `data/creaturescripts/scripts/otcv8_combatpower.lua` |
| Login | `data/creaturescripts/scripts/others/login.lua` → `ExtendedOpcodeCombatPower` |
| XML | `data/creaturescripts/creaturescripts.xml` |
| Talkaction | `data/talkactions/scripts/power_debug.lua` → `!power` |
| Cliente | `otcv8-dev-orig/modules/game_combatpower/` (Ctrl+Shift+O) |

**Shop (201)** é sistema separado: `otcv8_shop.lua` + `ExtendedOpcodeShop` — não misturar handlers.

---

## Protocolo

- **Opcode:** 203
- **Request (cliente → servidor):** JSON `{ "action": "request" }` ou `"combatPower"`
- **Response (servidor → cliente):** JSON `{ "action": "combatPower", "data": { ... } }`
- Pacotes grandes: chunking `S` / `P` / `E` em `Otcv8CombatPower.sendJSON`

Campos principais em `data`: `vocation`, `level`, `attack` (kind, min, max, `charmBonusPercent`, `charmLabel`, …), `defense`, `armor`, `equipment[]`, `spells[]`, `attackRunes[]`, `healingRunes[]`.

### Bestiary Charms no preview

Bônus permanentes de Charms (storages `151001`–`151016`, +1%/nível) entram no **mesmo cálculo** do combate real:

| Onde | Arquivo |
|------|---------|
| Lógica de bônus | `src/otcv8charms.cpp` — `applyOutgoingDamage`, `getBonusPercent` |
| Dano de arma no preview | `combatpreview.cpp` — `computeWeaponDamagePreview` |
| Magias/runas no preview | `combatpreview.cpp` — `safeApplyPreviewValues` |
| Punho + elemento secundário | `luascript.cpp` — `luaPlayerGetCombatPreview` |
| Wand (tipo elemental) | `Weapon::getCombatType()` em `weapons.h` |

Campos extras em `attack`: `charmBonusPercent` (0–20), `charmLabel` (ex. `"Magia Gelo"`, `"Melee"`). O cliente exibe linha **Charm:** no modal Combat Power.

**Rebuild obrigatório** após alterar `otcv8charms.cpp`, `combatpreview.cpp` ou `luascript.cpp`.

---

## Causa do crash (0xC0000005) — corrigido

### Sintoma

- Login OTC ok até entrar no mundo; TFS encerra durante primeira resposta ao opcode 203.
- **Teste A:** comentar `player:registerEvent("ExtendedOpcodeCombatPower")` no `login.lua` → sem crash.

### Causa

`CombatPreview::pushSpellPreviews` iterava **todas** instant spells (milhares), incluindo spells sem vocação, house spells e grupos irrelevantes, chamando `getPreviewValues` / linked combat com callbacks inválidos.

### Fix atual (`src/combatpreview.cpp`)

1. **`isSpellForPlayerVocation`** — `vocMap` vazio → excluir; senão exigir `player->getVocationId()` no mapa.
2. Só grupos **`Attack`** e **`Healing`**.
3. Excluir nomes `House *`.
4. Null checks em spell, player, `g_spells`, itens de runa (`runeItemId`, `ItemType`).
5. Runas de cura: só se `countPlayerItems > 0` e vocação compatível.

Após alterar `combatpreview.cpp`: **recompilar** `tfs.exe` e copiar para a raiz.

### Knight / FirstItems / backpack (2026-05-28)

**Sintoma:** ADM (god) responde opcode 203; personagem novo **Knight** com `FirstItems` crashava (`exit=-1073741819`) no primeiro `opcode=203` — log parava em `ExtendedOpcodeCombatPower` sem `handler done`.

**Causa provável:** fase **`pushSpellPreviews`** (magias de vocação Knight com `applyPreviewValues` / callback SKILL), não runas — Knight novo não tem runas de cura; runas sem `<vocation>` no XML eram ignoradas para não-god. O scan recursivo da **backpack** em `countPlayerItems` (uma passagem por runa de cura) foi endurecido por precaução.

**Correções adicionais (`combatpreview.cpp`):**

| Item | Detalhe |
|------|---------|
| `ItemCountCache` | Usa `Player::getItemTypeCount(itemId, -1)` com cache por request (inventário + containers aninhados) |
| `isRuneForPlayer` | Runas sem vocação no XML = todas as vocações |
| `pushAttackRunePreviews` | Runas `group="attack"` com count > 0 no inventário |
| `safeApplyPreviewValues` | Entrada única para preview de dano/cura por magia/runa |
| Logs `[combatpreview]` | Com `enableTfsDiagnosticLog`: fases `weapon`, `equipment`, `spells`, `healingRunes` |

**Teste:** login **Eu Sou Knight** → abrir Combat Power (opcode 203) → TFS deve logar `handler done: ExtendedOpcodeCombatPower`.

### Knight + steel axe 8601 — `playerWeaponCheck(nullptr)` (2026-05-28)

**Evidência:** `debug-1ecf01.log` parava em `after_getWeapon` (H-B) sem `after_playerWeaponCheck`.

**Causa:** `luaPlayerGetCombatPreview` chamava `weaponTool->playerWeaponCheck(player, nullptr, …)`; em `weapons.cpp` isso acessa `target->getPosition()` → **access violation**.

**Fix:** usar o próprio `player` como alvo de preview (mesmo tile, distância 0). Melhorias:

| Item | Detalhe |
|------|---------|
| `CombatPreview::resolveAttackDisplayKind` | `rod` / `wand`, `spear` / `bow` / `crossbow` no campo `attack.kind` |
| `minVsPlayer` / `minVsMonster` | Preenchidos para `WEAPON_DISTANCE` (fórmulas 1.3× / 1.6× level) |
| `weapons.xml` | `<distance id="2456" swing="true" />` — arco básico (loadDefaults ignora bows com ammo) |
| Cliente | `KIND_NAMES` em `game_combatpower/combatpower.lua` |

### Dano negativo e número que “muda sozinho” (spear / distância)

**Sintoma:** `Dano fisico` mostrava `-7 - -26` ou `-17 - -26`; ao empilhar spears parecia mudar.

**Causas:**

1. **Sinal:** o TFS guarda dano como valores **negativos** (`-26` = 26 de dano). O cliente exibia o número bruto.
2. **Mínimo aleatório:** `getWeaponDamage(..., maxDamage=false)` com `target=nullptr` usa `normal_random(1, max)` — cada abertura do modal sorteia outro mínimo (não é a quantidade de spears).
3. **Distância real:** o piso contra player é `ceil(level × 1.3)` (no lvl 8 → **11**), contra monstro `× 1.6` (**13**); o teto é a fórmula de skill/atk (~**26** com spear 25).

**Fix:** `CombatPreview::computeWeaponDamagePreview` (determinístico) + `fmtRange` no cliente com `math.abs`. Linha extra **PvP / PvE** para `spear`, `bow`, etc.

### Moeda / item sem tipo no slot (mao, capacete)

**Sintoma:** platinum/gold coin na mao; Combat Power instavel.

**Causa:** no `items.xml`, moedas so tem `weight` — `slotPosition == 0`, `weaponType == none`. O TFS aceitava em qualquer slot vazio (`queryAdd` retornava OK). O estoque usava `player:addItem`, que equipava na mao.

**Onde corrigir (nao e no XML da moeda):**

| Camada | Arquivo | Regra |
|--------|---------|--------|
| **Global (recomendado)** | `src/player.cpp` `queryAdd` | Sem slot/arma → `CANNOTBEDRESSED` em slots do corpo |
| **Estoque** | `data/lib/otcv8_stock.lua` | Retirar so para mochila/containers |
| **Combat Power** | `combatpreview.cpp` + `luascript.cpp` | `isValidCombatWeaponItem` — ignora lixo na mao |

Itens de ataque/defesa **devem** ter `weaponType` e/ou `slotType` no XML (ex. enchanted spear). Moedas **nao** precisam de slot no XML; vao para dentro da mochila.

---

## Performance

| Regra | Onde |
|-------|------|
| Filtrar por vocação no C++ | `pushSpellPreviews`, `pushHealingRunePreviews` |
| Uma chamada `getCombatPreview()` por envio | `Otcv8CombatPower.buildPlayerCombatPower` |
| `Otcv8CombatPowerSpells` não recalcula magias | Só repassa `preview.spells` do C++ |
| Cliente debounce 450 ms | `scheduleRequest()` em `combatpower.lua` |
| Primeiro request após login 900 ms | `onGameStart` → `scheduleEvent(requestCombatPower, 900)` |

Evitar: segundo `getCombatPreview()` no Lua; loop manual em `g_spells` no Lua.

---

## Como testar

### 1. Console — `!power`

No jogo (god ou talkaction liberada):

```
!power
```

- Imprime vocação, ataque, defesa, amostra de magias/runas.
- Chama `Otcv8CombatPower.send(player)` e confirma opcode 203.

### 2. Modal OTC

- Ctrl+Shift+O ou botão no top menu.
- Requer `GameExtendedOpcode` no cliente (`features.lua`).

### 3. Teste A/B (regressão crash)

1. Comentar `player:registerEvent("ExtendedOpcodeCombatPower")` em `login.lua`.
2. Reiniciar TFS, login OTC → deve **não** crashar.
3. Reativar linha após validar build com `combatpreview.cpp` atual.

### 4. Logs

Com `enableTfsDiagnosticLog = true` (rebuild): observar `[extopcode]` ao abrir modal.

---

## Estado do registro (validado)

`login.lua`:

```lua
player:registerEvent("ExtendedOpcodeShop")
player:registerEvent("ExtendedOpcodeCombatPower")
```

`creaturescripts.xml`:

```xml
<event type="extendedopcode" name="ExtendedOpcodeShop" script="otcv8_shop.lua" />
<event type="extendedopcode" name="ExtendedOpcodeCombatPower" script="otcv8_combatpower.lua" />
```

---

## Ícones no cliente

Servidor envia **nomes**, `words`, `itemId` / `clientId` — **não** envia imagens.

Cliente resolve ícones via `modules/gamelib/spells.lua` (`Spells.getSpellIcon`, `Spells.getRuneDisplayIcon`).

---

## Runas no inventário (ataque + cura)

- **`attackRunes[]`:** runas `group="attack"` (SD, GFB, HMM, …) com `count > 0` — preview `damageMin`/`damageMax` via `safeApplyPreviewValues`.
- **`healingRunes[]`:** runas `group="healing"` (IHR, UHR, …) com `count > 0` — preview `healMin`/`healMax`.
- Contagem: `Player::getInventoryItemCount` → `getItemTypeCount` (mochila e sub-containers).
- Cliente: seção **Runas (inventário)**; refresh automático em `Container.onUpdateItem` (debounce 450 ms).

## Próximas fases

- Paladin distance UI completa (plano original fase 2).

Ver `otserv_860/docs/COMBAT-POWER-PLAN.md` e `otserv_860/docs/DAMAGE.md`.
