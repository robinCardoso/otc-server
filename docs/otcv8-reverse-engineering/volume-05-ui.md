# Volume 5 — UI / OTUI / Lua

> **Status:** 🟡 Em progresso — pipeline e módulos principais mapeados
> **Fonte primária:** `client/modules/`, `client/data/styles/`, `framework/ui/`, `framework/luaengine/`

---

## 1. Pipeline OTC

```
init.lua
  → g_modules.discoverModules() / autoLoadModules
  → modules carregam .otmod + .lua

Módulo Lua (ex: game_interface)
  → carrega .otui (layout declarativo)
  → UIWidget C++ instanciado via g_ui.createWidget
  → callbacks Lua (onClick, onMouseRelease)
  → chama g_game.* / g_map.*

g_game (C++) processa protocolo
  → callLuaField("g_game", "onXxx", ...)  → módulos connect()
```

### Por que Lua + OTUI?

- **OTUI** — layout declarativo estilo CSS (posição, anchors, estilos)
- **Lua** — comportamento, sem recompilar C++
- **C++** — performance para mapa, protocolo, rendering

**Tradução Godot:** `.otui` → `.tscn` + `Theme`; Lua callbacks → signals GDScript.

---

## 2. Camadas do framework UI

| Camada | Caminho | Responsabilidade |
|---|---|---|
| OTML/OTUI parser | `framework/otml/` | Parse de `.otui` |
| UIWidget | `framework/ui/uiwidget*.cpp` | Widget base, eventos, draw |
| UIMap | `client/uimap.cpp` | MapView embutido em widget |
| Lua bindings | `luafunctions_client.cpp` | `g_game`, `g_map`, `LocalPlayer` |

### OTUI — layout vs estilo vs comportamento

| Aspecto | Onde | Exemplo |
|---|---|---|
| Layout | `.otui` | `anchors.fill: parent`, `size: 200 300` |
| Estilo | `data/styles/*.otui` | cores, fontes, borders |
| Comportamento | `.lua` do módulo | `connect(g_game, { onInventoryChange = ... })` |

---

## 3. Ciclo de boot UI

**Arquivo:** `client/init.lua`

```
1. g_configs.loadSettings
2. g_resources.setLayout("modern" | "mobile")
3. g_modules.autoLoadModules(99)   — corelib
4. g_modules.autoLoadModules(499)  — client_*
5. g_modules.autoLoadModules(999)  — game_*
6. client_entergame → tela login
7. Após login → game_interface monta HUD
```

**Prioridade módulo:** campo `priority` em `module.otmod` — menor carrega primeiro.

---

## 4. Módulos principais (gameplay)

### 4.1 Core do jogo

| Módulo | Responsabilidade | Signals `g_game` / `LocalPlayer` |
|---|---|---|
| `game_interface` | HUD, mapa, mouse actions, classic view | `onGameStart`, `onGameEnd` |
| `game_inventory` | Slots de equipamento | `onInventoryChange`, `onAutoWalk` |
| `game_containers` | Janelas de container | `onOpenContainer`, `onCloseContainer` |
| `game_walking` | Teclas WASD/setas, smart walk | `LocalPlayer.onWalk`, `onWalkFinish`, `onCancelWalk` |
| `game_console` | Chat | `onTalk`, `onTextMessage` |
| `game_battle` | Battle list | `onAttackingCreatureChange` |
| `game_skills` | Skills/stats | `onSkillChange`, `onLevelChange` |
| `game_minimap` | Minimapa + autowalk | `player:autoWalk()` |
| `game_textmessage` | Mensagens na tela | `onAutoWalkFail` |
| `game_features` | Features por versão | `onClientVersionChange` |

### 4.2 Cliente / infra

| Módulo | Responsabilidade |
|---|---|
| `client_entergame` | Login, char list |
| `client_options` | Settings |
| `client_styles` / `client_theme` | Temas visuais |
| `corelib` / `gamelib` | Utilitários Lua, constantes |
| `game_protocol` | Helpers de protocolo Lua |
| `game_things` | Load SPR/DAT |

### 4.3 Fluxo clique no mapa

**Arquivo:** `modules/game_interface/widgets/uigamemap.lua` + `gameinterface.lua`

```
onMouseRelease (UIGameMap)
  → getPosition(mouse) → autoWalkPos
  → processMouseAction(button, autoWalkPos, lookThing, useThing, ...)
      → ataque / use / look / menu contexto
      → se walk: player:autoWalk(autoWalkPos)   ← C++ findPathAsync
```

**Classic control:** RMB não autowalk; minimapa sem autowalk com classic.

| OTC | Godot | Status |
|---|---|---|
| `game_interface` | `GameHUD.tscn` | ✅ parcial |
| `game_inventory` | HUD inventory | ✅ |
| `game_containers` | HUD containers | ✅ |
| `game_walking` | `PlayerController` input | ⚠️ |
| `game_battle` | — | ⬜ |
| `game_console` | — | ⬜ |
| `game_skills` | — | ⬜ |
| `game_minimap` | — | ⬜ |

---

## 5. Padrão signals C++ → Lua

```cpp
// Exemplo: LocalPlayer::setHealth
callLuaField("onHealthChange", health, maxHealth, oldHealth, oldMaxHealth);
```

```lua
-- Módulo conecta no init()
connect(LocalPlayer, { onHealthChange = onHealthChange })
```

**Godot equivalente:** `Signal` em autoload + `connect()` nos managers.

### Eventos `g_game` mais usados

| Evento | Origem C++ |
|---|---|
| `onGameStart` | `Game::processGameStart` |
| `onGameEnd` | disconnect |
| `onTalk` | `parseCreatureSay` |
| `onTextMessage` | vários opcodes |
| `onOpenContainer` | `parseOpenContainer` |
| `onWalk` | `Game::walk` (antes de enviar) |
| `onAutoWalk` | `Game::autoWalk` |
| `onUse` | `Game::use` |

---

## 6. UIMap e MapView

**Arquivo:** `client/uimap.cpp`

`UIMap` é widget que encapsula `MapView`:
- `drawSelf()` chama `m_mapView->drawMapBackground/Foreground`
- Expõe para Lua: `setVisibleDimension`, `setDrawLights`, `getTile(position)`

**Godot:** `SubViewport` + script que chama mesmo pipeline do `MapView.gd`.

---

## 7. Classic view (config local)

**Arquivo:** `game_interface/gameinterface.lua`

```lua
CLASSIC_MAP_TARGET_TILE_PX = 40   -- init.lua
setVisibleDimension({ width = 15, height = 11 })
-- zoom calculado para tilePx alvo
```

**Por que existe?** Reproduz proporção do cliente oficial 8.6 (viewport menor centralizado) vs mapa full-width (25×20).

| OTC | Godot | Status |
|---|---|---|
| Classic 15×11 + zoom | — | ⬜ |
| Full width 25×20 | `MapState` | ⚠️ |

---

## 8. Módulos opcionais / servidor custom

| Módulo | Nota |
|---|---|
| `game_bot` | Bot framework — `findPath`, `autoWalk` Lua |
| `game_shop` | Extended opcode 201 |
| `game_stock` | Opcode 205 (config `init.lua`) |
| `updater` | Desabilitado neste fork |

---

## 9. Tradução OTUI → Godot

| OTUI | Godot |
|---|---|
| `MainWindow` | `Control` root full rect |
| `Panel` | `PanelContainer` / `NinePatchRect` |
| `GameMap` | `SubViewport` + `MapView` |
| `Item` | `TextureRect` + script |
| `anchors.*` | `Anchor` presets |
| `@onClick` | `pressed` signal |
| `modules.game_*` | Autoload ou child scene |

**Não portar 1:1** os 50+ módulos — priorizar por impacto gameplay (interface, inventory, containers, walking, console).

---

## 10. Gaps Godot

| Gap | Impacto |
|---|---|
| `game_walking` smart walk / turn keys | Movimento por teclado incompleto |
| `game_console` | Sem chat |
| `game_battle` | Sem target selection UI |
| Classic view toggle | UX diferente do OTC |
| Context menu (`processMouseAction`) | Use/look/attack com botões errados |

---

## 11. Referências

- **Volume 4** — autowalk via `player:autoWalk`
- **Volume 3** — UIMap rendering
- `client/init.lua` — boot e `APP_VERSION = 860`
- `client/modules/game_features/features.lua` — features UI-dependentes
