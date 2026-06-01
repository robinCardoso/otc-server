# Assign Spell — lista do TFS (opcode 202)

## Resumo

O **Assign Spell** da action bar lista magias vindas do servidor (`data/spells/spells.xml` carregado no TFS), **não** o catálogo fixo `SpellInfo` do OTC.

| Opcode | Uso |
|--------|-----|
| **201** | Shop OTCv8 — ver `docs/SHOP-MODULE.md` |
| **202** | Lista de magias (`spellList`) — Assign Spell |
| **203** | Combat Power |
| **205** | Estoque depot |

**Rebuild C++:** necessário após mudar `pushInstantSpell` (`group` no Lua). Só Lua no handler: reiniciar `tfs.exe`. **Cliente:** reiniciar `otclient_gl.exe` após mudar `modules/game_actionbar/`.

---

## Fonte da verdade

```
data/spells/spells.xml
    → TFS C++ (g_spells->loadFromXml na subida)
    → player:getInstantSpells()  (filtro canCast: vocação + needlearn)
    → Otcv8SpellList (Lua) JSON opcode 202
    → actionbar.lua (cache + Assign Spell)
```

| Entra na lista (opcode 202) | Não entra |
|-----------------------------|-----------|
| `<instant …>` | `<rune …>` puras (SD, GFB no action bar = tipo **ITEM**) |
| `<conjure …>` (ex. `adana mort` → Animate Dead) | Magias só no `spells.lua` do cliente (ex. `utori flam` se ausente no XML) |

**Nível/mana:** `getInstantSpells()` usa `canCast` (vocação + aprendizado). **Não** esconde magias acima do level do char — o filtro **"Only show usable spells (Level)"** no cliente faz isso.

**vocations.xml:** define IDs de vocação; cada magia em `spells.xml` referencia `<vocation id="…"/>`. Não é lido diretamente pelo opcode 202.

---

## Bug historico: magias fantasma no modal

**Sintoma:** Assign Spell mostrava centenas de magias (ex. `utori flam`) que não existem em `spells.xml`.

**Causa:** servidor `-orig` sem handler opcode 202 + cliente preenchia fallback `SpellInfo['Default']` enquanto aguardava resposta.

**Fix:** módulo `otcv8_spelllist.lua` no TFS + cliente **sem** fallback local (só loading/timeout).

---

## Arquivos — servidor (`otserv_860-orig`)

| Arquivo | Função |
|---------|--------|
| `data/lib/otcv8_spelllist.lua` | `Otcv8SpellList.send`, `buildPlayerSpellList`, `resolveCategory` |
| `data/lib/lib.lua` | `dofile('data/lib/otcv8_spelllist.lua')` |
| `data/creaturescripts/scripts/otcv8_spelllist.lua` | `onExtendedOpcode` — `request` / `spellList` |
| `data/creaturescripts/creaturescripts.xml` | `ExtendedOpcodeSpellList` |
| `data/creaturescripts/scripts/others/login.lua` | `registerEvent("ExtendedOpcodeSpellList")` |
| `data/talkactions/scripts/spelllist_debug.lua` | `!spelllist` (diagnóstico + reenvio) |
| `data/talkactions/talkactions.xml` | entrada `!spelllist` |

**Alterar magias no jogo:** editar `data/spells/spells.xml` → reiniciar TFS. Cliente: reabrir Assign Spell ou `!spelllist`.

---

## Arquivos — cliente (`otcv8-dev-orig`)

| Arquivo | Função |
|---------|--------|
| `modules/game_actionbar/actionbar.lua` | Opcode 202, `serverSpellList`, `assignSpell`, abas Attack/Support/Healing/Runas |
| `modules/game_actionbar/spell.otui` | Modal Assign Spell + `SpellCategoryTab` |
| `modules/gamelib/spells.lua` | **Só ícones** — `Spells.getSpellIcon`, `Spells.lookupLocalInfo` |

**Prefetch:** ~800 ms após login. **Assign Spell sem cache:** "Carregando magias do servidor..."; timeout 5 s se TFS não responder.

---

## Protocolo JSON

**Cliente → servidor:**

```json
{ "action": "request", "data": {} }
```

**Servidor → cliente:**

```json
{
  "action": "spellList",
  "data": {
    "vocation": 1,
    "level": 27,
    "maglevel": 20,
    "count": 42,
    "spells": [
      {
        "name": "Animate Dead",
        "words": "adana mort",
        "level": 27,
        "mlevel": 4,
        "mana": 600,
        "premium": false,
        "parameter": false,
        "group": "support",
        "category": "runes"
      }
    ]
  }
}
```

### Campo `category` (abas Assign Spell)

| Valor | Regra (servidor) |
|-------|------------------|
| `runes` | Conjure de runa — palavras `adevo`/`adana`/`adori`/`adura`/`adori blank` (prioridade sobre `group`) |
| `attack` | `group="attack"` em `spells.xml` |
| `healing` | `group="healing"` (exura, exura gran — instants) |
| `support` | Resto (support, conjure arrow/bolt, etc.) |

O cliente filtra a lista por aba + checkboxes vocação/level. Última aba: `g_settings` chave `assignSpellCategory`. Se o botão já tem magia, abre na aba dela.

---

## Teste rápido

1. Recompilar `tfs.exe` se mudou `src/luascript.cpp` (`group` em `pushInstantSpell`).
2. Reiniciar `tfs.exe` (ou `/reload creaturescripts` se mudou só Lua handler).
3. Reiniciar `otclient_gl.exe`.
4. Sorcerer → `!spelllist` (console: contagem `canCast` + linha `Categorias: attack=… support=… healing=… runes=…`).
5. Assign Spell → abas Attack / Support / Healing / Runas; **não** deve aparecer `utori flam` se ausente no XML.
6. Filtro level no cliente continua opcional; trocar aba e reabrir modal lembra última aba (`assignSpellCategory`).

Diagnóstico: `!spelllist`.

---

## Referência cruzada

Documentação espelho em `otserv_860/docs/SPELL-LIST-MODULE.md` e `otcv8-dev-orig/docs/SPELL-LIST-MODULE.md` (se existir).
