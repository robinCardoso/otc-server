# Volume 1 — Arquitetura Geral

> **Status:** 🟡 Em progresso — estrutura, boot e singletons documentados
> **Fonte primária:** `main.cpp`, `client.cpp`, `graphicalapplication.cpp`, `framework/core/`

---

## 1. Objetivo

Mapa mental do OTCv8: onde vive cada subsistema, como inicializa, e quem depende de quem — base para portar módulos isolados no Godot.

---

## 2. Estrutura de pastas

```
client/
├── src/
│   ├── main.cpp                 # Entry point
│   ├── client/                  # C++ jogo: protocolo, mapa, criaturas
│   │   ├── game.cpp / map.cpp / creature.cpp / ...
│   │   ├── protocolgame*.cpp    # Rede jogo
│   │   └── luafunctions_client.cpp
│   └── framework/               # Engine reutilizável
│       ├── core/                # App, dispatcher, modules, clock
│       ├── graphics/            # DrawQueue, Painter, Atlas, GL
│       ├── net/                 # TCP, Protocol base
│       ├── ui/                  # UIWidget, layouts
│       └── luaengine/           # Lua VM, bindings
├── modules/                     # ~60 módulos Lua (game_*, client_*)
├── data/                        # things/, fonts/, styles/, images/
├── init.lua                     # Boot script
└── mods/                        # Mods opcionais
```

---

## 3. Singletons globais

| Singleton | Tipo | Responsabilidade |
|---|---|---|
| `g_app` | `GraphicalApplication` | Loop principal, janela, FPS |
| `g_client` | `Client` | Init/term client modules |
| `g_game` | `Game` | Estado jogo, LocalPlayer, ProtocolGame |
| `g_map` | `Map` | Tiles, criaturas, pathfinding |
| `g_sprites` | `SpriteManager` | SPR |
| `g_things` | `ThingTypeManager` | DAT |
| `g_dispatcher` | `EventDispatcher` | Fila eventos async (main logic) |
| `g_graphicsDispatcher` | | Eventos thread gráfica |
| `g_asyncDispatcher` | | Worker pool (pathfinding) |
| `g_ui` | `UIManager` | Widget tree, OTUI |
| `g_lua` | `LuaInterface` | VM Lua |
| `g_drawQueue` | `DrawQueue` | Fila draw corrente (thread-local) |
| `g_atlas` | `Atlas` | Texture atlas GPU |
| `g_adaptiveRenderer` | `AdaptiveRenderer` | LOD por FPS |
| `g_minimap` | `Minimap` | Cache minimap para pathfinding |
| `g_modules` | `ModuleManager` | Load ordem módulos Lua |

**Godot equivalente:** Autoloads (`GlobalNetwork`, `GameWorld`, managers).

---

## 4. Ciclo de vida — boot

```
main()
  ├── g_resources.init()
  ├── g_app.init(args)          # SDL, GL, dispatcher, window
  ├── g_client.init(args)       # g_map, g_game, g_things.init()
  ├── g_lua.safeRunScript("init.lua")
  │     ├── g_modules.discoverModules()
  │     ├── load corelib → gamelib → client_* → game_*
  │     └── client_entergame (tela login)
  └── g_app.run()               # Loop até quit
        ├── worker thread: poll + build DrawQueues
        └── render thread: execute DrawQueues + swap
```

### Shutdown

```
g_app.deinit() → g_client.terminate() → g_app.terminate()
  → g_map.terminate(), g_sprites.unload(), g_things.terminate()
```

---

## 5. Ciclo de vida — sessão de jogo

```
Login (Lua: g_game.loginWorld)
  ├── ProtocolGame::login → RSA + XTEA
  ├── resetGameStates(), g_map.clean()
  ├── m_localPlayer = new LocalPlayer
  └── parseMessage loop (Volume 2)

Primeiro opcode pós-login
  └── processGameStart() → Lua onGameStart → game_interface monta HUD

Disconnect
  └── processDisconnect() → onGameEnd → limpa mapa/player
```

---

## 6. Threads e dispatchers

```
┌─────────────────────────────────────────────────────────┐
│ Main / Render thread                                     │
│  g_graphicsDispatcher.poll()                             │
│  DrawQueue execution (OpenGL)                            │
│  g_clock.update()                                        │
└─────────────────────────────────────────────────────────┘
         ▲ mutex (DrawQueue swap)
┌─────────────────────────────────────────────────────────┐
│ Worker / Dispatcher thread                               │
│  g_dispatcher.poll() — eventos agendados               │
│  Protocol callbacks → parse → g_game/g_map             │
│  UI render → build DrawQueue                             │
│  Creature walk updates (scheduleEvent 20ms)            │
└─────────────────────────────────────────────────────────┘
         ▲
┌─────────────────────────────────────────────────────────┐
│ Async thread pool (g_asyncDispatcher)                    │
│  Map::findPathAsync                                      │
│  Minimap threadGetTile                                   │
└─────────────────────────────────────────────────────────┘
```

### Por que `g_dispatcher`?

Tudo que mexe em estado do jogo deve rodar na thread do dispatcher — protocolo agenda callbacks com `addEvent` para evitar race com render.

**Godot:** `_process` / signals na main thread — equivalente natural.

---

## 7. Dependências entre subsistemas

```
                    ┌─────────────┐
                    │  ProtocolGame│
                    └──────┬──────┘
                           │ parse → mutate
              ┌────────────┼────────────┐
              ▼            ▼            ▼
          ┌───────┐   ┌────────┐   ┌──────────┐
          │ g_game│◄─►│ g_map  │   │ g_things │
          └───┬───┘   └───┬────┘   └────┬─────┘
              │           │              │
              │     ┌─────┴─────┐        │
              │     ▼           ▼        ▼
              │  MapView    Tile/Creature  SpriteManager
              │     │           │              │
              ▼     ▼           ▼              ▼
          LocalPlayer      Lua modules    DrawQueue → GPU
              │
              ▼
          g_ui (HUD widgets)
```

**Fronteira C++/Lua:**
- C++: bytes, estado, render, pathfinding
- Lua: UI layout, input routing, config, features por versão

---

## 8. Onde termina C++ e começa Lua

| Operação | Camada |
|---|---|
| Parse opcode | C++ `protocolgameparse.cpp` |
| Atualizar HP/mana | C++ → `callLuaField` |
| Desenhar barra HP | Lua module ou C++ `drawInformation` |
| Clique no mapa | Lua `uigamemap.lua` → C++ `autoWalk` |
| Calcular path | C++ `findPathAsync` |
| Habilitar feature 860 | Lua `features.lua` |

---

## 9. Configuração deste fork (8.60)

**Arquivo:** `client/init.lua`

| Constante | Valor | Efeito |
|---|---|---|
| `APP_VERSION` | 860 | Protocolo TFS 8.60 |
| `CLASSIC_MAP_*` | tile 40px, zoom 11 | Classic view |
| `Servers` | 127.0.0.1:7171:860 | Login local |

---

## 10. Módulos Lua — inventário

**Total:** ~65 módulos em `client/modules/`

| Grupo | Exemplos |
|---|---|
| `client_*` (15) | entergame, options, styles, terminal |
| `game_*` (45) | interface, inventory, battle, bot, shop |
| libs | corelib, gamelib |

Prioridade de port Godot: `game_interface`, `game_walking`, `game_inventory`, `game_containers`, `game_console`, `game_features`.

---

## 11. OTC → Godot — arquitetura alvo

| OTC | Godot |
|---|---|
| Singletons `g_*` | Autoloads + managers em `GameWorld` |
| `g_dispatcher` events | `call_deferred` / signals |
| `g_modules` | Scenes + autoload scripts |
| `init.lua` boot | `project.godot` main scene |
| Worker DrawQueue | RenderingServer nativo |
| Lua UI | `.tscn` + GDScript |

---

## 12. Referências

- **Volume 2** — ProtocolGame detalhado
- **Volume 3** — render threads
- **Volume 5** — módulos Lua
- `plano.md` §2–§3 — metodologia
