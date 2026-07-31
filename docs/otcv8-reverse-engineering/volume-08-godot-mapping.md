# Volume 8 — Godot Mapping

> **Status:** 🟡 Contínuo — atualizado 2026-07-30 após Fase A volumes 1,3–7

---

## Tabela consolidada OTC → Godot

### Rede e protocolo (Volume 2 — referência)

| OTC | Godot | Status | Notas |
|---|---|---|---|
| `ProtocolLogin` | `Protocol.gd` | ✅ | RSA + char list |
| `ProtocolGame` | `GameProtocol.gd` | ✅ | Handshake + loop |
| `parseMessage()` | `OpcodeDispatcher` + `GameOpcodeReader` | ✅ | |
| `InputMessage` | `ProtocolReader.gd` | ✅ | |
| `parseMapDescription()` | `MapParser.gd` | ⚠️ | Desync ativo — Volume 2 |
| `getItem()` | `ThingReader.read_item()` | ⚠️ | Flags DAT — Volume 7 |
| `getCreature()` | `ThingReader.read_creature()` | ✅ | |
| `parseCreatureMove` | `CreatureManager` | ⚠️ | Falta `allowAppearWalk` chain |
| `parseCancelWalk` (0xB5) | — | ⬜ | Volume 4 §4.3 |

### Estado do jogo (Volume 1 + 4)

| OTC | Godot | Status | Notas |
|---|---|---|---|
| `Map` | `GameWorld` → `MapManager` | ✅ | |
| `Tile` | `MapTile` | ✅ | |
| `Creature` | `CreatureManager` | ✅ | |
| `LocalPlayer` | `PlayerController` | ⚠️ | Sem autowalk async |
| `Container` | `ContainerManager` | ✅ | |
| `Inventory` | `InventoryManager` | ✅ | |
| `Effect` | `EffectManager` | ✅ | |
| `AwareRange` 25×20 | `MapState` constants | ⚠️ | Volume 4 §8.1 |
| `removeUnawareThings` | — | ⬜ | Volume 6 §4.3 |

### Renderização (Volume 3)

| OTC | Godot | Status | Notas |
|---|---|---|---|
| `MapView` | `MapView.gd` | ⚠️ | Ordem layers, FBO |
| `DrawQueue` (ex-DrawPool) | `CanvasItem._draw()` | ⬜ | Sem batching manual |
| `DrawCache` batching | MultiMesh / RS batch | ⬜ | |
| `LightView` | Shader 2D / Modulate | ⬜ | CPU lightmap no OTC |
| `AdaptiveRenderer` | LOD manual | ⬜ | Volume 3 §5 |
| Walk offset câmera | — | ⬜ | Volume 3 §2.4 |
| Floor fading | — | ⬜ | |

### Gameplay / walking (Volume 4)

| OTC | Godot | Status | Notas |
|---|---|---|---|
| `Creature::walk()` + `updateWalk()` | `CreatureWalker.gd` | ⚠️ | Offset linear 8.60 |
| `getStepDuration()` fórmula 8.60 | — | ⬜ | beat + diagonal ×1.5 |
| `getWalkOffset()` / walking tile | — | ⬜ | |
| `Game::walk()` + sendWalk* | `PlayerController` | ✅ | |
| `LocalPlayer::autoWalk()` | — | ⬜ | |
| `Map::findPathAsync()` | — | ⬜ | **Bloqueia clique mapa** |
| `Game::autoWalk()` + sendAutoWalk | parcial | ⚠️ | |
| `tryVisualWalkStep` | — | ⬜ | OTC também incompleto |
| Fases animação pé | — | ⬜ | |

### UI (Volume 5)

| OTC | Godot | Status | Notas |
|---|---|---|---|
| `game_interface` | `GameHUD.tscn` | ⚠️ | Classic view |
| `game_inventory` | HUD inventory | ✅ | |
| `game_containers` | HUD containers | ✅ | |
| `game_walking` | input parcial | ⚠️ | Smart walk, turn |
| `game_battle` | — | ⬜ | |
| `game_console` | — | ⬜ | |
| `game_minimap` | — | ⬜ | |
| `processMouseAction` | — | ⬜ | Use/look/attack |

### Assets (Volume 7)

| OTC | Godot | Status | Notas |
|---|---|---|---|
| `SpriteManager` / RLE | `SpriteReader.gd` | ✅ | |
| `ThingTypeManager` / DAT | `DatReader.gd` | ✅ | |
| Flags DAT → protocolo | `ThingReader` | ⚠️ | Desync getItem |
| `Atlas` 4096² | — | ⬜ | |
| `Outfit` colorização layers | `ThingSpriteFactory` | ⚠️ | head/body/legs/feet |
| ThingType unload 60s | ResourceLoader | ✅ | nativo |

### Performance (Volume 6)

| OTC | Godot | Status | Notas |
|---|---|---|---|
| Visible tiles cache | — | ⬜ | |
| Pathfinding async thread | WorkerThreadPool | ⬜ | |
| Adaptive text/effect limits | — | ⬜ | |
| Draw thread split | Engine nativo | ✅ | |

---

## Legenda de status

| Símbolo | Significado |
|---|---|
| ✅ | Implementado e funcional |
| ⚠️ | Implementado com gaps conhecidos |
| ⬜ | Não implementado |

---

## Prioridade de implementação (pós Fase A)

| # | Item | Volume | Bloqueio |
|---|---|---|---|
| 1 | Corrigir desync protocolo (`getItem`, map) | 2, 7 | Login quebra |
| 2 | `findPathAsync` + `autoWalk` | 4 | Clique mapa |
| 3 | `getStepDuration` + walk offset 8.60 | 4 | Movimento errado |
| 4 | `parseCancelWalk` | 4 | Walk travado |
| 5 | Light rendering | 3 | Visual noturno |
| 6 | Outfit layers | 7 | Sprites player |
| 7 | UI console/battle | 5 | Gameplay social |

---

## Riscos de migração

| Risco | Impacto | Mitigação |
|---|---|---|
| Desync protocolo | Crítico | Volume 2 — bytes TFS |
| Viewport 18×14 vs 25×20 | Crítico | Volume 4 §8 — `GameBiggerMapCache` |
| Pathfinding ausente | Alto | Volume 4 §7 |
| Walk timing errado | Alto | Volume 4 §5.2 — serverBeat |
| Light ausente | Médio | Volume 3 §4 — shader multiply |
| DrawQueue portado literal | Baixo | Usar CanvasItem nativo |
| 50+ módulos Lua | Médio | Volume 5 — priorizar 6 módulos |

---

## Histórico

| Data | Alteração |
|---|---|
| 2026-07-30 | Versão inicial volumes 2–7 |
| 2026-07-30 | Fase A: volumes 1,3–7 documentados; tabela expandida com gaps Volume 4 |
