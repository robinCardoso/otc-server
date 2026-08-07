# Assign Spell (action bar) — diagnóstico e manutenção

## Sintoma

Janela **Assign Spell to Action Button** abre, mas a lista de magias fica **vazia** (só o cabeçalho/preview da magia já no botão, se houver).

## Fluxo

```
assignSpell() → actionbar.lua
  ├─ serverSpellList preenchido? → JSON opcode 202 (spells.xml no TFS)
  │     └─ ícones/cd: SpellInfo['Default'] por nome (fallback ícone genérico)
  └─ senão → SpellInfo local + request opcode 202 → atualiza janela ao receber
  → filterSpells() (level opcional; vocação off com lista do servidor)
```

**Manutenção completa:** `otserv_860/docs/SPELL-LIST-MODULE.md` · **Resumo cliente:** `docs/SPELL-LIST-MODULE.md`

## Causas corrigidas (2025)

| # | Causa | Efeito |
|---|--------|--------|
| 1 | `translateVocation()` para `getClientVersion() >= 910` mapeava voc 1→8, etc. | Com login em versão alta ou proxy, filtro "vocation" ocultava **todas** as magias |
| 2 | `widget.spellData.level` não era preenchido | Com "Only show usable spells (Level)" marcado, `level == nil` → **nenhuma** magia visível |

## Arquivos

| Arquivo | Função |
|---------|--------|
| `modules/game_actionbar/actionbar.lua` | `assignSpell`, `translateVocation`, `filterSpells` |
| `modules/game_actionbar/spell.otui` | UI, checkboxes (vocation/level) |
| `modules/gamelib/spells.lua` | `SpellInfo`, `SpellIcons`, nível/vocação por magia |

Referência que **funciona** com mesma base de dados: `modules/game_spelllist/spelllist.lua` (`table.find(info.vocations, localPlayer:getVocation())`).

## Teste manual

1. Personagem vocação 1–8, nível ≥ 9.
2. Action bar → Assign Spell.
3. Só **"Only show vocation spells"**: deve listar magias da vocação (ex. sorc: exura, exori, …).
4. Só **"Only show usable spells (Level)"**: magias com `level` > nível do char somem.
5. Ambos: interseção dos dois filtros.
6. Login `127.0.0.1:7171:860` — confirmar `g_game.getClientVersion()` == 860 no console Lua se ainda falhar.

## Se ainda estiver vazio

- Conferir `init.lua` / servidor: terceiro número da porta deve ser **860** (não 1098/1341).
- Desmarcar os dois filtros — se aparecer tudo, é filtro/vocação/nível.
- Ver log por erro em `SpellIcons[icon]` ausente ao criar widgets.

## Lista do servidor (opcode 202) — implementado

Plano: **`otserv_860/docs/SPELL-LIST-PLAN.md`**

| Item | Detalhe |
|------|---------|
| Opcode | **202** (`action: request` → `spellList`) |
| Cliente | `modules/game_actionbar/actionbar.lua` — `registerExtendedJSONOpcode`, cache `serverSpellList` |
| Prefetch | ~800 ms após login |
| Assign Spell | Lista do servidor; ícones/cd/grupos do `SpellInfo` quando o nome bate |
| Filtro vocação | Desligado automaticamente com lista do servidor (TFS já filtrou) |
| Fallback | Se opcode não responder, lista local `SpellInfo` |

**Teste Sorc 27:** `!spelllist` no jogo + Assign Spell — deve listar `Animate Dead` (conjure `adana mort`) se `canCast` no TFS.

## Alterar magias no servidor

Editar `otserv_860/data/spells/spells.xml` → reiniciar TFS. Cliente: reabrir Assign Spell (prefetch no login) ou `!spelllist`. **Não** editar `spells.lua` do OTC para a lista — só para ícone de magias novas/custom.
