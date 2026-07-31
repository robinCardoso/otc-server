# Volume 4 — Gameplay

> **Status:** 🟡 Em progresso — walking, pathfinding e mapa documentados para 8.60
> **Protocolo alvo:** TFS 8.60 (client version 860)
> **Fontes primárias:** `localplayer.cpp`, `creature.cpp`, `map.cpp`, `game.cpp`, `protocolgameparse.cpp`

---

## 1. Visão geral

O gameplay do OTCv8 separa **estado do mapa** (C++), **lógica de movimento** (C++ com hooks Lua) e **input/UI** (módulos Lua). Para 8.60, `GameNewWalking` **não** está ativo — o servidor é autoridade total sobre posição; o cliente anima e envia intenções.

```
Input (Lua/C++)
      │
      ▼
Game::walk() / Game::autoWalk()
      │
      ├──► ProtocolGame::sendWalk* / sendAutoWalk  ──► Servidor TFS
      │
      ▼
parseCreatureMove (0x6D) ──► Map::addThing ──► Creature::onAppear ──► walk()
      │
      ▼
MapView (câmera segue getWalkOffset)
```

### Por que três camadas de walking?

| Camada | Motivo |
|---|---|
| `Game` | Valida ação, envia pacote, dispara eventos Lua (`onWalk`, `onAutoWalk`) |
| `LocalPlayer` | Regras específicas do jogador local: prewalk (protocolos novos), autowalk, cancel, lock |
| `Creature` | Animação pixel-a-pixel, duração do passo, walking tile, fases de pé |

**Regra de negócio (8.60):** sem `GameNewWalking`, **não há preWalk no autowalk** — enviar path inteiro e deixar o servidor mover passo a passo via `parseCreatureMove`.

---

## 2. Walking manual — `Game::walk()`

**Arquivo:** `client/src/client/game.cpp:684`

```
Tecla / Lua g_game.walk(dir)
      │
      ▼
canPerformGameAction()?
      │
      ▼ (8.60)
Verifica tile destino: blocksCreatureWalk()
      │
      ▼
g_lua: onWalk(direction, withPreWalk)
      │
      ▼
switch(direction) → sendWalkNorth/East/... (8 direções)
```

### Pacotes enviados (8.60)

| Direção | Opcode cliente |
|---|---|
| N/S/E/W | `ClientWalkNorth` etc. (`protocolgamesend.cpp`) |
| Diagonais | `ClientWalkNorthEast` etc. |

**Módulo Lua:** `modules/game_walking/walking.lua` — bind de teclas, smart walk, `lockWalk` após teleporte.

| OTC | Godot | Status |
|---|---|---|
| `Game::walk()` | `PlayerController` + input | ✅ |
| `sendWalk*` | `GameProtocol.send_walk()` | ✅ |
| `blocksCreatureWalk()` check | `PlayerController.can_walk()` | ⚠️ validar paridade |

---

## 3. Auto walk — clique no mapa

### 3.1 Fluxo completo

```
Clique mapa (uigamemap.lua / gameinterface.lua)
      │
      ▼
LocalPlayer::autoWalk(destination)
      │
      ▼
Map::findPathAsync(start, dest, callback)   ← thread async
      │
      ▼
Game::autoWalk(path, startPos)
      │
      ├── 8.60: m_protocolGame->sendAutoWalk(dirs)   (path até 127 dirs)
      └── new walking: sendNewWalk + preWalk opcional
```

**Arquivos:**
- `localplayer.cpp:328` — `autoWalk()`
- `map.cpp:1233` — `findPathAsync()` → `newFindPath()` em worker thread
- `game.cpp:635` — `autoWalk()` → `sendAutoWalk`
- `protocolgamesend.cpp:217` — pacote `0x64` com lista de direções codificadas 1–8

### Por que pathfinding async?

Calcular caminho pode visitar até **50.000 nós** (`newFindPath`). Rodar na thread principal travaria UI; `g_asyncDispatcher` calcula e retorna via `g_dispatcher.addEvent`.

### Retry e falha

| Situação | Comportamento OTC |
|---|---|
| Path não encontrado | `onAutoWalkFail(status)` → Lua (`textmessage.lua`) |
| Servidor cancela mid-path | `parseCancelWalk` (0xB5) → `LocalPlayer::cancelNewWalk` |
| Destino parcial (obstáculo) | `m_lastAutoWalkPosition` + retry até 3× (200–400 ms) |

| OTC | Godot | Status |
|---|---|---|
| `LocalPlayer::autoWalk()` | — | ⬜ |
| `Map::findPathAsync()` | — | ⬜ |
| `Game::autoWalk()` + `sendAutoWalk` | parcial em `PlayerController` | ⚠️ |
| Retry 3× | — | ⬜ |
| `onAutoWalkFail` | — | ⬜ |

---

## 4. Sincronização servidor → cliente

### 4.1 `parseCreatureMove` (opcode servidor move thing)

**Arquivo:** `protocolgameparse.cpp:1250`

```cpp
ThingPtr thing = getMappedThing(msg);
Position newPos = getPosition(msg);
// 8.60: sem stepDuration extra
g_map.removeThing(thing);
creature->allowAppearWalk(stepDuration);  // stepDuration=0 no 8.60
g_map.addThing(thing, newPos, -1);
```

**Cadeia até animação:**

```
tile->addThing(creature)
  → creature->setPosition(newPos)
  → creature->onAppear()
      → se oldPos adjacente (1,1): walk(oldPos, newPos)   // virtual → LocalPlayer::walk
```

### 4.2 `LocalPlayer::walk()` — 8.60

**Arquivo:** `localplayer.cpp:164`

| Ramo | Quando | Ação |
|---|---|---|
| Predição visual inválida | `newPos != m_visualPredictedDest` | `stopWalk()` |
| PreWalk ativo | `GameNewWalking` (não 8.60) | reconcilia fila `m_preWalking` |
| Server walk | default 8.60 | `m_serverWalking=true` → `Creature::walk()` |

### 4.3 Cancel walk — `0xB5`

**Arquivo:** `protocolgameparse.cpp:2380`

```
parseCancelWalk → Game::processWalkCancel(dir)
  → LocalPlayer::cancelWalk(dir)   // 8.60: cancelNewWalk
      → limpa m_preWalking, stopWalk(), retryAutoWalk?, onCancelWalk Lua
```

| OTC | Godot | Status |
|---|---|---|
| `parseCreatureMove` → `onAppear` → `walk` | `CreatureManager` move + walker | ⚠️ |
| `parseCancelWalk` | — | ⬜ |
| `allowAppearWalk` + step duration | N/A no 8.60 | — |

---

## 5. Animação de movimento — `Creature`

### 5.1 Interpolação pixel-a-pixel

**Arquivo:** `creature.cpp:728`

```
walkTicksPerPixel = getStepDuration(true) / spriteSize(32)
totalPixelsWalked = walkTimer.elapsed / walkTicksPerPixel
updateWalkAnimation(totalPixelsWalked)
updateWalkOffset(pixels)
updateWalkingTile()   ← criatura pode estar em tile vizinho durante walk
```

**8.60 — offset linear (sem smoothstep):**

```cpp
// getWalkOffset() — progress linear, ancora em m_lastStepFromPosition
progress = elapsed / stepDuration
pixels = progress * spriteSize
```

**Por que `getPrewalkingPosition()` retorna tile de origem no 8.60?**

No 8.60, `m_position` já é atualizado para o tile destino quando o pacote chega; o desenho ancora no tile de origem (`m_lastStepFromPosition`) para a animação deslizar corretamente.

### 5.2 Duração do passo — `getStepDuration()`

**Arquivo:** `creature.cpp:1003`

```
interval = 1000 * groundSpeed / calculatedStepSpeed
  → arredonda para múltiplo de serverBeat (50 ms no 8.60)
  → ×1.5 se direção diagonal
  → mínimo = serverBeat
```

| Parâmetro | Fonte |
|---|---|
| `groundSpeed` | tile destino (`Tile::getGroundSpeed()`, default 150) |
| `speed` | criatura (`Creature::setSpeed`) |
| Fórmula 8.60 | logarítmica `kSpeedA/B/C` + ceil ao beat |

### 5.3 Fases de animação (pés)

**Arquivo:** `creature.cpp:587`

- `footDelay = stepDuration / footAnimPhases`
- Alterna `m_walkAnimationPhase` enquanto `totalPixelsWalked < 32`
- Outfit: layers via `yPattern` (addons 1 e 2)

### 5.4 Walking tile

Durante o walk, a criatura é desenhada no tile onde o **canto inferior direito** do sprite virtual cai — pode ser tile adjacente. Lista `m_walkingCreatures` em `Tile`.

| OTC | Godot | Status |
|---|---|---|
| `Creature::walk()` + `updateWalk()` | `CreatureWalker.gd` | ✅ básico |
| `getStepDuration()` fórmula 8.60 | — | ⬜ |
| `getWalkOffset()` linear | — | ⚠️ |
| `updateWalkingTile()` | — | ⬜ |
| Fases de pé / outfit phase | — | ⬜ |

---

## 6. Predição visual (autowalk 8.60) — estado atual

Infraestrutura em `localplayer.cpp` para movimento suave **sem** preWalk:

| API | Propósito |
|---|---|
| `setAutoWalkPath(dirs)` | Guarda path enviado ao servidor |
| `tryVisualWalkStep(dir, fromPos)` | Inicia animação local sem alterar `m_preWalking` |
| `AUTO_WALK_PREDICT_PROGRESS = 0.85f` | Constante para predizer próximo sqm a 85% do passo |

**Gap identificado:** `AUTO_WALK_PREDICT_PROGRESS` e `tryVisualWalkStep` existem mas **não têm caller** no código C++ atual — predição visual ainda não está wired. Documentado em `client/docs/MAP-SMOOTH.md` como trabalho planejado.

| OTC | Godot | Status |
|---|---|---|
| `tryVisualWalkStep` | — | ⬜ (OTC incompleto) |
| Predição 85% do passo | — | ⬜ |

---

## 7. Pathfinding

### 7.1 Duas implementações

| Função | Uso | Algoritmo | Thread |
|---|---|---|---|
| `Map::findPath()` | Lua sync (`g_map.findPath`) | Dijkstra com heap (comentário diz A*) | Main |
| `Map::newFindPath()` | `findPathAsync` (autowalk UI) | Dijkstra + heurística | Async |

**Arquivo sync:** `map.cpp:852`  
**Arquivo async:** `map.cpp:1115`

### 7.2 Custo e flags

```
custo = custo_anterior + (groundSpeed * walkFactor) / 100
walkFactor = 1.0 (ortogonal) | 3.0 (diagonal)
```

**Flags** (`const.h:503`):

| Flag | Efeito |
|---|---|
| `PathFindAllowNotSeenTiles` | Usa minimap para tiles não vistos |
| `PathFindIgnoreCreatures` | Ignora criaturas no tile |
| `PathFindAllowNonPathable` | Ignora `isPathable()` |
| `PathFindAllowNonWalkable` | Ignora `isWalkable()` |

**8.60 extra:** em `findPath` e `newFindPath`, tiles com `blocksCreatureWalk()` são pulados (exceto goal).

### 7.3 `findPathAsync` — preparação de nós

Antes do async, coleta todos os tiles do floor visível em `visibleNodes` com custos de walkability — seed para o grafo sem reler mapa na thread.

### 7.4 Limites

| Limite | Valor |
|---|---|
| `maxComplexity` (sync) | parâmetro Lua (bots usam 7–100) |
| `newFindPath` | 50.000 expansões |
| Path autowalk 8.60 | máx. **127** direções (`game.cpp:362`) |

| OTC | Godot | Status |
|---|---|---|
| `Map::findPath()` | — | ⬜ |
| `Map::findPathAsync()` | — | ⬜ |
| Custo diagonal ×3 | — | ⬜ |
| Minimap fallback | — | ⬜ |

---

## 8. Mapa e visão

### 8.1 AwareRange (viewport servidor)

**Arquivo:** `map.cpp:826` — `resetAwareRange()`

```
left=12, right=12, top=9, bottom=10  →  25×20 tiles
```

Ativado com `GameBiggerMapCache` em `features.lua` (≥860).

**Por que importa:** TFS envia `0x64` full map nesse viewport. Godot deve usar os mesmos limites em `MapState` (ver Volume 2 §8).

### 8.2 MapView — dimensão visível vs desenho

**Arquivo:** `mapview.cpp:49`

| Constante | Valor default | Significado |
|---|---|---|
| `m_visibleDimension` | 15×11 | Tiles mostrados na tela (classic view) |
| `m_drawDimension` | visible + (3,3) | Margem para scroll suave |
| `m_optimizedSize` | drawDim × 32px | Tamanho do framebuffer interno |

Classic view (`game_interface/gameinterface.lua`): `setVisibleDimension(15, 11)` com zoom por tile px.

### 8.3 Cache de tiles visíveis

`updateVisibleTilesCache()` — itera diagonais do `drawDimension`, preenche `m_cachedVisibleTiles[z]`. Invalidado por `requestVisibleTilesCacheUpdate()` (movimento, prewalk, floor change).

### 8.4 Floor change

`parseFloorChangeUp/Down` — ajusta `centralPosition.z` e reenvia aware range ao servidor.

### 8.5 Limpeza de tiles unaware

`removeUnawareThings()` — remove criaturas, static texts e blocos de tiles fora do aware range. Com `GameBiggerMapCache`, margem de limpeza é 4× o range.

| OTC | Godot | Status |
|---|---|---|
| `AwareRange` 25×20 | `MapState` constants | ⚠️ |
| `MapView` 15×11 classic | `MapView.gd` | ⚠️ |
| `cachedVisibleTiles` | — | ⬜ |
| `removeUnawareThings` | — | ⬜ |

---

## 9. WalkMatrix (debug / new walking)

**Arquivo:** `walkmatrix.h`

Matriz 7×7 de prediction IDs ao redor do jogador — usada por `predictiveCancelWalk` em protocolos com `GameNewWalking`. No 8.60 é infraestrutura inerte (só debug).

---

## 10. Limitação C++ vs regra de negócio

| Aspecto | Limitação C++ | Regra de negócio (manter no Godot) |
|---|---|---|
| Pathfinding em thread | `g_asyncDispatcher` manual | Algoritmo e custos devem ser idênticos |
| Walk timer | `g_dispatcher.scheduleEvent` 20 ms | Duração = f(groundSpeed, speed, diagonal, beat) |
| PreWalk | Só com `GameNewWalking` | 8.60: servidor move, cliente anima em `onAppear` |
| Position update | Imediata no `setPosition` | Offset visual compensa até fim do passo |

---

## 11. Gaps que bloqueiam Godot

| Gap | Impacto | Prioridade |
|---|---|---|
| `findPathAsync` não portado | Clique no mapa sem desvio de mobs | Alta |
| `parseCancelWalk` / `cancelWalk` | Travamento visual após bloqueio | Alta |
| `getStepDuration` fórmula 8.60 | Velocidade errada vs servidor | Alta |
| `getWalkOffset` + walking tile | Sprite em tile errado durante walk | Média |
| Predição visual autowalk (OTC incompleto) | Micro-teleportes em lag | Média |
| `removeUnawareThings` | Memory leak de tiles longe do player | Baixa |

---

## 12. Referências cruzadas

- **Volume 2** — `parseCreatureMove`, `parseCancelWalk`, `parseMapDescription`, aware range
- **Volume 3** — `MapView` câmera segue `getWalkOffset`
- **Volume 7** — `spriteSize=32`, outfit layers para animação
- `client/docs/MAP-SMOOTH.md` — alterações locais de smooth walk
- `client/docs/CLIENT-CHANGES.md` — preWalk desabilitado no 8.60
