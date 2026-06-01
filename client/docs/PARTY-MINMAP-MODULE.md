# Party minimap — cliente OTCv8

Marcadores de **membros da party** no minimap. Dados vêm do servidor (opcode **204**); desenho é 100% local.

Documentação completa (C++ party + servidor + deploy): `otserv_860/docs/PARTY-MODULE.md`.

---

## Visual

| Elemento | Estilo |
|----------|--------|
| Jogador local | Cruz `MinimapCross`, cor **#3388FF** (`uiminimap.lua` → `setCrossPosition`) |
| Membro da party | `MinimapPartyDot` — quadrado **8×8**, verde `#33CC33`, borda `#115511` |
| Outro andar (Z diferente) | Mesmo X/Y projetado no andar da câmera; dot **pisca**; tooltip `Nome (Floor Z)` |
| Distância | **Sem limite** — posição vem do servidor, não de `getSpectators` |

Convidados com escudo azul/amarelo de convite **não** entram na lista do opcode (só líder + `party:getMembers()` no TFS).

---

## Módulo principal

**`modules/game_minimap/minimap.lua`**

| Variável / constante | Uso |
|---------------------|-----|
| `PARTY_MINIMAP_OPCODE` | 204 |
| `partyRemoteMembers` | Cache por nome: `x`, `y`, `z`, `updatedAt` |
| `partyDots` | Widgets `MinimapPartyDot` por membro |
| `PARTY_DOT_REQUEST_MS` | 250 — pedido ao servidor |
| `PARTY_DOT_REFRESH_MS` | 150 — redesenho |
| `PARTY_DOT_BLINK_MS` | 450 — toggle visibilidade (outro andar) |

### Fluxo

1. `registerPartyMinimapOpcode()` no `init` e `online` (sem depender de feature no registro).
2. `requestPartyMinimapPositions()` envia `{ action = "request" }` se `GameExtendedOpcode` ativo e jogador em party.
3. `onPartyMinimapExtendedJSON` atualiza `partyRemoteMembers` a partir de `data.members`.
4. `refreshPartyDots()` mescla cache remoto + `collectVisiblePartyMembers()` (refino quando na tela).
5. `centerInPosition(dot, { x, y, z = cameraZ })` — para outro andar, ancora X/Y no plano do minimap atual.

### Eventos

| Evento | Ação |
|--------|------|
| `LocalPlayer.onPositionChange` | Atualiza câmera + pede opcode |
| `LocalPlayer.onShieldChange` | Limpa cache se saiu da party |
| `Creature.onPositionChange` (party) | Pede opcode |
| `Creature.onShieldChange` | Remove membro do cache se perdeu escudo de party |
| `UIMinimap.onCameraPositionChange` | `refreshPartyDots()` |

**Não** usar `onDisappear` para limpar cache — causava sumiço falso ao sair da tela.

---

## Arquivos UI

| Arquivo | Conteúdo |
|---------|----------|
| `data/styles/40-minimap.otui` | `MinimapPartyDot`, minimap expandido (`Expand` / Ctrl+Shift+M) |
| `minimap_overlay.otui` | Overlay do mapa grande |

---

## Requisitos

- `modules/game_features/features.lua` — `GameExtendedOpcode` para versão **≥ 860**
- Servidor com `ExtendedOpcodePartyMinimap` + GlobalEvent — ver `PARTY-MODULE.md`

---

## Após editar

| O que mudou | Ação |
|-------------|------|
| Só `minimap.lua` / OTUI | Reiniciar `otclient_gl.exe` |
| Servidor Lua | Reiniciar `tfs.exe` |
| C++ party (`party.cpp`, etc.) | Rebuild servidor — não afeta este módulo |

---

## Diagnóstico

1. Shop (201) abre e lista itens → extended opcode OK no cliente.
2. Dois personagens em party: um anda longe → quadrado verde deve permanecer (borda do minimap se longe).
3. Um desce escada → verde **piscando** no mesmo X/Y.

Se falhar só longe: problema no opcode 204 ou GlobalEvent do servidor, não no desenho do dot.
