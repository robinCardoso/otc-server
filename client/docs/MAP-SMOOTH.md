# Mapa deslizando entre tiles (estilo Zezenia)

## O que já existe

| Camada | O quê |
|--------|--------|
| Cliente C++ | `getWalkOffset()` em tempo real, progresso **float** (sub-pixel) |
| Cliente C++ | Câmera: tile **de origem** do passo + offset (`mapview.cpp`) |
| Cliente C++ | Autowalk sem `terminateWalk` entre passos (`localplayer.cpp`) |
| Cliente C++ | Predição visual autowalk: `tryVisualWalkStep` + `setAutoWalkPath` (`game.cpp`) |
| Cliente C++ | Encadear `Creature::walk` se `oldPos == m_lastStepToPosition` |
| Cliente C++ | Smoothstep leve no progresso do passo |
| Cliente C++ | `blocksCardinalWalk` — sem `preWalk`/pacote/offset se mob na reta (**validado**: trapado = câmera estável) |
| Cliente Lua | Delays walk, dash, smart walk; `walking.lua` bloqueia cardinal com criatura |
| Servidor | Pacotes, actions, walkthrough diagonal |

## Por que ainda pode parecer “tile a tile”

1. **Latência do passo (servidor)** — cada sqm ainda depende do TFS; predição visual reduz, não elimina.
2. **`floorFading > 0`** — use **0** em Opções (migração v4).
3. **FPS / vsync** — testar `backgroundFrameRate` 60+ e vsync off.
4. **Classic view** — testar off se layout permitir.
5. **Protocolo 8.60** — sem duração de passo no pacote de movimento.

## Próximos passos (se ainda faltar)

| Prioridade | Onde | Ideia |
|------------|------|--------|
| Média | `creature.cpp` | Igualar `getStepDuration` ao `g_game.getServerBeat()` |
| Média | Render | `PointF` no offset de caminhada (sem `lround`) |
| Baixa | Servidor | Speed / scheduler entre passos |
| Teste | Manual | `otclient_dx.exe`, vsync, `debugWalking` |

## Ajuste fino

- **Predição autowalk:** `AUTO_WALK_PREDICT_PROGRESS` em `localplayer.cpp` (default **0.85**). Ping instável → **0.90**.
- **V-Sync:** manter **off** para LERP; ver seção em `pesquisa-zezenia-tibia.md`.
- **FPS:** 60+ ou max; evitar cap baixo (10–35).

## Teste rápido

1. `.\scripts\build-client.ps1`
2. Opções: **Floor fading = 0**, FPS 60, **vsync off**
3. Andar em linha reta e diagonal — mapa deve deslizar; entre passos de autowalk menos “trava”

## Debug

Ativar em extras: `debugWalking` — mostra duração do passo e offset no nome da criatura.
