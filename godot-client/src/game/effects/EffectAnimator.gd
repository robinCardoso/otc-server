class_name EffectAnimator
extends RefCounted

## Constantes do OTClient (extraídas diretamente do fonte)
const EFFECT_TICKS_PER_FRAME := 75       # effect.h:34
const ANIMATED_TEXT_DURATION := 1000     # const.h:42
const MISSILE_DURATION_FACTOR := 150.0   # missile.cpp:79
const TILE_SIZE := 32

# Tabela de direção de mísseis (missile.cpp:36-64)
# dir → [x_pattern, y_pattern]
const MISSILE_DIRECTION_PATTERNS := {
	0: [0, 0],  # NW
	1: [1, 0],  # N
	2: [2, 0],  # NE
	3: [2, 1],  # E
	4: [2, 2],  # SE
	5: [1, 2],  # S
	6: [0, 2],  # SW
	7: [0, 1],  # W
	8: [1, 1],  # Center
}

# ---------------------------------------------------------------------------
# EFEITOS MÁGICOS (Opcode 0x83)
# ---------------------------------------------------------------------------

## Retorna a phase atual do efeito ou -1 se expirou.
static func get_effect_phase(effect: Dictionary, total_phases: int) -> int:
	if total_phases <= 0:
		return -1
	var elapsed: int = Time.get_ticks_msec() - int(effect.get("start_ms", 0))
	var phase := int(elapsed / EFFECT_TICKS_PER_FRAME)
	if phase >= total_phases:
		return -1
	return phase

## Retorna os pattern_x/y do efeito com base na posição do tile.
static func get_effect_patterns(effect: Dictionary, thing_pattern_x: int, thing_pattern_y: int) -> Vector2i:
	var tile_pos: Vector3i = effect.get("tile_pos", Vector3i.ZERO)
	var px := tile_pos.x % maxi(1, thing_pattern_x)
	if px < 0:
		px += thing_pattern_x
	var py := tile_pos.y % maxi(1, thing_pattern_y)
	if py < 0:
		py += thing_pattern_y
	return Vector2i(px, py)

# ---------------------------------------------------------------------------
# MÍSSEIS (Opcode 0x85)
# ---------------------------------------------------------------------------

## Duração real: 150ms * sqrt(dx² + dy²) onde dx,dy em tiles.
static func calc_missile_duration(from_pos: Vector3i, to_pos: Vector3i) -> int:
	var dx := float(to_pos.x - from_pos.x)
	var dy := float(to_pos.y - from_pos.y)
	var dist := sqrt(dx * dx + dy * dy)
	return maxi(int(MISSILE_DURATION_FACTOR * dist), 1)

## Converte delta de posição para enum de direção (0=NW … 8=Center).
static func calc_missile_direction(from_pos: Vector3i, to_pos: Vector3i) -> int:
	var dx := to_pos.x - from_pos.x
	var dy := to_pos.y - from_pos.y
	if dx == 0 and dy == 0: return 8   # Center
	if dx < 0 and dy < 0:  return 0   # NW
	if dx == 0 and dy < 0: return 1   # N
	if dx > 0 and dy < 0:  return 2   # NE
	if dx > 0 and dy == 0: return 3   # E
	if dx > 0 and dy > 0:  return 4   # SE
	if dx == 0 and dy > 0: return 5   # S
	if dx < 0 and dy > 0:  return 6   # SW
	if dx < 0 and dy == 0: return 7   # W
	# Diagonais parciais — escolher o eixo dominante
	if abs(dx) >= abs(dy):
		return 3 if dx > 0 else 7
	return 5 if dy > 0 else 1

## Retorna [x_pattern, y_pattern] para texturas do míssil.
static func get_missile_sprite_pattern(direction: int) -> Array:
	return MISSILE_DIRECTION_PATTERNS.get(direction, [1, 1])

## Retorna fração [0..1] do percurso atual do míssil.
static func get_missile_progress(missile: Dictionary) -> float:
	var elapsed: float = float(Time.get_ticks_msec() - int(missile.get("start_ms", 0)))
	var duration: float = float(maxi(int(missile.get("duration_ms", 1)), 1))
	return minf(elapsed / duration, 1.0)

## Retorna true se o míssil ainda está voando.
static func is_missile_alive(missile: Dictionary) -> bool:
	var elapsed: int = Time.get_ticks_msec() - int(missile.get("start_ms", 0))
	return elapsed < missile.get("duration_ms", 0)

## Retorna o offset de tela do míssil em pixels (interpolação linear).
## O míssil parte do centro do tile de origem e vai ao centro do tile de destino.
static func get_missile_screen_offset(missile: Dictionary) -> Vector2:
	var progress := get_missile_progress(missile)
	var delta: Vector2 = missile.get("delta_pixels", Vector2.ZERO)
	return delta * progress

# ---------------------------------------------------------------------------
# TEXTO ANIMADO (Opcode 0x84)
# ---------------------------------------------------------------------------

## Retorna estado do texto animado: { y_offset, alpha, alive }.
## Movimenta 48px para cima em 1000ms. Fade nos últimos ~17% (1000/1.2 ≈ 833ms).
static func get_animated_text_state(text_entry: Dictionary) -> Dictionary:
	var elapsed: float = float(Time.get_ticks_msec() - int(text_entry.get("start_ms", 0)))
	var tf := float(ANIMATED_TEXT_DURATION)

	if elapsed >= tf:
		return {"y_offset": 0.0, "alpha": 0.0, "alive": false}

	var y_offset := (-48.0 * elapsed) / tf
	var alpha := 1.0
	var fade_start := tf / 1.2  # ~833ms
	if elapsed > fade_start:
		alpha = 1.0 - (elapsed - fade_start) / (tf - fade_start)
	alpha = clampf(alpha, 0.0, 1.0)

	return {"y_offset": y_offset, "alpha": alpha, "alive": true}
