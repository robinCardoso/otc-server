# Plano de Implementação — Efeitos, Mísseis e Texto Animado

> [!NOTE]
> Plano completamente reescrito com base na análise direta de `effect.cpp`, `missile.cpp`, `animatedtext.cpp`, `tile.cpp` e `mapview.cpp` do OTClient. Todos os valores e fórmulas são extraídos da fonte original.

---

## Análise das Lacunas do Plano Anterior

O plano anterior estava incompleto em **5 pontos críticos**:

1. **Texto Animado era ausente** — O opcode `0x84` (AnimatedText) estava completamente fora do plano, sendo um dos efeitos mais visíveis do jogo (números de dano, cura, XP).
2. **Estrutura de dados incorreta** — O plano propunha armazenar efeitos/mísseis globalmente no `MapState`, mas o OTClient os armazena **por Tile** (effects) e **por andar** (missiles). A abordagem correta preserva a Z-order e a culling de andares.
3. **Ordem de renderização errada** — O plano não especificava que Efeitos são desenhados *depois* das criaturas e *antes* dos itens on-top, conforme `tile.cpp:drawTop()`.
4. **Mísseis sem fórmula de duração** — A duração de um míssil é `150ms * sqrt(distância_em_pixels)`, não era mencionada.
5. **Opcodes relacionados a criaturas ignorados** — Os opcodes `0x8C` (CreatureHealth), `0x8D` (CreatureOutfit), `0x8E` (CreatureSpeed) chegam frequentemente após o login e precisam atualizar dados das criaturas já no mapa. O plano não tocava neles.

---

## Constantes Reais do OTClient (Extraídas do Fonte)

| Constante | Valor | Origem |
|---|---|---|
| `EFFECT_TICKS_PER_FRAME` | `75ms` | `effect.h:34` |
| `ANIMATED_TEXT_DURATION` | `1000ms` | `const.h:42` |
| `MISSILE_DURATION_FACTOR` | `150ms * √distância` | `missile.cpp:79` |
| `TILE_SIZE` | `32px` | `spritemanager` |

---

## Opcodes a Implementar

| Opcode | Nome | Estrutura do Pacote |
|---|---|---|
| `0x83` | Magic Effect | `position(x,y,z)` + `effect_id(u8)` |
| `0x84` | Animated Text | `position(x,y,z)` + `color(u8)` + `text(string)` |
| `0x85` | Distance Missile | `from_pos(x,y,z)` + `to_pos(x,y,z)` + `missile_id(u8)` |
| `0x8C` | Creature Health | `creature_id(u32)` + `health_percent(u8)` |
| `0x8D` | Creature Outfit | `creature_id(u32)` + `outfit(look_type + cores)` |
| `0x8E` | Creature Speed | `creature_id(u32)` + `speed(u16)` |

> [!IMPORTANT]
> `0x8C`, `0x8D` e `0x8E` NÃO são efeitos visuais, mas são frequentemente recebidos junto aos pacotes de efeitos (ex: monstro toma dano → `0x83` + `0x8C`). É imprescindível implementá-los agora para que as criaturas reflitam estado correto após combate.

---

## Proposta de Mudanças nos Arquivos

---

### Componente 1 — Estrutura de Dados

#### [MODIFY] [MapTile.gd](file:///c:/8.6/otserv_860/otc-server/godot-client/src/game/map/MapTile.gd)

Adicionar `effects: Array[Dictionary]` ao tile. **Os efeitos pertencem ao tile**, assim como no OTClient.

```gdscript
var items: Array[Dictionary] = []
var creatures: Array[Dictionary] = []
var effects: Array[Dictionary] = []   # [NEW] Magic Effects do tile
```

#### [MODIFY] [MapState.gd](file:///c:/8.6/otserv_860/otc-server/godot-client/src/game/map/MapState.gd)

Adicionar apenas **Mísseis** e **Textos Animados** como lista global (não pertencem a um tile fixo — viajam/flutuam).

```gdscript
var active_missiles: Array[Dictionary] = []      # [NEW]
var active_animated_texts: Array[Dictionary] = [] # [NEW]
```

---

### Componente 2 — Rede (Parsing dos Opcodes)

#### [MODIFY] [GameOpcodeReader.gd](file:///c:/8.6/otserv_860/otc-server/godot-client/src/core/network/GameOpcodeReader.gd)

Substituir os blocos `0x83`, `0x84`, `0x85` de "skip" para parsers reais:

**Opcode `0x83` — Magic Effect:**
```gdscript
# Ler: position + effect_id(u8)
# Criar entrada: { effect_id, tile_pos, start_ms, phase }
# Adicionar em: tile.effects.append(entry)
```

**Opcode `0x84` — Animated Text:**
```gdscript
# Ler: position + color(u8) + text(string)  
# Criar entrada: { text, color, tile_pos, start_ms }
# Adicionar em: map_state.active_animated_texts.append(entry)
```

**Opcode `0x85` — Distance Missile:**
```gdscript
# Ler: from_pos + to_pos + missile_id(u8)
# Calcular: delta_x = to.x - from.x, delta_y = to.y - from.y
# Calcular: duration = 150 * sqrt(delta_x^2 + delta_y^2) [em tiles]
# Calcular: direction (NW=0, N=1, NE=2, E=3, SE=4, S=5, SW=6, W=7, center=8)
# Adicionar em: map_state.active_missiles.append(entry)
```

**Opcode `0x8C` — Creature Health:**
```gdscript
# Ler: creature_id(u32) + health_percent(u8)
# Buscar criatura no map_state e atualizar health_percent
```

**Opcode `0x8D` — Creature Outfit:**
```gdscript
# Ler: creature_id(u32) + outfit completo (look_type + cores)
# Buscar criatura no map_state e atualizar look_*
```

**Opcode `0x8E` — Creature Speed:**
```gdscript
# Ler: creature_id(u32) + speed(u16)
# Buscar criatura no map_state e atualizar speed
```

> [!WARNING]
> A busca de criatura por ID (já implementada em `_find_creature_by_id`) **percorre todos os tiles**. Para `0x8C`/`0x8D`/`0x8E` que chegam frequentemente, precisamos de uma **lookup table por ID** no `MapState` para O(1). Detalhe na Seção de Performance abaixo.

---

### Componente 3 — Fábrica de Sprites

#### [MODIFY] [ThingSpriteFactory.gd](file:///c:/8.6/otserv_860/otc-server/godot-client/src/game/map/ThingSpriteFactory.gd)

```gdscript
# [NEW] Obter textura de efeito mágico com animação e padrão de tile
static func get_effect_texture(effect_id: int, anim_phase: int, tile_x: int, tile_y: int) -> Texture2D

# [NEW] Obter textura de míssil com direção (xPattern, yPattern vindos da tabela)
static func get_missile_texture(missile_id: int, dir_x: int, dir_y: int) -> Texture2D

# [NEW] Retornar número total de fases de animação de um efeito
static func get_effect_animation_phases(effect_id: int) -> int
```

A **tabela de direção dos mísseis** (extraída de `missile.cpp:36-64`):

| Direção | x_pattern | y_pattern |
|---|---|---|
| NW (0) | 0 | 0 |
| N (1) | 1 | 0 |
| NE (2) | 2 | 0 |
| E (3) | 2 | 1 |
| SE (4) | 2 | 2 |
| S (5) | 1 | 2 |
| SW (6) | 0 | 2 |
| W (7) | 0 | 1 |
| Center (8) | 1 | 1 |

---

### Componente 4 — Motor de Animação (novo arquivo)

#### [NEW] `src/game/effects/EffectAnimator.gd`

Classe estática com funções matemáticas puras, seguindo o padrão do `CreatureWalker.gd`:

```gdscript
class_name EffectAnimator
extends RefCounted

const EFFECT_TICKS_PER_FRAME := 75       # effect.h:34
const ANIMATED_TEXT_DURATION := 1000     # const.h:42
const MISSILE_DURATION_FACTOR := 150.0   # missile.cpp:79
const TILE_SIZE := 32

# Retorna a phase atual de um efeito (ou -1 se expirado)
static func get_effect_phase(effect: Dictionary, total_phases: int) -> int

# Retorna o offset de tela de um míssil (posição interpolada)
static func get_missile_screen_offset(missile: Dictionary) -> Vector2

# Retorna a fração [0..1] do percurso de um míssil
static func get_missile_progress(missile: Dictionary) -> float

# Verifica se um míssil ainda está ativo
static func is_missile_alive(missile: Dictionary) -> bool

# Retorna o deslocamento Y e alpha do texto animado
static func get_animated_text_state(text_entry: Dictionary) -> Dictionary
    # retorna: { y_offset, alpha, alive }

# Fórmula real: 150 * sqrt(dx² + dy²) onde dx,dy em tiles
static func calc_missile_duration(from_pos: Vector3i, to_pos: Vector3i) -> int

# Converte delta de tile para enum de direção do míssil (0..8)
static func calc_missile_direction(from_pos: Vector3i, to_pos: Vector3i) -> int
```

---

### Componente 5 — Renderização

#### [MODIFY] [MapView.gd](file:///c:/8.6/otserv_860/otc-server/godot-client/src/game/map/MapView.gd)

**Ordem de renderização correta** (replicando `tile.cpp:drawTop()`):

```
[Ground] → [Bottom Items] → [Creatures] → [EFFECTS no tile] → [Top Items]
```

Depois de todos os tiles:
```
→ [Missiles por andar]
→ [Animated Texts]
```

**Funções a adicionar/modificar:**

1. **`_draw_tile_effects(tile, tile_pos, draw_elevation, camera_offset)`** — Itera `tile.effects`, chama `EffectAnimator.get_effect_phase()`. Remove automaticamente efeitos expirados (`phase == -1`).

2. **`_draw_all_missiles(camera_offset)`** — Itera `map_state.active_missiles`, chama `EffectAnimator.get_missile_screen_offset()`. Remove mísseis expirados. **Desenha apenas mísseis do andar visível** (`.z == camera_pos.z`).

3. **`_draw_animated_texts(camera_offset)`** — Itera `map_state.active_animated_texts`. Chama `EffectAnimator.get_animated_text_state()`. Usa `draw_string()` do Godot com a cor e alpha corretos. Remove textos expirados.

4. **`_process(delta)`** — Já verifica walking. Adicionar verificação de:
   - `map_state.active_missiles.size() > 0`
   - `map_state.active_animated_texts.size() > 0`
   - Qualquer tile na view com `effects.size() > 0`

---

### Componente 6 — Performance: Lookup Table de Criaturas

> [!CAUTION]
> **Problema crítico de performance:** `_find_creature_by_id()` atual percorre TODOS os tiles para cada opcode `0x8C`/`0x8D`/`0x8E`. Em um mapa cheio, isso é O(n*m) a cada frame com combate.

#### [MODIFY] [MapState.gd](file:///c:/8.6/otserv_860/otc-server/godot-client/src/game/map/MapState.gd)

```gdscript
# [NEW] Índice rápido: creature_id → creature Dictionary
var creature_index: Dictionary = {}  # { int_id: creature_dict }

# [NEW] Registrar ao adicionar criatura a um tile
func register_creature(creature: Dictionary) -> void:
    creature_index[creature["id"]] = creature

# [NEW] Buscar em O(1)
func find_creature_by_id(creature_id: int) -> Dictionary:
    return creature_index.get(creature_id, {})
```

O `MapParser.gd` e o `GameOpcodeReader.gd` devem chamar `register_creature()` ao inserir criaturas.

---

## Ordem de Implementação Recomendada

```
1. EffectAnimator.gd (matemática pura — sem deps)
2. MapTile.gd (campo effects)
3. MapState.gd (active_missiles, active_animated_texts, creature_index)
4. ThingSpriteFactory.gd (get_effect_texture, get_missile_texture)
5. GameOpcodeReader.gd (parsers 0x83, 0x84, 0x85, 0x8C, 0x8D, 0x8E)
6. MapView.gd (_draw_tile_effects, _draw_all_missiles, _draw_animated_texts)
```

---

## Verificação

### Testes visuais
1. **Effect:** Ativar magia `exori mas` (ou clicar com fire bomb). Deve aparecer a explosão animada no chão.
2. **Missile:** Atirar com um Paladin usando flecha, ou lançar uma runa. O projétil deve voar em linha reta entre tiles.
3. **Animated Text:** Tomar dano de qualquer fonte. O número em vermelho deve flutuar para cima e desaparecer após 1 segundo.
4. **Creature Health (0x8C):** Observar a barra de HP de um monstro sendo atacado. O percentual deve atualizar em tempo real.

### Testes de robustez
- Múltiplos efeitos simultâneos no mesmo tile (ex: campo de fogo multi-explosão) não devem travar.
- Mísseis viajando longas distâncias (5+ tiles) devem durar proporcionalmente mais tempo.
- Textos animados que chegam rápido (combo) devem empilhar verticalmente ou somar (como o OTClient faz para dano).
