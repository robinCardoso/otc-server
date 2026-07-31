class_name TibiaPlayerController
extends RefCounted

const _AutoWalkScript := preload("res://src/gameplay/AutoWalk.gd")
const _PathfinderScript := preload("res://src/gameplay/Pathfinder.gd")

var _map = null
var _creatures = null
var auto_walk = null

var player_id: int = 0
var server_beat: int = 50

# Opcode 0xA0 — PlayerStats (TFS 8.60 / OTC parsePlayerStats)
var health: int = 0
var max_health: int = 0
var free_capacity: float = 0.0
var experience: int = 0
var level: int = 0
var level_percent: int = 0
var mana: int = 0
var max_mana: int = 0
var magic_level: int = 0
var magic_level_percent: int = 0
var soul: int = 0
var stamina: int = 0

func _init(map_manager, creature_manager) -> void:
	_map = map_manager
	_creatures = creature_manager
	auto_walk = _AutoWalkScript.new()

func bind_login(login_data: Dictionary) -> void:
	player_id = login_data.get("player_id", 0)
	server_beat = maxi(login_data.get("beat_duration", 50), 1)

func get_position() -> Vector3i:
	return _map.get_player_pos()

func can_walk() -> bool:
	return not _creatures.is_player_walking(player_id)

func build_move_context() -> Dictionary:
	return {
		"player_id": player_id,
		"server_beat": server_beat,
	}

func auto_walk_to(destination: Vector3i, flags: int = 0) -> bool:
	return auto_walk.start(_map.state, get_position(), destination, player_id, flags)

func stop_auto_walk() -> void:
	auto_walk.stop()

func on_creature_moved(creature: Dictionary) -> void:
	if creature.get("id", 0) != player_id:
		return
	if auto_walk.is_active():
		auto_walk.on_step_completed()
		if can_walk():
			auto_walk.try_step()

func on_walk_cancelled() -> void:
	auto_walk.on_walk_cancelled()

func try_auto_walk_step() -> bool:
	if not auto_walk.is_active() or not can_walk():
		return false
	return auto_walk.try_step()

func find_path_to(destination: Vector3i, flags: int = 0) -> Dictionary:
	return _PathfinderScript.find_path(
		_map.state, get_position(), destination, _PathfinderScript.MAX_COMPLEXITY_DEFAULT, flags, player_id
	)

# Bytes 0xA0 (860): u16 hp, u16 maxHp, u32 cap/100, u32 exp, u16 lvl, u8 lvl%,
# u16 mana, u16 maxMana, u8 ml, u8 ml%, u8 soul, u16 stamina
func apply_stats(stats: Dictionary) -> void:
	health = stats.get("health", health)
	max_health = stats.get("max_health", max_health)
	free_capacity = stats.get("free_capacity", free_capacity)
	experience = stats.get("experience", experience)
	level = stats.get("level", level)
	level_percent = stats.get("level_percent", level_percent)
	mana = stats.get("mana", mana)
	max_mana = stats.get("max_mana", max_mana)
	magic_level = stats.get("magic_level", magic_level)
	magic_level_percent = stats.get("magic_level_percent", magic_level_percent)
	soul = stats.get("soul", soul)
	stamina = stats.get("stamina", stamina)

func get_stats() -> Dictionary:
	return {
		"health": health,
		"max_health": max_health,
		"free_capacity": free_capacity,
		"experience": experience,
		"level": level,
		"level_percent": level_percent,
		"mana": mana,
		"max_mana": max_mana,
		"magic_level": magic_level,
		"magic_level_percent": magic_level_percent,
		"soul": soul,
		"stamina": stamina,
	}
