class_name TibiaCreatureManager
extends RefCounted

const _CreatureWalkerScript := preload("res://src/game/creature/CreatureWalker.gd")
const _ThingSpriteFactoryPath := "res://src/game/map/ThingSpriteFactory.gd"
const _DatReaderPath := "res://src/io/DatReader.gd"

var _map = null

static var _sprite_factory_script: GDScript
static var _dat_reader_script: GDScript

func _init(map_manager) -> void:
	_map = map_manager

func register(creature: Dictionary, tile_pos: Vector3i) -> void:
	creature["tile_pos"] = tile_pos
	_map.state.register_creature(creature)

func find(creature_id: int) -> Dictionary:
	return _map.state.find_creature_by_id(creature_id)

func find_location(creature_id: int) -> Dictionary:
	var creature: Dictionary = find(creature_id)
	if creature.is_empty():
		return {}
	if creature.has("tile_pos"):
		var tile_pos: Vector3i = creature["tile_pos"]
		var tile = _map.get_tile(tile_pos)
		if tile != null:
			for i in range(tile.creatures.size()):
				if tile.creatures[i].get("id", 0) == creature_id:
					return {"creature": creature, "tile": tile, "index": i, "tile_pos": tile_pos}
	for tile_key in _map.state.tiles:
		var tile = _map.state.tiles[tile_key]
		for i in range(tile.creatures.size()):
			if tile.creatures[i].get("id", 0) == creature_id:
				var parts: PackedStringArray = String(tile_key).split(",")
				if parts.size() != 3:
					continue
				var tile_pos := Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
				creature = tile.creatures[i]
				creature["tile_pos"] = tile_pos
				return {"creature": creature, "tile": tile, "index": i, "tile_pos": tile_pos}
	return {}

func move(buffer: StreamPeerBuffer, move_context: Dictionary) -> Dictionary:
	var x := buffer.get_u16()
	var old_pos := Vector3i.ZERO
	var creature: Dictionary = {}
	var old_tile = null
	var creature_idx := -1

	if x == 0xFFFF:
		var creature_id := buffer.get_u32()
		var found := find_location(creature_id)
		if found.is_empty():
			push_warning("CreatureManager: criatura id %d nao encontrada no 0x6D." % creature_id)
			return {}
		creature = found.creature
		old_tile = found.tile
		creature_idx = found.index
		old_pos = found.tile_pos
	else:
		old_pos = Vector3i(x, buffer.get_u16(), buffer.get_u8())
		var old_stack_pos := buffer.get_u8()
		old_tile = _map.get_tile(old_pos)
		if old_tile == null:
			push_warning("CreatureManager: tile antigo %s nao encontrado." % old_pos)
			return {}
		if old_stack_pos >= old_tile.creatures.size():
			if not old_tile.creatures.is_empty():
				creature_idx = old_tile.creatures.size() - 1
				creature = old_tile.creatures[creature_idx]
			else:
				return {}
		else:
			creature_idx = old_stack_pos
			creature = old_tile.creatures[creature_idx]

	var new_pos := _read_position(buffer)
	if old_pos == new_pos:
		return {}

	old_tile.creatures.remove_at(creature_idx)
	if old_tile.creatures.is_empty() and old_tile.items.is_empty():
		_map.remove_tile(old_pos)

	var new_tile = _map.get_or_create_tile(new_pos)
	new_tile.creatures.append(creature)

	var server_beat: int = max(move_context.get("server_beat", 50), 1)
	var player_id: int = move_context.get("player_id", 0)
	var is_diagonal: bool = old_pos.x != new_pos.x and old_pos.y != new_pos.y
	var ground_speed := _ground_speed_for_tile(new_tile)
	var speed: int = max(creature.get("speed", 200), 1)
	var duration: int = _CreatureWalkerScript.calc_step_duration(
		speed, ground_speed, server_beat, is_diagonal
	)
	if duration <= 0:
		duration = server_beat

	var dir := _direction_from_positions(old_pos, new_pos)
	var now_ms := Time.get_ticks_msec()

	creature["tile_pos"] = new_pos
	creature["from_tile_pos"] = old_pos
	creature["walk_direction"] = dir
	creature["direction"] = dir
	creature["is_walking"] = true
	creature["walk_start_ms"] = now_ms
	creature["foot_last_step_ms"] = now_ms
	creature["step_duration_ms"] = duration
	creature["walked_pixels"] = 0
	creature["walk_anim_phase"] = 0
	creature["foot_step"] = 0

	if creature.get("id", 0) == player_id:
		_map.set_player_pos(new_pos)

	return {
		"creature": creature,
		"old_pos": old_pos,
		"new_pos": new_pos,
		"is_player": creature.get("id", 0) == player_id,
	}

func cancel_walk(direction: int, player_id: int) -> Dictionary:
	if player_id <= 0:
		return {}
	var found := find_location(player_id)
	if found.is_empty():
		return {}
	var creature: Dictionary = found.creature
	var tile = found.tile
	var tile_pos: Vector3i = found.tile_pos
	var tile_idx: int = found.index

	if creature.get("is_walking", false):
		var from_pos: Vector3i = creature.get("from_tile_pos", tile_pos)
		_CreatureWalkerScript.cancel_walk(creature, direction)
		tile.creatures.remove_at(tile_idx)
		if tile.creatures.is_empty() and tile.items.is_empty():
			_map.remove_tile(tile_pos)
		var revert_tile = _map.get_or_create_tile(from_pos)
		revert_tile.creatures.append(creature)
		creature["tile_pos"] = from_pos
		_map.set_player_pos(from_pos)
	else:
		creature["direction"] = direction

	return {
		"creature": creature,
		"direction": direction,
		"player_pos": _map.get_player_pos(),
	}

func update_health(creature_id: int, health_percent: int) -> void:
	var creature := find(creature_id)
	if not creature.is_empty():
		creature["health_percent"] = health_percent

func update_light(creature_id: int, light_level: int, light_color: int) -> void:
	var creature := find(creature_id)
	if not creature.is_empty():
		creature["light_level"] = light_level
		creature["light_color"] = light_color

func apply_outfit(creature_id: int, outfit_data: Dictionary) -> void:
	var creature := find(creature_id)
	if creature.is_empty():
		return
	for key in outfit_data:
		creature[key] = outfit_data[key]

func update_speed(creature_id: int, speed: int) -> void:
	var creature := find(creature_id)
	if not creature.is_empty():
		creature["speed"] = speed

# CreatureTurn via 0x6B + thing 0x63 (TFS sendCreatureTurn) — OTC getCreature(CREATURE_TURN)
func turn(creature_id: int, direction: int) -> bool:
	var creature := find(creature_id)
	if creature.is_empty():
		push_warning("CreatureManager: turn — criatura %d nao encontrada." % creature_id)
		return false
	creature["direction"] = direction
	return true

func is_player_walking(player_id: int) -> bool:
	if player_id <= 0:
		return false
	var creature := find(player_id)
	return not creature.is_empty() and creature.get("is_walking", false)

static func _read_position(buffer: StreamPeerBuffer) -> Vector3i:
	return Vector3i(buffer.get_u16(), buffer.get_u16(), buffer.get_u8())

static func _direction_from_positions(old_pos: Vector3i, new_pos: Vector3i) -> int:
	if old_pos.y > new_pos.y and old_pos.x == new_pos.x:
		return 0
	if old_pos.x < new_pos.x and old_pos.y == new_pos.y:
		return 1
	if old_pos.y < new_pos.y and old_pos.x == new_pos.x:
		return 2
	if old_pos.x > new_pos.x and old_pos.y == new_pos.y:
		return 3
	if old_pos.x < new_pos.x and old_pos.y > new_pos.y:
		return 4
	if old_pos.x < new_pos.x and old_pos.y < new_pos.y:
		return 5
	if old_pos.x > new_pos.x and old_pos.y < new_pos.y:
		return 6
	if old_pos.x > new_pos.x and old_pos.y > new_pos.y:
		return 7
	return 2

static func _sprite_factory() -> GDScript:
	if _sprite_factory_script == null:
		_sprite_factory_script = load(_ThingSpriteFactoryPath) as GDScript
	return _sprite_factory_script

static func _dat_reader() -> GDScript:
	if _dat_reader_script == null:
		_dat_reader_script = load(_DatReaderPath) as GDScript
	return _dat_reader_script

func _ground_speed_for_tile(tile) -> int:
	if tile == null or tile.items.is_empty():
		return 150
	var factory := _sprite_factory()
	var dat := _dat_reader()
	for item in tile.items:
		var ground_thing = factory.get_thing(item.get("id", 0), dat.ThingCategory.ITEM)
		if ground_thing == null:
			continue
		var ground_speed: int = ground_thing.get_ground_speed()
		if ground_speed > 0:
			return ground_speed
	return 150
