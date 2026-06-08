# Viewport 25×20 (TFS + OTCv8)

Documentação do mapa visível enviado pelo servidor e consumido pelo cliente **otc-server**.

**Visão completa (Classic view + UI):** [`../../client/docs/VIEWPORT-CLASSIC-VIEW.md`](../../client/docs/VIEWPORT-CLASSIC-VIEW.md)

---

## Estado atual (2026-06)

| Camada | Valor | Onde |
|--------|-------|------|
| Mapa na rede | **25 × 20** tiles | `protocolgame.cpp` |
| Aware range cliente | left=**12**, top=**9**, right=**12**, bottom=**10** | `client/map.cpp`, `game_viewport/viewport.lua` |
| Classic view | Só zoom no cliente | Não altera pacotes do servidor |

Substitui o viewport **18×14** vanilla (8+9+1 × 6+7+1) usado antes neste fork.

---

## Constantes em `map.h` (fonte única)

```cpp
static constexpr int32_t clientMapWidth = 25;
static constexpr int32_t clientMapHeight = 20;
static constexpr int32_t clientMapLeft = 12;
static constexpr int32_t clientMapRight = 12;
static constexpr int32_t clientMapTop = 9;
static constexpr int32_t clientMapBottom = 10;

static constexpr int32_t maxClientViewportX = clientMapLeft;   // 12
static constexpr int32_t maxClientViewportY = clientMapTop;    // 9
static constexpr int32_t maxViewportX = clientMapRight + 1;    // 13
static constexpr int32_t maxViewportY = clientMapBottom + 1;   // 11
```

`static_assert` garante `left + right + 1 == width` e idem para altura.

Esses limites propagam para `combat.cpp`, `monster.cpp`, `creature.h` via `Map::maxClientViewport*` / `Map::maxViewport*` sem editar cada arquivo.

---

## `protocolgame.cpp` — pontos alterados

| Bloco | Função |
|-------|--------|
| `sendMapDescription` | Mapa inicial login (opcode **0x64**) |
| `sendMoveCreature` | Faixas norte/sul/leste/oeste (0x65–0x68) |
| `MoveUpCreature` / `MoveDownCreature` | Pisos e resync lateral |
| `ProtocolGame::canSee` | Filtro de visibilidade — **obrigatório** alinhar com `GetMapDescription` |

### Offsets de movimento (referência)

| Direção | Antes (18×14) | Agora (25×20) |
|---------|---------------|---------------|
| Mapa completo | x−8, y−6, 18×14 | x−`clientMapLeft`, y−`clientMapTop`, 25×20 |
| Norte | y−6, faixa 18×1 | y−`clientMapTop`, 25×1 |
| Sul | y+7, faixa 18×1 | y+`clientMapBottom`, 25×1 |
| Leste | x+9, faixa 1×14 | x+`clientMapRight`, 1×20 |
| Oeste | x−8, faixa 1×14 | x−`clientMapLeft`, 1×20 |

### `canSee`

```cpp
x >= px - Map::clientMapLeft + offsetz  &&  x <= px + Map::clientMapRight + offsetz
y >= py - Map::clientMapTop + offsetz   &&  y <= py + Map::clientMapBottom + offsetz
```

Se só mudar `GetMapDescription` sem `canSee`, criaturas/tiles nas bordas somem ao andar.

---

## `game.cpp`

Yell usa espectadores no retângulo do mapa cliente:

```cpp
map.getSpectators(spectators, *pos, true, false,
    Map::clientMapWidth, Map::clientMapWidth,
    Map::clientMapHeight, Map::clientMapHeight);
```

---

## Lua — opcode 206 (não usado no login)

| Arquivo | Papel |
|---------|--------|
| `data/lib/otcv8_viewport.lua` | `Otcv8Viewport.handleMode` → `player:setMapViewportMode` (**binding ausente** no C++ deste fork) |
| `data/creaturescripts/scripts/otcv8_viewport.lua` | Handler extended opcode **206** |

O cliente **não envia** opcode 206 no login. O TFS envia **sempre** 25×20 após rebuild. Motivo: segundo `0x64` / dessync de criaturas em experimentos anteriores (ver `otserv_860/docs/VIEWPORT-MODULE.md` histórico).

---

## Classic view (lado cliente)

A opção **Classic view** no OTC **não** pede ao servidor outro tamanho de mapa.

| Classic view | Servidor | Cliente |
|--------------|----------|---------|
| ON | 25×20 (igual) | Zoom 15×11 + letterbox cinza |
| OFF | 25×20 (igual) | `fitZoomToScreen` — usa largura dos 25 tiles |

Detalhes: [`client/docs/VIEWPORT-CLASSIC-VIEW.md`](../../client/docs/VIEWPORT-CLASSIC-VIEW.md).

---

## Build

```powershell
$env:PATH = "C:\msys64\mingw64\bin;C:\msys64\usr\bin;" + $env:PATH
cd C:\8.6\otserv_860\otc-server\server\build_win
cmake --build . -j8
Copy-Item tfs.exe ..\tfs.exe -Force
```

Ver [`BUILD.md`](BUILD.md). Cliente: `client/scripts/build-client.ps1`.

**Relog** após deploy de novo `tfs.exe`.

---

## Anti-regressão

| Não fazer | Motivo |
|-----------|--------|
| Cliente 29×20 + servidor 18×14 | Opcode 0x64 parse corrompido → `invalid id 61823` |
| `changeMapAwareRange(31,21)` no 860 | TFS não implementa opcode 66 neste fork |
| Opcode 206 no login | Dessync histórico |
| Mudar só `protocolgame.cpp` sem `canSee` | Bordas invisíveis |

---

## Teste

1. Rebuild `tfs.exe` + `otclient_gl.exe`
2. Reiniciar ambos; **relogar**
3. Andar em todas as direções nas bordas do mapa visível
4. Subir/descer andares (escadas, buracos)
5. Classic ON/OFF no cliente — layout estável; OFF sem faixas pretas

---

## Changelog

| Data | Mudança |
|------|---------|
| 2026-06 | Viewport 18×14 → **25×20**; Classic view refatorado (só zoom cliente) |
