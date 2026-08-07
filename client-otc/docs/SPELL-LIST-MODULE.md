# Assign Spell — lista do TFS (opcode 202)

Documentação **completa** (servidor + protocolo + `spells.xml`):  
**`otserv_860/docs/SPELL-LIST-MODULE.md`**

## Neste repo (cliente)

| Arquivo | O que fazer |
|---------|-------------|
| `modules/game_actionbar/actionbar.lua` | Único arquivo da feature — opcode 202, cache, `assignSpell` |
| `modules/gamelib/spells.lua` | **Não** é a lista do Assign Spell; só ícones/exhaust quando o nome bate |
| `docs/ASSIGN-SPELL.md` | Sintomas (lista vazia), filtros, testes |

**Não precisa rebuild C++** — reiniciar `otclient_gl.exe` após editar Lua.

## Comportamento

- Login → pedido `request` (~800 ms) → cache `serverSpellList`.
- Assign Spell → lista do servidor; fallback `SpellInfo` se cache ainda vazio.
- Filtro **vocation** desligado com lista do servidor (TFS já filtrou `canCast`).
- Hotkey no botão usa `words` / `name` enviados pelo servidor.

## Servidor

Opcode **202**, lib `data/lib/otcv8_spelllist.lua`, talkaction `!spelllist`.  
Ver `otserv_860/docs/SPELL-LIST-MODULE.md`.
