# OTCv8 Reverse Engineering — Manual Técnico

Documentação técnica do OTClient v8 (`client/`) para guiar a implementação do cliente Godot 4.7+.

> **Metodologia:** entender *por que* cada subsistema existe antes de portar para Godot.
> Ver [`plano.md`](../../plano.md) §2–§3.

---

## Volumes

| Vol. | Arquivo | Título | Status |
|---|---|---|---|
| 1 | [volume-01-arquitetura-geral.md](volume-01-arquitetura-geral.md) | Arquitetura Geral | 🟡 ~75% |
| 2 | [volume-02-networking.md](volume-02-networking.md) | Networking | 🟡 Em progresso |
| 3 | [volume-03-rendering.md](volume-03-rendering.md) | Rendering | 🟡 ~80% |
| 4 | [volume-04-gameplay.md](volume-04-gameplay.md) | Gameplay | 🟡 ~85% |
| 5 | [volume-05-ui.md](volume-05-ui.md) | UI / OTUI / Lua | 🟡 ~70% |
| 6 | [volume-06-performance.md](volume-06-performance.md) | Performance | 🟡 ~65% |
| 7 | [volume-07-assets.md](volume-07-assets.md) | Assets (SPR/DAT) | 🟡 ~80% |
| 8 | [volume-08-godot-mapping.md](volume-08-godot-mapping.md) | Godot Mapping | 🟡 Contínuo |

---

## Fontes de referência

| Fonte | Caminho | Uso |
|---|---|---|
| Parse de pacotes | `client/src/client/protocolgameparse.cpp` | Bytes servidor → cliente |
| Envio de pacotes | `client/src/client/protocolgamesend.cpp` | Bytes cliente → servidor |
| Opcodes | `client/src/client/protocolcodes.h` | Constantes de opcode |
| Features por versão | `client/modules/game_features/features.lua` | O que ler em cada protocolo |
| Walking 8.60 | `client/src/client/localplayer.cpp`, `creature.cpp` | Movimento e animação |
| Pathfinding | `client/src/client/map.cpp:852` | findPath / findPathAsync |
| Render pipeline | `client/src/framework/core/graphicalapplication.cpp` | Threads + DrawQueue |
| Servidor TFS | `server/src/networkmessage.cpp` | O que o servidor **realmente** envia |
| Alterações locais | `client/docs/CLIENT-CHANGES.md`, `MAP-SMOOTH.md` | Fork 8.60 |

---

## Convenções

- **Opcode** em hex (`0x64`)
- **Tipos de campo:** `u8`, `u16`, `u32`, `string` (u16 length + UTF-8)
- **Features** referenciadas como em `const.h` (`GameBiggerMapCache`, etc.)
- Cada seção termina com tabela **OTC → Godot → Status**
- "DrawPool" na literatura OTCv8 = **`DrawQueue`** no código (`framework/graphics/drawqueue.h`)

---

## Gaps críticos para Godot (resumo Fase A)

1. **Protocolo** — desync `getItem` / map (Volume 2)
2. **Pathfinding async** — `findPathAsync` não portado (Volume 4)
3. **Walk timing 8.60** — `getStepDuration` + offset linear (Volume 4)
4. **Cancel walk** — `parseCancelWalk` (Volume 4)
5. **Light** — `LightView` multiply pass (Volume 3)
