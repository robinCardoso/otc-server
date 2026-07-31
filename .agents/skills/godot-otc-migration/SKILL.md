---
name: godot-otc-migration
description: >
  Arquitetura e processo de migração do OTClient v8 para Godot 4.7+.
  Define como portar comportamento, protocolo e sistemas do OTC sem copiar
  código C++ linha a linha. Use junto com otclient-protocol-implementer (bytes)
  e godot47-otserver-client (assets e padrões GDScript).
---

# SKILL: OTCv8 Migration Architect

> Esta skill define **como pensar** a migração OTC → Godot.
> Para **bytes de protocolo**, use `.agents/skills/otclient-protocol-implementer/SKILL.md`.
> Para **.spr/.dat e padrões GDScript**, use `.agents/skills/godot47-otserver-client/SKILL.md`.

---

## 1. Missão

Portar **arquitetura, comportamento e protocolo** — não código C++.

Toda decisão deve responder, nesta ordem:

1. **Como isso funciona no OTCv8?** (fonte: `client/src/client/`)
2. **Qual é a melhor implementação em Godot 4.7+?**

### Objetivo final

O cliente Godot deve substituir o OTCv8 completamente:

| Critério | Exigência |
|---|---|
| Servidor | Conectar no mesmo TFS/Canary |
| Protocolo | Interpretar os mesmos pacotes |
| Comportamento | Produzir o mesmo resultado observável |
| Renderização | Exibir mapa, criaturas e UI corretamente |
| Recursos | Suportar os mesmos sistemas de gameplay |

A implementação interna muda; a **experiência e compatibilidade** permanecem.

### O que preservar sempre

- Compatibilidade com TFS/Canary e OTClient
- Performance e escalabilidade
- Organização modular e testabilidade

---

## 2. Princípio central

| Copiar (fidelidade) | Adaptar (Godot) |
|---|---|
| Comportamento | Renderização |
| Protocolo e estruturas de dados | Gerenciamento de memória |
| Fluxo de estados e eventos | Cenas e recursos |
| Semântica de opcodes | UI (Control/Theme) |
| Regras de mapa/things | Threads e I/O |

**Nunca** converter linha a linha, copiar SDL/OpenGL, portar ponteiros/`delete` ou criar wrappers que imitam classes C++ do OTC.

**Sempre** perguntar: *existe solução nativa da Godot?* Se sim, usar.

---

## 3. Escopo de responsabilidade

Sistemas que esta migração cobre:

| Domínio | Componentes OTC | Prioridade |
|---|---|---|
| **Rede** | ProtocolGame, ProtocolLogin, InputMessage, OutputMessage | Fase 1 |
| **Mapa** | Map, Tile, MapView, floor change, skip, scroll | Fase 1 |
| **Things** | ThingType, Thing, Item, Outfit | Fase 1–2 |
| **Criaturas** | Creature, LocalPlayer, animação, movimento | Fase 2 |
| **Inventário** | Inventory, Container, Item | Fase 2 |
| **Efeitos** | Effects, Missiles, Light | Fase 3 |
| **Render** | DrawPool, Painter, FrameBuffer, Textures | Fase 2–3 |
| **UI** | UIWidget, OTUI, Modules | Fase 3–4 |
| **Extras** | Bot, Lua, Shaders | Fase 4+ |

---

## 4. Processo de migração (por sistema)

Antes de implementar qualquer módulo, responder:

| # | Pergunta |
|---|---|
| 1 | Como funciona no OTCv8? (arquivo/função de referência) |
| 2 | Qual a responsabilidade única deste módulo? |
| 3 | Quais dependências upstream/downstream? |
| 4 | Existe equivalente nativo na Godot? |
| 5 | Vale reutilizar código Godot existente no projeto? |
| 6 | Vale redesenhar em vez de espelhar estrutura OTC? |
| 7 | Qual a arquitetura final (camadas, arquivos, signals)? |

### Ordem de migração (nunca tudo de uma vez)

```
1. Network          → NetworkManager, XTEA, RSA
2. Protocol         → GameOpcodeReader, ThingReader, MapParser
3. Map              → MapState, tiles, skip, scroll
4. Things           → DatReader, ThingSpriteFactory
5. Creatures        → CreatureWalker, registro de criaturas
6. Renderer         → MapView, draw por tile
7. UI               → GameHUD, inventário, containers
8. Gameplay         → walking, combate, spells
9. Effects          → EffectAnimator, missiles, texto animado
10. Polimento       → performance, edge cases, módulos extras
```

### Checklist por módulo migrado

- [ ] Compatível com protocolo 8.60 (sem desync)
- [ ] Compatível com servidor deste repositório
- [ ] Arquitetura idiomática Godot (sem wrappers C++)
- [ ] Performance aceitável (sem Node2D por sprite)
- [ ] Modular e testável
- [ ] Documentado (comentário de mapeamento OTC → Godot)

---

## 5. Mapeamento OTC → Godot

### Rede e protocolo

| OTC (C++) | Godot (GDScript) | Notas |
|---|---|---|
| `ProtocolGame` | `GameProtocol` + `OpcodeDispatcher` | Dispatcher de opcodes |
| `ProtocolLogin` | `Protocol.gd` | Login RSA + char list |
| `InputMessage` | `StreamPeerBuffer` + `ProtocolReader` | Leitura tipada U8/U16/U32/string |
| `OutputMessage` | `StreamPeerBuffer.put_*` | Envio de pacotes |
| `parseMapDescription` | `MapParser.parse_full_map()` | Ver protocol-implementer |

> **Protocolo:** toda leitura de bytes segue `otclient-protocol-implementer/SKILL.md`.
> Fonte da verdade: `client/src/client/protocolgameparse.cpp`.

### Estado do jogo

| OTC (C++) | Godot (GDScript) | Notas |
|---|---|---|
| `Map` | `GameWorld` → `MapManager` → `MapState` | Facade + estado |
| `Tile` | `MapTile` | `items[]` + `creatures[]` |
| `Thing` / `Item` | `Dictionary` em `ThingReader` | Dados puros, sem Node |
| `Creature` | `CreatureManager` + `creature_index` | Movimento, outfit, health |
| `LocalPlayer` | `PlayerController` | Posição, walk, beat |
| `Container` | `ContainerManager` | Modelo separado da UI |
| `Inventory` | `InventoryManager` | Slots 1–10 |
| `Effect` / `Missile` | `EffectManager` | Efeitos voláteis globais e por tile |

### Renderização

| OTC (C++) | Godot | Abordagem |
|---|---|---|
| `MapView` | `MapView.gd` | Câmera + draw de tiles visíveis |
| `DrawPool` | `RenderingServer` / `CanvasItem` | **Não** recriar DrawPool |
| `Painter` | `_draw()` / MultiMesh | Batching nativo |
| `FrameBuffer` | `Viewport` / `SubViewport` | Quando necessário |
| `TextureManager` | `ThingSpriteFactory` + cache `Texture2D` | AtlasTexture quando possível |

### UI

| OTC | Godot |
|---|---|
| `UIWidget` | `Control` |
| OTUI (`.otui`) | `.tscn` + `Theme` |
| Styles inline | `Theme` resources |
| Modules Lua | Cenas/scripts GDScript ou Resources |

---

## 6. Regras por domínio

### 6.1 Protocolo

- **Nunca** modificar semântica de opcode, ordem de bytes ou tamanho de campos.
- **Nunca** mascarar desync com heurísticas (`_scan_skip_marker`, retry de count, resync no tile).
- Desync = 1 byte lido a mais ou a menos → corrigir o `read` específico.
- Ver anti-padrões e mapeamento detalhado em `otclient-protocol-implementer/SKILL.md`.

### 6.2 Mapa

Preservar sem alteração:

- Floor change (`0xBE`/`0xBF`)
- Skip markers (`0xFF00`)
- Tile stack e thing stack (máx. 10 things/tile no TFS 8.60)
- Creature move (`0x6D`)
- Map scroll (`0x65`–`0x68`)
- Viewport 25×20 (`GameBiggerMapCache`)

### 6.3 Things, criaturas e itens

```
ThingData (Dictionary)  →  Renderer (MapView/Factory)  →  Entity visual (opcional)
```

| Tipo | Contém | Não contém |
|---|---|---|
| **Thing/Item** | id, count, flags do .dat | UI, lógica de gameplay |
| **Creature** | id, outfit, speed, direction | Animação, rede, render |
| **Container** | modelo (itens, capacidade) | Visual, handlers de rede |

Separar sempre: **dados · lógica · animação · renderização · rede**.

### 6.4 UI

Migrar **conceito**, não implementação OTUI.

- Layouts → `.tscn`
- Estilos → `Theme`
- Eventos → `signal` Godot
- Estado → Autoloads (`GlobalNetwork`) ou modelos (`MapState`)

### 6.5 Lua e módulos OTC

Antes de portar script Lua, perguntar:

| Alternativa Godot | Quando usar |
|---|---|
| `Resource` (.tres) | Dados estáticos (spells, items custom) |
| `ConfigFile` / JSON | Configuração editável |
| GDScript autoload | Lógica global (equivalente a `g_game`) |
| Plugin / addon | Sistema extensível |
| Manter Lua (plugin) | Último recurso — evitar recriar runtime Lua |

### 6.6 Performance e memória

| OTC | Godot |
|---|---|
| Gerenciamento manual de texturas | `Texture2D` + cache por referência |
| DrawPool batching manual | `RenderingServer`, `MultiMesh`, `CanvasItem` |
| Ponteiros e ownership | GC da engine — sem `delete`/smart pointers |
| Threads manuais | `WorkerThreadPool`, `Thread`, `ResourceLoader` |
| Shaders GLSL crus | Godot Shader Language (`.gdshader`) |

Antes de portar otimização do OTC, perguntar: *o gargalo existe na Godot? A engine já resolve?*

---

## 7. Matriz de decisão

Para cada componente, classificar a estratégia:

| Componente | Copiar comportamento | Adaptar | Reescrever | Nativo Godot |
|---|---|---|---|---|
| ProtocolGame / MapParser | ✔ | ✔ | ✖ | ✖ |
| ThingReader / DatReader | ✔ | ✔ | ✖ | ✖ |
| DrawPool | ✖ | ✖ | ✔ | ✔ |
| Painter | ✖ | ✖ | ✔ | ✔ |
| TextureManager | ✔ | ✔ | ✖ | ✔ |
| UIWidget / OTUI | ✖ | ✔ | ✔ | ✔ |
| Lua modules | ✖ | ✔ | ✔ | ✔ |
| Bot | ✖ | ✔ | ✔ | Parcial |

**Sempre justificar** qualquer desvio do comportamento observável do OTC.

### Árvore de decisão rápida

```
É leitura de bytes de rede?
  → Sim: espelhar protocolgameparse.cpp (protocol-implementer)
  → Não ↓

É renderização?
  → Sim: usar CanvasItem/RenderingServer, não portar DrawPool
  → Não ↓

É UI?
  → Sim: Control + Theme, não portar OTUI
  → Não ↓

É dado de jogo (item, tile, creature)?
  → Sim: Dictionary/Resource puro, sem Node
  → Não ↓

Adaptar ou reescrever com recurso nativo Godot
```

---

## 8. Testes

Após migrar cada módulo, validar **antes** de avançar:

| Teste | Como verificar |
|---|---|
| Mesmo pacote | Comparar bytes consumidos com OTC (debug log) |
| Mesmo mapa | Tile count, posição do player, sem desync |
| Mesmo comportamento | Walking, scroll, floor change, inventário |
| Sem regressão | `erro.md` sem `thing id 0`, `buffer curto`, opcodes falsos |

Nunca seguir para o próximo módulo com desync de protocolo ativo.

---

## 9. Relatório de migração (quando solicitado)

Ao analisar um sistema para migração, produzir:

1. **Sistema analisado** — nome e arquivos OTC de referência
2. **Funcionamento OTCv8** — responsabilidade e fluxo
3. **Problemas da implementação original** — limitações C++ relevantes
4. **Oportunidades Godot** — recursos nativos aplicáveis
5. **Arquitetura proposta** — camadas, arquivos, signals
6. **Fluxo de dados** — rede → parser → estado → render/UI
7. **Dependências** — o que precisa existir antes
8. **Impactos e riscos** — breaking changes, performance
9. **Compatibilidade** — protocolo, servidor, OTC
10. **Plano de migração** — passos ordenados
11. **Testes necessários** — critérios de aceite

---

## 10. Skills relacionadas

| Skill | Quando usar |
|---|---|
| `otclient-protocol-implementer` | Qualquer opcode, parse de mapa/things/criaturas |
| `godot47-otserver-client` | .spr, .dat, estrutura de pastas, GDScript 4.7+ |
| Esta skill (`godot-otc-migration`) | Decisões de arquitetura, ordem de migração, OTC→Godot |

---

## 12. Arquitetura de arquivos (implementada)

```
godot-client/src/
├── autoload/
│   └── GlobalNetwork.gd          # Sessão: rede + session_world
├── core/network/
│   ├── GameProtocol.gd           # Handshake + loop de opcodes
│   ├── OpcodeDispatcher.gd       # Facade → GameOpcodeReader
│   ├── GameOpcodeReader.gd       # Parser de opcodes (bytes)
│   └── ProtocolReader.gd         # Helpers U8/U16/U32/string
├── world/                        # Camada World (SKILL §3)
│   ├── GameWorld.gd              # Coordenador central
│   ├── MapManager.gd             # Tiles, things no mapa
│   ├── CreatureManager.gd        # Movimento, outfit, health
│   ├── EffectManager.gd          # 0x83/0x84/0x85
│   ├── InventoryManager.gd       # 0x78/0x79
│   └── ContainerManager.gd         # 0x6E–0x72
├── gameplay/
│   └── PlayerController.gd       # Player local, can_walk, beat
├── game/
│   ├── creature/CreatureWalker.gd
│   ├── effects/EffectAnimator.gd
│   └── map/                      # MapState, MapParser, MapView
├── io/                           # DatReader, SpriteReader, ThingReader
└── ui/                           # Login, HUD, containers
```

Fluxo de dados:

```
Rede → GameProtocol → OpcodeDispatcher → GameOpcodeReader
                                              ↓
                                         GameWorld
                                    ┌─────────┼─────────┐
                                    map  creatures  effects
                                    └─────────┬─────────┘
                                              ↓
                                         MapView (render)
```


O OTCv8 representa anos de evolução de um cliente Tibia. O objetivo **não** é reproduzir sua tecnologia (C++, SDL, DrawPool), mas preservar:

- Experiência do jogador
- Compatibilidade de protocolo
- Comportamento observável

Utilizando a arquitetura moderna da Godot 4.

> **Nunca copie uma limitação do OTCv8** se a Godot oferecer solução mais robusta,
> desde que o comportamento observado pelo jogador permaneça equivalente.
