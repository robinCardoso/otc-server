class_name CreatureWalker
extends RefCounted

# Constantes TFS 8.60 (protocol_version < 981)
const SPEED_A := 857.36
const SPEED_B := 261.29
const SPEED_C := -4795.01
const TILE_SIZE := 32
const DIAGONAL_FACTOR := 1.5

static func calc_step_duration(speed: int, ground_speed: int, server_beat: int, is_diagonal: bool) -> int:
	if speed < 1:
		return 0
	
	var step_speed: float = maxf(1.0, floor(SPEED_A * log(speed / 2.0 + SPEED_B) + SPEED_C + 0.5))
	var interval := int(floor(1000.0 * ground_speed / step_speed))
	
	# Arredondar para cima no múltiplo do beat (50ms)
	interval = int(ceil(float(interval) / float(server_beat))) * server_beat
	
	if is_diagonal:
		interval = int(interval * DIAGONAL_FACTOR)
		
	return max(interval, server_beat)

static func get_walk_offset(creature: Dictionary) -> Vector2:
	if not creature.get("is_walking", false):
		return Vector2.ZERO
		
	var elapsed: int = Time.get_ticks_msec() - int(creature.get("walk_start_ms", 0))
	var step_duration_ms: int = creature.get("step_duration_ms", 1)
	
	if elapsed >= step_duration_ms:
		return Vector2.ZERO
		
	# progress linear
	var progress: float = float(elapsed) / float(step_duration_ms)
	var pixels: float = progress * float(TILE_SIZE)
	
	return _direction_to_offset(creature.get("walk_direction", 2), pixels)

static func _direction_to_offset(dir: int, pixels: float) -> Vector2:
	match dir:
		0: return Vector2(0, -pixels)           # Norte
		1: return Vector2(pixels, 0)            # Leste
		2: return Vector2(0, pixels)            # Sul
		3: return Vector2(-pixels, 0)           # Oeste
		4: return Vector2(pixels, -pixels)      # Nordeste (NE)
		5: return Vector2(pixels, pixels)       # Sudeste (SE)
		6: return Vector2(-pixels, pixels)      # Sudoeste (SO)
		7: return Vector2(-pixels, -pixels)     # Noroeste (NO)
	return Vector2.ZERO

static func get_anim_phase(creature: Dictionary, total_phases: int) -> int:
	if not creature.get("is_walking", false) or total_phases <= 1:
		return 0
	return creature.get("walk_anim_phase", 0)

static func update_walk(creature: Dictionary) -> void:
	if not creature.get("is_walking", false):
		return
		
	var elapsed: int = Time.get_ticks_msec() - int(creature.get("walk_start_ms", 0))
	var step_duration_ms: int = maxi(int(creature.get("step_duration_ms", 1)), 1)
	
	var pixels_walked: int = mini(
		int(float(elapsed) * float(TILE_SIZE) / float(step_duration_ms)),
		TILE_SIZE
	)
	var current_walked: int = creature.get("walked_pixels", 0)
	creature["walked_pixels"] = max(current_walked, pixels_walked)
	
	_update_anim_phase(creature, elapsed)
	
	if elapsed >= step_duration_ms:
		_terminate_walk(creature)

static func _update_anim_phase(creature: Dictionary, elapsed: int) -> void:
	# O ideal seria puxar do ThingType, mas vamos assumir 3 frames para criaturas (fase 0, 1 e 2).
	# A fase 0 é parado. Sobram 2 fases (1 e 2) para a caminhada (foot_phases = 2).
	var foot_phases: int = 2
	
	var step_duration_ms: int = int(creature.get("step_duration_ms", 1))
	var foot_delay: int = maxi(
		int(ceil(float(step_duration_ms + 20) / float(foot_phases))),
		20
	)
	var now: int = Time.get_ticks_msec()
	
	var walked_pixels: int = creature.get("walked_pixels", 0)
	var foot_last_step_ms: int = creature.get("foot_last_step_ms", creature.get("walk_start_ms", 0))
	
	if walked_pixels < TILE_SIZE and now >= foot_last_step_ms + foot_delay:
		var foot_step: int = creature.get("foot_step", 0) + 1
		creature["foot_step"] = foot_step
		creature["walk_anim_phase"] = 1 + (foot_step % foot_phases)
		creature["foot_last_step_ms"] = foot_last_step_ms + foot_delay

static func _terminate_walk(creature: Dictionary) -> void:
	creature["is_walking"] = false
	creature["walked_pixels"] = 0
	creature["walk_anim_phase"] = 0
	creature["foot_step"] = 0

static func cancel_walk(creature: Dictionary, direction: int) -> void:
	creature["is_walking"] = false
	creature["walked_pixels"] = 0
	creature["walk_anim_phase"] = 0
	creature["foot_step"] = 0
	creature["direction"] = direction
