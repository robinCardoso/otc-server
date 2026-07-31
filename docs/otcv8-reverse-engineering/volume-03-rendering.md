# Volume 3 — Rendering

> **Status:** 🟡 Em progresso — pipeline DrawQueue, MapView e light documentados
> **Fonte primária:** `mapview.cpp`, `framework/graphics/drawqueue.cpp`, `lightview.cpp`, `graphicalapplication.cpp`

---

## 1. Visão geral

No OTCv8 o termo "DrawPool" da documentação antiga corresponde a **`DrawQueue`** (`framework/graphics/drawqueue.h`). O rendering é **deferred**: UI constrói filas de draw calls numa thread; outra thread executa OpenGL.

```
Thread worker (dispatcher)                Thread render (main)
─────────────────────────                ─────────────────────
g_ui.render(MapBackgroundPane)
  → MapView::drawMapBackground
  → tiles enqueue DrawQueueItems    →    toDrawMapQueue->draw()
                                              ↓
g_ui.render(MapForegroundPane)              FBO mapa → tela
  → criaturas info, light, textos   →    toDrawMapForegroundQueue->draw()
g_ui.render(ForegroundPane)           →    toDrawQueue->draw()
```

### Por que duas threads?

Separar construção da fila (CPU, Lua, pathfinding de UI) da execução GL evita stutter quando o mapa tem muitos tiles. Mutex troca `shared_ptr<DrawQueue>` entre threads (`graphicalapplication.cpp:149`).

| OTC | Godot | Status |
|---|---|---|
| `DrawQueue` (ex-DrawPool) | `CanvasItem._draw()` / layers | ⬜ |
| Thread worker + render | Godot render thread nativo | ✅ nativo |
| `g_drawQueue` global | — | N/A |

---

## 2. Pipeline do mapa — `MapView`

### 2.1 Ordem de desenho por floor

**Arquivo:** `mapview.cpp:110` — `drawMapBackground()`

```
Para cada floor z (de baixo para cima, com fading):
  drawFloor(z):
    1. Light: setFieldBrightness em grounds opacos
    2. Ground (chão)
    3. Bottom (items embaixo)
    4. Crosshair (se tile marcado)
    5. Creatures (no tile)
    6. Top (items em cima)
  Missiles do floor
```

**Foreground** (`drawMapForeground`, linha 226):

```
1. Informação de criaturas (nomes, barras) — spectators range
2. LightView::draw() — multiply blend sobre o mapa
3. StaticText / AnimatedText (com limite adaptive)
4. Tile texts
5. Health bars on top (opcional)
6. Tile widgets
```

### 2.2 Cache de tiles visíveis

`updateVisibleTilesCache()` — preenche `m_cachedVisibleTiles[floor]` iterando diagonais. Só tiles com `isDrawable()` entram.

**Dimensões:**

| Variável | Default | Uso |
|---|---|---|
| `m_visibleDimension` | 15×11 | Viewport na tela |
| `m_drawDimension` | visible + 3 | Margem anti-corte |
| `m_optimizedSize` | drawDim × 32 | Resolução FBO interno |

### 2.3 Framebuffer do mapa

```cpp
g_drawQueue->setFrameBuffer(rect, m_optimizedSize, srcRect);
// ... enqueue tiles ...
// No render thread:
m_mapFramebuffer->bind();
toDrawMapQueue->draw(DRAW_ALL);
m_mapFramebuffer->draw(destRect, srcRect);  // blit com shader opcional
```

**Por que FBO?** Permite aplicar shader pós-processo no mapa (ex.: scaling, colorização) sem redesenhar tiles.

### 2.4 Câmera e walk offset

`calcFramebufferSource()` — se seguindo criatura em walk, soma `getWalkOffset(inNextFrame)` ao `drawOffset` para scroll suave pixel-a-pixel.

| OTC | Godot | Status |
|---|---|---|
| `MapView::drawMapBackground` | `MapView.gd` | ✅ básico |
| Ordem ground→bottom→creatures→top | — | ⚠️ |
| FBO interno | `SubViewport` | ⬜ |
| Walk offset na câmera | — | ⬜ |
| Floor fading | — | ⬜ |

---

## 3. DrawQueue — batching e cache

**Arquivos:** `drawqueue.h`, `drawqueue.cpp`, `drawcache.cpp`

### 3.1 Tipos de item

| Classe | Uso |
|---|---|
| `DrawQueueItemTexturedRect` | Sprite/tile (maioria) |
| `DrawQueueItemOutfit` | Outfit com colorização RGB |
| `DrawQueueItemOutfitWithShader` | Outfit + shader |
| `DrawQueueItemText` | Texto bitmap |
| `DrawQueueItemFilledRect` | Retângulos sólidos |
| `LightView` | Item especial — draw no final |

### 3.2 Batching via DrawCache

```cpp
if (!m_queue[i]->cache()) {      // tenta acumular no batch
    g_drawCache.draw();           // flush batch anterior
    m_queue[i]->draw();           // draw individual
}
if (g_drawCache.getSize() >= HALF_MAX_SIZE)
    g_drawCache.draw();
```

**`cache()` retorna true** quando textura + shader + estado são compatíveis — acumula vértices em `g_drawCache` para um único `glDrawArrays`.

### 3.3 Conditions (estado GL)

| Condition | Efeito |
|---|---|
| `DrawQueueConditionClip` | `glScissor` |
| `DrawQueueConditionRotation` | Rotação em torno de ponto |
| `DrawQueueConditionMark` | Marca itens para highlight |

### 3.4 Atlas integration

`DrawQueueItemTexturedRect::cache()` usa `g_atlas.cache(hash, size)` — sprites repetidos vão para atlas 4096² em vez de textura individual.

| OTC | Godot | Status |
|---|---|---|
| DrawCache batching | MultiMesh / batch nativo | ⬜ |
| Conditions clip/opacity | `CanvasItem.clip_children` | ⬜ |
| `correctOutfit()` scaling | — | ⬜ |

---

## 4. Light rendering

**Arquivos:** `lightview.cpp`, `lightview.h`

### 4.1 Por que reescrito?

Light antigo do OTClient era por-sprite. OTCv8 acumula fontes de luz durante o draw dos tiles e calcula **mapa de luz por tile** numa passagem CPU.

### 4.2 Algoritmo

```
1. Durante drawFloor: addLight(pos, color, intensity) por item/criatura com light
2. setFieldBrightness em tiles com ground opaco (bloqueia luz de baixo)
3. LightView::draw():
   Para cada pixel do mapa de luz (1 px por tile 32×32):
     cor = globalLight
     para cada light após tile.start:
       distance = sqrt(dx²+dy²) / spriteSize
       intensity = (-distance + light.intensity) * 0.2
       cor = max(cor, lightColor * intensity)
   glTexImage2D → texture RGBA
   Painter::CompositionMode_Multiply sobre o mapa
```

### 4.3 Ambient light

```cpp
if (cameraPosition.z <= SEA_FLOOR)
    ambientLight = g_map.getLight();  // luz global do servidor
m_minimumAmbientLight = 0.05f (com GameForceLight)
```

| OTC | Godot | Status |
|---|---|---|
| `LightView` CPU lightmap | Shader 2D / `CanvasModulate` | ⬜ |
| Multiply blend | `BLEND_MODE_MUL` | ⬜ |
| Ground blocking light | — | ⬜ |
| `addLight` por thing | — | ⬜ |

---

## 5. Adaptive rendering

**Arquivo:** `adaptiverenderer.cpp`

Monitora FPS (janela 5 s) e ajusta `m_speed` (1–4):

| Speed | effectsLimit | creaturesLimit | textsLimit | mapRenderInterval |
|---|---|---|---|---|
| 1 (melhor) | 20 | 20 | 1000 | 0 ms |
| 2 | 10 | 10 | 50 | 10 ms |
| 3 | 7 | 7 | 30 | 20 ms |
| 4 (pior) | 2 | 3 | 5 | 100 ms |

**Gatilhos:** FPS abaixo do alvo → speed-- (mais agressivo); FPS acima → speed++.

**Usado em:** `mapview.cpp` — limita static/animated texts desenhados; `allowFading()` desabilita floor fade em speed > 2.

| OTC | Godot | Status |
|---|---|---|
| `AdaptiveRenderer` | `Engine.max_fps` + LOD manual | ⬜ |
| textsLimit | — | ⬜ |

---

## 6. Painter e shaders

**Arquivo:** `framework/graphics/painter.cpp`

- `g_painter` — estado OpenGL (matriz projeção, cor, shader, blend mode)
- `ShaderManager` — shaders de outfit, mapa, scaling
- Map FBO pode usar shader com `setCenter` / `setOffset` para efeitos

**Limitação C++:** gerenciamento manual de estado GL. Godot abstrai via `RenderingServer`.

---

## 7. Ordem global de render (GraphicalApplication)

```
1. DRAW_BEFORE_MAP  — UI atrás do mapa
2. MapBackground FBO
3. MapForeground    — light, textos, barras
4. DRAW_AFTER_MAP   — UI na frente (inventário, chat)
```

Panes definidos em `Fw::MapBackgroundPane`, `MapForegroundPane`, `ForegroundPane` (`uimap.cpp`).

---

## 8. Limitação C++ vs regra de negócio

| Aspecto | Limitação C++ | Regra relevante Godot |
|---|---|---|
| Light CPU O(n×lights) | Aceitável em 15×11; não escala | Usar shader com falloff por tile |
| DrawQueue manual | Verboso | `_draw()` + z-index por layer |
| Thread split | Mutex + double buffer | Godot já separa logic/render |
| FBO 4096 atlas | VRAM fixa | `Texture2D` + atlas opcional |

---

## 9. Gaps Godot

| Gap | Impacto |
|---|---|
| Light multiply pass | Mapa sem atmosfera noturna |
| Ordem de layers por tile | Items sobrepostos errados |
| Walk offset na câmera | Mapa "salta" entre tiles |
| Adaptive text limits | FPS cai em áreas com muito spam |
| Outfit shader layers | Cores de outfit incorretas |

---

## 10. Referências

- **Volume 4** — `getWalkOffset`, walking tile
- **Volume 7** — `ThingType::draw`, atlas, sprites 32×32
- `client/src/framework/core/graphicalapplication.cpp:149` — loop render
