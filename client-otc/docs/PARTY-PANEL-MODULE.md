# Painel Party — `game_party` (OTCv8)

Módulo **`modules/game_party/`** — janela de party no cliente. Compartilha o **opcode 204** com o minimap.

Documentação completa: `otserv_860/docs/PARTY-MODULE.md`.

---

## Uso

| Item | Detalhe |
|------|---------|
| Abrir | Botão **Party** no topmenu (`/images/topbuttons/party.png`) ou **Ctrl+Shift+P** |
| Ícone | `data/images/topbuttons/party.png` — não usar `battle_party` (spritesheet quebra no topmenu) |
| Dados | Servidor envia `partyStatus` a cada 500 ms (+ pedido ao abrir) |
| Minimap | Mesmo opcode — `game_minimap.onPartyStatusUpdate` |

---

## Arquivos

| Arquivo | Função |
|---------|--------|
| `party.lua` | Opcode 204, UI, botões leave/shared exp |
| `party.otui` | `PartyMemberRow`, janela `partyWindow` |
| `party.otmod` | Módulo; carregado após `game_minimap` |

---

## Botões

| Botão | Quem vê | Ação |
|-------|---------|------|
| **Enable/Disable Shared Exp** | Líder | `g_game.partyShareExperience(...)` |
| **Leave** | Todos em party | `g_game.partyLeave()` |

Convidar / expulsar / passar liderança: continua no **menu botão direito** (`gameinterface.lua`).

---

## Após editar

| O quê | Ação |
|-------|------|
| Só Lua/OTUI cliente | Reiniciar `otclient_gl.exe` |
| `otcv8_party.lua` servidor | Reiniciar `tfs.exe` |
