# Volume 6 — Performance

> **Status:** 🟡 Em progresso — caches, threads e adaptive rendering documentados
> **Fonte primária:** `thingtypemanager.cpp`, `atlas.cpp`, `drawqueue.cpp`, `adaptiverenderer.cpp`, `map.cpp`

---

## 1. Visão geral

O OTCv8 otimiza em cinco eixos: **texture atlas**, **draw batching**, **lazy asset load**, **thread offload** e **adaptive LOD**. Muitas otimizações são workarounds de OpenGL manual — Godot resolve várias nativamente.

---

## 2. Texture e sprite cache

### 2.1 Atlas GPU

**Arquivo:** `atlas.cpp`

| Parâmetro | Valor |
|---|---|
| Tamanho atlas sprites | 4096×4096 (ou max GPU) |
| Atlas fonts | 2048×2048 |
| Packing | Grid 2048 com free list |
| Eviction | Reset completo quando cheio (`m_doReset`) |

**Por que?** Sprites 32×32 individuais = milhares de bind texture. Atlas reduz para 1–2 binds por frame de mapa.

### 2.2 ThingType texture eviction

**Arquivo:** `thingtypemanager.cpp:77`

```
A cada 1 segundo: scan 100 ThingTypes
Se lastUsage + 60s < now → unload()
```

Scan circular por categoria — não bloqueia frame.

### 2.3 SpriteManager lazy load

SPR mantém file handle + offsets; `getSpriteImage(id)` decodifica sob demanda. OTV8 pré-carrega buffers criptografados na RAM.

| OTC | Godot | Status |
|---|---|---|
| Atlas 4096 | `AtlasTexture` / manual | ⬜ |
| ThingType unload 60s | ResourceLoader refcount | ✅ nativo |
| SPR lazy seek | `SpriteReader` on demand | ✅ |

---

## 3. Draw batching

**Arquivo:** `drawqueue.cpp:293`

```
DrawCache acumula vértices com mesma textura/shader
Flush quando: cache() falha | HALF_MAX_SIZE atingido | condition change
```

**Outfit batching:** `DrawQueueItemOutfit::cache()` — múltiplos outfits mesma textura base.

| OTC | Godot |
|---|---|
| DrawCache manual | MultiMesh / batch por material |
| Condition clip stack | `CanvasItem` clip |

---

## 4. Map cache

### 4.1 Visible tiles cache

`MapView::m_cachedVisibleTiles` — recalculado só quando `m_mustUpdateVisibleTilesCache`. Evita iterar todos os tiles do aware range a cada frame.

### 4.2 Tile blocks

`Map::m_tileBlocks[z][blockIndex]` — tiles agrupados em blocos para lookup O(1) por posição.

### 4.3 Unaware cleanup

`removeUnawareThings()` — com `GameBiggerMapCache`, margem 4× aware range antes de deletar tiles. Trade-off memória vs re-parse do servidor.

### 4.4 Minimap thread cache

`g_minimap.threadGetTile()` — leitura thread-safe para pathfinding async sem lock no mapa principal.

| OTC | Godot | Status |
|---|---|---|
| Visible tiles cache | Culling por viewport | ⬜ |
| Tile blocks | Dictionary por chunk | ⚠️ |
| removeUnawareThings | Unload chunks distantes | ⬜ |

---

## 5. Threading

| Thread | Trabalho |
|---|---|
| Dispatcher worker | UI build, protocol poll, walk timers |
| Render main | OpenGL draw, swap buffers |
| Async pool | `findPathAsync`, minimap reads |

**Sincronização DrawQueue:** `std::mutex` + double buffer de `shared_ptr<DrawQueue>`.

**Godot:** `WorkerThreadPool` para pathfinding; rendering já separado.

---

## 6. Adaptive rendering (LOD)

**Arquivo:** `adaptiverenderer.cpp`

Monitora frames/5s e ajusta speed 1–4:

| Speed | Efeitos max | Criaturas info | Textos max | Map interval |
|---|---|---|---|---|
| 1 | 20 | 20 | 1000 | 0 ms |
| 2 | 10 | 10 | 50 | 10 ms |
| 3 | 7 | 7 | 30 | 20 ms |
| 4 | 2 | 3 | 5 | 100 ms |

Também: `allowFading()` false em speed > 2.

**Gatilho:** FPS abaixo de `maxFps * (4.0 - speed*0.3)` → degradar.

---

## 7. Object reuse

| Área | Técnica |
|---|---|
| `DrawQueue` items | `new` por frame, delete no destructor da queue |
| `SNode` pathfinding | Alocado por busca, delete após |
| `CoordsBuffer` | Reused em Painter |
| Static vectors em LightView | `buffer.resize()` reuse |

**Nota:** OTC não usa object pool generalizado — alocação por frame aceitável com pools pontuais.

---

## 8. O que Godot já resolve

| Otimização OTC | Godot nativo |
|---|---|
| Texture refcount manual | `Texture2D` + ResourceLoader |
| DrawCache GL batching | RenderingServer batching |
| Thread render split | Engine render thread |
| Font atlas | `FontFile` cache |
| FPS limiter | `Engine.max_fps` |

---

## 9. O que ainda vale portar

| Otimização | Motivo |
|---|---|
| Visible tile cache | Evitar iterar mapa inteiro |
| Pathfinding async | Não bloquear main thread |
| Adaptive text/effect limits | Áreas crowded |
| Unaware tile cleanup | Memória em sessões longas |
| Atlas para sprites 32×32 | Draw calls se usar CanvasItem puro |

---

## 10. Profiling OTC

Stats integrados: `STATS_MAIN`, `STATS_RENDER` em `graphicalapplication.cpp`.  
`g_graphs[]` — CPU frame time overlay com `debugRender`.

---

## 11. Gaps Godot

| Gap | Risco |
|---|---|
| Sem adaptive LOD | FPS em war zones |
| Pathfinding sync | Stutter no clique |
| Sem tile unload | RAM crescente |
| Sem atlas | GPU overhead |

---

## 12. Referências

- **Volume 3** — DrawCache, adaptive texts
- **Volume 4** — findPathAsync
- **Volume 7** — atlas, ThingType unload
