# Volume 7 — Assets (SPR/DAT)

> **Status:** 🟡 Em progresso — pipeline SPR/DAT e atlas documentados
> **Fonte primária:** `spritemanager.cpp`, `thingtypemanager.cpp`, `thingtype.cpp`, `outfit.cpp`, `framework/graphics/atlas.cpp`

---

## 1. Pipeline geral

```
Tibia.spr                          Tibia.dat
    │                                  │
    ▼                                  ▼
SpriteManager                    ThingTypeManager
getSpriteImage(id)               ThingType::unserialize()
    │                                  │
    ▼                                  ▼
Image 32×32 RGBA                 flags, sprites[], animation
    │                                  │
    └──────────┬───────────────────────┘
               ▼
         Atlas (4096² FBO)  ←── hash por sprite composto
               ▼
         Texture GPU  ←── DrawQueueItemTexturedRect
```

### Por que separar SPR e DAT?

- **SPR** — pixels brutos (RLE), sem semântica
- **DAT** — metadados: walkability, layers, animação, market, light
- **OTB** (servidor) — server IDs; cliente usa client IDs do DAT

---

## 2. Sprite Manager — `.spr`

**Arquivo:** `client/src/client/spritemanager.cpp`

### 2.1 Formatos suportados

| Formato | Detecção | Sprite size |
|---|---|---|
| Classic `.spr` | arquivo existe | 32×32 |
| Encrypted OTV8 | signature `OTV8` | 32×32, buffer criptografado |
| HD `.cwm` | `m_isHdMod=true` | variável, PNG packed |

### 2.2 Header classic

```
u32 signature
u16/u32 spriteCount   (u32 se GameSpritesU32)
[spriteCount × u32 offset]   ← lazy read
```

Sprites **não** são carregados todos na memória — `getSpriteImageCasual()` faz seek por offset.

### 2.3 Decodificação RLE

**Por sprite** (após color key 3 bytes ignorados):

```
loop até pixelDataSize:
  u16 transparentPixels   ← pula N pixels (alpha=0)
  u16 coloredPixels
  para cada colored:
    se GameSpritesAlphaChannel: RGBA (4 bytes)
    senão: RGB + alpha=0xFF
```

**Regra 8.60:** `GameSpritesAlphaChannel` **não** ativo por default em `features.lua` — sprites opacos com alpha forçado 0xFF.

### 2.4 Formato OTV8 encrypted

```
u32 "OTV8"
u32 signature
u32 count
para cada sprite:
  u16 bufferSize
  u8[bufferSize] criptografado (bdecrypt com signature+id)
  u8 hasAlpha
  RLE interno (transparent/colored chunks)
```

| OTC | Godot | Status |
|---|---|---|
| `SpriteManager::loadSpr` | `SpriteReader.gd` | ✅ |
| RLE decode | `SpriteReader` | ✅ |
| Lazy load por offset | — | ⚠️ |
| OTV8 encrypted | — | ⬜ |

---

## 3. Thing Type Manager — `.dat`

**Arquivo:** `thingtypemanager.cpp:170`

### 3.1 Load

```
u32 datSignature
para cada category (item, creature, effect, missile):
  u16 count + 1
  para cada id:
    ThingType::unserialize(id, category, stream)
```

**IDs:** items começam em **100**; demais categorias em 1.

### 3.2 Atributos relevantes ao protocolo (8.60)

**Arquivo:** `thingtype.cpp:136` — loop até `ThingLastAttr`

| Flag DAT | Impacto gameplay/protocolo |
|---|---|
| `DatGround` / `DatGroundBorder` | `isGround()`, minimap color |
| `DatStackable` | `getItem()` lê count (u8 vs u16) |
| `DatChargeable` | charges no item |
| `DatFluidContainer` | fluid type no `getItem()` |
| `DatBlockProjectile` | `isSightClear` |
| `DatNotWalkable` / `DatNotPathable` | pathfinding, walk |
| `DatPickupable` | interação |
| `DatLight` | intensity + color → `LightView` |
| `DatElevation` | draw elevation stacking |
| `DatDisplacement` | offset sprite |
| `DatCloth` | slot de outfit |
| `DatMarket` | market category |

Ver Volume 2 §9 para mapeamento `getItem()` byte-a-byte.

### 3.3 Eviction de texturas

```cpp
// thingtypemanager.cpp:77 — a cada 1s, 100 types
if (type->getLastUsage() + 60 < now)
    type->unload();
```

**Limitação C++:** scan circular manual. Godot usa refcount em `Texture2D`.

| OTC | Godot | Status |
|---|---|---|
| `ThingTypeManager::loadDat` | `DatReader.gd` | ✅ |
| Flags walkability | `ThingType` flags | ⚠️ |
| Eviction 60s | ResourceLoader cache | ✅ nativo |

---

## 4. ThingType → GPU

### 4.1 Composição de sprite

`ThingType` guarda `m_spritesIndex[]` — índices no SPR.  
`ThingType::draw()` escolhe layer, pattern (x/y/z), animationPhase.

**Patterns:**

| Pattern | Significado |
|---|---|
| `xPattern` | direção (0–3) ou variant |
| `yPattern` | addon layer (outfit) |
| `zPattern` | mount layer (0=sem, 1=com mount) |
| `animationPhase` | frame de animação |

### 4.2 Animator

`Animator` / `IdleAnimator` — phases com timing async ou random.  
Items: `isAnimateAlways()` cicla frames por tempo.

---

## 5. Outfit — composição de layers

**Arquivo:** `outfit.cpp:44`

### 5.1 Ordem de desenho

```
1. Aura (back) — se feature
2. Mount (zPattern=1)
3. Wings (South/East primeiro, North/West depois)
4. Body layers (yPattern 0=base, 1=addon1, 2=addon2)
5. Aura (front)
```

### 5.2 Colorização (layer 1)

```cpp
uint32_t colors = m_head + (m_body << 8) + (m_legs << 16) + (m_feet << 24);
DrawQueueItemOutfit(..., colors, ...)
```

Shader/painter aplica paleta por canal RGB do sprite template.

### 5.3 Mount e displacement

Mount usa `ThingCategoryCreature` separado (`m_mount` id).  
`getDisplacement()` retorna displacement do mount se montado.

| OTC | Godot | Status |
|---|---|---|
| `Outfit::draw()` layers | `ThingSpriteFactory` outfit | ⚠️ |
| Colorização head/body/legs/feet | — | ⬜ |
| Mount zPattern | — | ⬜ |
| Wings bone offset | — | ⬜ |

---

## 6. Atlas de texturas

**Arquivo:** `framework/graphics/atlas.cpp`

### 6.1 Configuração

```
m_size = min(4096, maxTextureSize)
m_atlas[0] — sprites (4096²)
m_atlas[1] — fonts (2048² ou 4096²)
```

### 6.2 Cache

```cpp
Point Atlas::cache(uint64_t hash, const Size& size, bool& draw)
```

- Hash único por combinação sprite+transform
- Bin packing em grid 2048 dentro do atlas
- `m_doReset` — recria atlas quando cheio

**Por que atlas?** Reduz trocas de textura GL — crítico com milhares de sprites 32×32.

| OTC | Godot | Status |
|---|---|---|
| `Atlas` 4096² | AtlasTexture / manual | ⬜ |
| Hash cache | Dictionary texture cache | ⚠️ parcial |

---

## 7. Texture Manager (framework)

**Arquivo:** `framework/graphics/texturemanager.cpp`

Cache de `Texture` por path — usado para UI, fonts, imagens PNG. Separado do atlas de sprites de jogo.

---

## 8. Fluxo boot de assets

```
init.lua → modules/game_things/things.lua
  g_sprites.loadSpr('/data/things/860/Tibia')
  g_things.loadDat('/data/things/860/Tibia')
  g_things.loadOtml(...)  // overrides opcionais
```

Signature SPR/DAT enviada no login (`ProtocolLogin`) para validação servidor.

---

## 9. Limitação C++ vs regra de negócio

| Aspecto | C++ | Regra Godot |
|---|---|---|
| RLE decode | Manual byte-a-byte | Portar idêntico — bugs visuais se diferente |
| Atlas eviction | Reset total | Godot pode usar LRU por sprite |
| ThingType lazy | unload após 60s | Manter flags sempre; texture pode cache |
| HD .cwm | PNG unpack | Não necessário para 8.60 clássico |

---

## 10. Gaps Godot

| Gap | Impacto |
|---|---|
| Atlas GPU compartilhado | Muitas draw calls / memória |
| Outfit colorização 4 canais | Cores erradas em players |
| `zPattern` mount | Sprite sem mount |
| OTV8 encrypted SPR | Não carrega assets encrypted |
| Flags DAT → protocolo | Desync em `getItem()` (Volume 2) |

---

## 11. Referências

- **Volume 2** §9 — `getItem()` e flags DAT
- **Volume 3** — `ThingType::draw` → DrawQueue
- **Volume 4** — `spriteSize`, walk animation phases
- `client/modules/game_things/things.lua`
