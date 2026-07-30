extends RefCounted

const _MapParserPath := "res://src/game/map/MapParser.gd"
const _MapStateScript := preload("res://src/game/map/MapState.gd")
const _ProtocolReaderScript := preload("res://src/core/network/ProtocolReader.gd")
const _ThingReaderScript := preload("res://src/io/ThingReader.gd")
const _ThingSpriteFactoryPath := "res://src/game/map/ThingSpriteFactory.gd"
const _DatReaderPath := "res://src/io/DatReader.gd"
const _CreatureWalkerScript := preload("res://src/game/creature/CreatureWalker.gd")
const _EffectAnimatorPath := "res://src/game/effects/EffectAnimator.gd"

static var _map_parser_script: GDScript
static var _sprite_factory_script: GDScript
static var _dat_reader_script: GDScript
static var _effect_animator_script: GDScript

static func _map_parser() -> GDScript:
	if _map_parser_script == null:
		_map_parser_script = load(_MapParserPath) as GDScript
	return _map_parser_script

static func _sprite_factory() -> GDScript:
	if _sprite_factory_script == null:
		_sprite_factory_script = load(_ThingSpriteFactoryPath) as GDScript
	return _sprite_factory_script

static func _dat_reader() -> GDScript:
	if _dat_reader_script == null:
		_dat_reader_script = load(_DatReaderPath) as GDScript
	return _dat_reader_script

static func _creature_walker():
	return _CreatureWalkerScript

static func _effect_animator() -> GDScript:
	if _effect_animator_script == null:
		_effect_animator_script = load(_EffectAnimatorPath) as GDScript
	return _effect_animator_script

static func consume_opcode(
	opcode: int,
	buffer: StreamPeerBuffer,
	map_state = null,
	move_context: Dictionary = {}
) -> bool:
	match opcode:
		0x78:
			buffer.get_u8()
			_ThingReaderScript.skip_thing(buffer)
		0x79:
			buffer.get_u8()
		0x65: # MapMoveNorth — OTC parseMapMoveNorth
			var pos: Vector3i = map_state.player_pos
			pos.y -= 1
			map_state.player_pos = pos
			_map_parser().read_map_description(
				buffer,
				map_state,
				pos.x - _MapStateScript.MAP_LEFT,
				pos.y - _MapStateScript.MAP_TOP,
				pos.z,
				_MapStateScript.MAP_WIDTH,
				1,
			)
		0x66: # MapMoveEast
			var pos: Vector3i = map_state.player_pos
			pos.x += 1
			map_state.player_pos = pos
			_map_parser().read_map_description(
				buffer,
				map_state,
				pos.x + _MapStateScript.MAP_RIGHT,
				pos.y - _MapStateScript.MAP_TOP,
				pos.z,
				1,
				_MapStateScript.MAP_HEIGHT,
			)
		0x67: # MapMoveSouth
			var pos: Vector3i = map_state.player_pos
			pos.y += 1
			map_state.player_pos = pos
			_map_parser().read_map_description(
				buffer,
				map_state,
				pos.x - _MapStateScript.MAP_LEFT,
				pos.y + _MapStateScript.MAP_BOTTOM,
				pos.z,
				_MapStateScript.MAP_WIDTH,
				1,
			)
		0x68: # MapMoveWest
			var pos: Vector3i = map_state.player_pos
			pos.x -= 1
			map_state.player_pos = pos
			_map_parser().read_map_description(
				buffer,
				map_state,
				pos.x - _MapStateScript.MAP_LEFT,
				pos.y - _MapStateScript.MAP_TOP,
				pos.z,
				1,
				_MapStateScript.MAP_HEIGHT,
			)
		0x69: # UpdateTile — OTC parseUpdateTile
			var tile_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
			_map_parser().read_update_tile(buffer, map_state, tile_pos)
		0x6A: # CreateOnMap
			var create_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
			_add_thing_to_tile(buffer, map_state, create_pos)
		0x6B: # ChangeOnMap — OTC parseTileTransformThing (getMappedThing + getThing)
			_ProtocolReaderScript.skip_mapped_thing(buffer)
			_ThingReaderScript.skip_thing(buffer)
		0x6C: # DeleteOnMap — OTC parseTileRemoveThing
			var remove_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
			var stack_pos: int = buffer.get_u8()
			_remove_thing_at(map_state, remove_pos, stack_pos)
		0x83:
			_handle_magic_effect(buffer, map_state)
		0x84:
			_handle_animated_text(buffer, map_state)
		0x85:
			_handle_distance_missile(buffer, map_state)
		0x8C:
			_handle_creature_health(buffer, map_state)
		0x8D:
			_handle_creature_light(buffer, map_state)
		0x8E:
			_handle_creature_outfit(buffer, map_state)
		0x8F:
			_handle_creature_speed(buffer, map_state)
		0x6E: # OpenContainer — OTC parseOpenContainer
			_skip_open_container(buffer)
		0x82:
			buffer.get_u8()
			buffer.get_u8()
		0xA0:
			_skip_player_stats(buffer)
		0xA1:
			_skip_player_skills(buffer)
		0x92: # CreatureUnpass
			buffer.get_u32()
		0x93: # CreaturesMark
			var len := buffer.get_u8()
			for i in range(len):
				buffer.get_u32()
				buffer.get_u8()
				buffer.get_u8()
		0xA2:
			buffer.get_u16()
		0xAA: # Talk / mensagem de canal — OTC parseTalk (860)
			_skip_talk_message(buffer)
		0xAC: # Open channel — OTC parseOpenChannel (860)
			_skip_open_channel(buffer)
		0xA7:
			buffer.get_u8()
			buffer.get_u8()
			buffer.get_u8()
		0xB4:
			buffer.get_u8()
			_ProtocolReaderScript.skip_string(buffer)
		0xB5: # CancelWalk — OTC parseCancelWalk
			buffer.get_u8()
		0xB7:
			for _i in range(7):
				buffer.get_u8()
		0xB8:
			buffer.get_u8()
		0xD2: # VIP add — OTC parseVipAdd (860)
			buffer.get_u32()
			_ProtocolReaderScript.skip_string(buffer)
			buffer.get_u8()
		0x32:
			buffer.get_u8()
			_ProtocolReaderScript.skip_string(buffer)
		0x6F: # CloseContainer
			buffer.get_u8()
		0xBE: # Floor change up/down (TFS MoveUp/MoveDownCreature)
			pass
		0xA4: # Spell cooldown
			buffer.get_u8()
			buffer.get_u32()
		0xA5: # Spell group cooldown
			buffer.get_u8()
			buffer.get_u32()
		0x6D:
			var move_result: Dictionary = _handle_creature_move(buffer, map_state, move_context)
			if not move_result.is_empty():
				move_context["last_move"] = move_result
		0x70: # ContainerAddItem — OTC parseContainerAddItem
			buffer.get_u8()
			_ThingReaderScript.skip_thing(buffer)
		0x71: # ContainerUpdateItem
			buffer.get_u8()
			buffer.get_u8()
			_ThingReaderScript.skip_thing(buffer)
		0x72: # ContainerRemoveItem
			buffer.get_u8()
			buffer.get_u8()
		_:
			push_warning("GameOpcodeReader: Opcode 0x%02X nao implementado." % (opcode & 0xFF))
			return false
	return true

static func parse_login(buffer: StreamPeerBuffer) -> Dictionary:
	var player_id := buffer.get_u32()
	var beat_duration := buffer.get_u16()
	var can_report_bugs := buffer.get_u8()
	return {
		"player_id": player_id,
		"beat_duration": beat_duration,
		"can_report_bugs": can_report_bugs,
	}

static func parse_full_map(buffer: StreamPeerBuffer):
	return _map_parser().parse_full_map(buffer)

static func _skip_player_stats(buffer: StreamPeerBuffer) -> void:
	buffer.get_u16()
	buffer.get_u16()
	buffer.get_u32()
	buffer.get_u32()
	buffer.get_u16()
	buffer.get_u8()
	buffer.get_u16()
	buffer.get_u16()
	buffer.get_u8()
	buffer.get_u8()
	buffer.get_u8()
	buffer.get_u16()

static func _skip_player_skills(buffer: StreamPeerBuffer) -> void:
	for _i in range(7):
		buffer.get_u8()
		buffer.get_u8()

static func _handle_creature_move(
	buffer: StreamPeerBuffer,
	map_state,
	move_context: Dictionary
) -> Dictionary:
	if map_state == null:
		return {}

	var x := buffer.get_u16()
	var old_pos := Vector3i.ZERO
	var creature: Dictionary = {}
	var old_tile = null
	var creature_idx := -1

	if x == 0xFFFF:
		var creature_id := buffer.get_u32()
		# Usar índice O(1) se disponível
		if map_state.has_method("find_creature_by_id"):
			creature = map_state.find_creature_by_id(creature_id)
			if creature.is_empty():
				push_warning("GameOpcodeReader: criatura id %d nao encontrada no 0x6D." % creature_id)
				return {}
			# Localizar tile e index para remoção
			var found := _find_creature_by_id(map_state, creature_id)
			old_tile = found.get("tile")
			creature_idx = found.get("index", -1)
			old_pos = found.get("tile_pos", Vector3i.ZERO)
			if old_tile == null or creature_idx < 0:
				return {}
		else:
			var found := _find_creature_by_id(map_state, creature_id)
			if found.is_empty():
				push_warning("GameOpcodeReader: criatura id %d nao encontrada no 0x6D." % creature_id)
				return {}
			creature = found.creature
			old_tile = found.tile
			creature_idx = found.index
			old_pos = found.tile_pos
	else:
		old_pos = Vector3i(x, buffer.get_u16(), buffer.get_u8())
		var old_stack_pos := buffer.get_u8()
		old_tile = map_state.get_tile(old_pos)
		if old_tile == null:
			push_warning("GameOpcodeReader: tile antigo %s nao encontrado." % old_pos)
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

	var new_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	if old_pos == new_pos:
		return {}

	old_tile.creatures.remove_at(creature_idx)
	var new_tile = map_state.get_or_create_tile(new_pos)
	new_tile.creatures.append(creature)

	var server_beat: int = max(move_context.get("server_beat", 50), 1)
	var player_id: int = move_context.get("player_id", 0)
	var is_diagonal: bool = old_pos.x != new_pos.x and old_pos.y != new_pos.y
	var ground_speed := _ground_speed_for_tile(new_tile)
	var speed: int = max(creature.get("speed", 200), 1)
	var duration: int = _creature_walker().calc_step_duration(
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
		map_state.player_pos = new_pos

	return {
		"creature": creature,
		"old_pos": old_pos,
		"new_pos": new_pos,
		"is_player": creature.get("id", 0) == player_id,
	}

static func _find_creature_by_id(map_state, creature_id: int) -> Dictionary:
	for tile_key in map_state.tiles:
		var tile = map_state.tiles[tile_key]
		for i in range(tile.creatures.size()):
			if tile.creatures[i].get("id", 0) == creature_id:
				var parts: PackedStringArray = String(tile_key).split(",")
				if parts.size() != 3:
					continue
				return {
					"creature": tile.creatures[i],
					"tile": tile,
					"index": i,
					"tile_pos": Vector3i(int(parts[0]), int(parts[1]), int(parts[2])),
				}
	return {}

# ---------------------------------------------------------------------------
# MAGIC EFFECT — Opcode 0x83
# ---------------------------------------------------------------------------
static func _handle_magic_effect(buffer: StreamPeerBuffer, map_state) -> void:
	var tile_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var effect_id := buffer.get_u8()
	if map_state == null or effect_id <= 0:
		return
	var tile = map_state.get_or_create_tile(tile_pos)
	tile.effects.append({
		"effect_id": effect_id,
		"tile_pos": tile_pos,
		"start_ms": Time.get_ticks_msec(),
	})

# ---------------------------------------------------------------------------
# ANIMATED TEXT — Opcode 0x84
# ---------------------------------------------------------------------------
static func _handle_animated_text(buffer: StreamPeerBuffer, map_state) -> void:
	var tile_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var color := buffer.get_u8()
	var text: String = _ProtocolReaderScript.read_string(buffer)
	if map_state == null:
		return
	map_state.active_animated_texts.append({
		"text": text,
		"color": color,
		"tile_pos": tile_pos,
		"start_ms": Time.get_ticks_msec(),
	})

# ---------------------------------------------------------------------------
# DISTANCE MISSILE — Opcode 0x85
# ---------------------------------------------------------------------------
static func _handle_distance_missile(buffer: StreamPeerBuffer, map_state) -> void:
	var from_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var to_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var missile_id := buffer.get_u8()
	if map_state == null or missile_id <= 0:
		return
	var animator := _effect_animator()
	var duration: int = animator.calc_missile_duration(from_pos, to_pos)
	var direction: int = animator.calc_missile_direction(from_pos, to_pos)
	var dx := float(to_pos.x - from_pos.x) * 32.0
	var dy := float(to_pos.y - from_pos.y) * 32.0
	map_state.active_missiles.append({
		"missile_id": missile_id,
		"from_pos": from_pos,
		"to_pos": to_pos,
		"direction": direction,
		"delta_pixels": Vector2(dx, dy),
		"duration_ms": duration,
		"start_ms": Time.get_ticks_msec(),
	})

# ---------------------------------------------------------------------------
# CREATURE HEALTH — Opcode 0x8C
# ---------------------------------------------------------------------------
static func _handle_creature_health(buffer: StreamPeerBuffer, map_state) -> void:
	var creature_id := buffer.get_u32()
	var health_percent := buffer.get_u8()
	if map_state == null:
		return
	var creature: Dictionary = map_state.find_creature_by_id(creature_id)
	if not creature.is_empty():
		creature["health_percent"] = health_percent

# ---------------------------------------------------------------------------
# CREATURE LIGHT — Opcode 0x8D (TFS 8.60)
# ---------------------------------------------------------------------------
static func _handle_creature_light(buffer: StreamPeerBuffer, map_state) -> void:
	var creature_id := buffer.get_u32()
	var light_level := buffer.get_u8()
	var light_color := buffer.get_u8()
	if map_state == null:
		return
	var creature: Dictionary = map_state.find_creature_by_id(creature_id)
	if not creature.is_empty():
		creature["light_level"] = light_level
		creature["light_color"] = light_color

# ---------------------------------------------------------------------------
# CREATURE OUTFIT — Opcode 0x8E (TFS 8.60)
# ---------------------------------------------------------------------------
static func _handle_creature_outfit(buffer: StreamPeerBuffer, map_state) -> void:
	var creature_id := buffer.get_u32()
	var outfit_data := {}
	_ThingReaderScript.read_outfit(buffer, outfit_data)
	if map_state == null:
		return
	var creature: Dictionary = map_state.find_creature_by_id(creature_id)
	if creature.is_empty():
		return
	for key in outfit_data:
		creature[key] = outfit_data[key]

# ---------------------------------------------------------------------------
# CREATURE SPEED — Opcode 0x8F (TFS 8.60)
# ---------------------------------------------------------------------------
static func _handle_creature_speed(buffer: StreamPeerBuffer, map_state) -> void:
	var creature_id := buffer.get_u32()
	var speed := buffer.get_u16()
	if map_state == null:
		return
	var creature: Dictionary = map_state.find_creature_by_id(creature_id)
	if not creature.is_empty():
		creature["speed"] = speed

static func _ground_speed_for_tile(tile) -> int:
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

static func _skip_open_container(buffer: StreamPeerBuffer) -> void:
	buffer.get_u8()
	_ThingReaderScript.skip_thing(buffer)
	_ProtocolReaderScript.skip_string(buffer)
	buffer.get_u8()
	buffer.get_u8()
	var item_count: int = buffer.get_u8()
	for _i in range(item_count):
		_ThingReaderScript.skip_thing(buffer)

# OTC parseOpenChannel() — protocolo 8.60 (sem GameChannelPlayerList)
static func _skip_open_channel(buffer: StreamPeerBuffer) -> void:
	buffer.get_u16()
	_ProtocolReaderScript.skip_string(buffer)

# OTC parseTalk() — protocolo 8.60 (GameMessageStatements + GameMessageLevel)
static func _skip_talk_message(buffer: StreamPeerBuffer) -> void:
	buffer.get_u32()
	_ProtocolReaderScript.skip_string(buffer)
	buffer.get_u16()
	var mode: int = buffer.get_u8()
	match mode:
		1, 2, 3, 4, 5, 19, 20: # TFS SpeakClasses com posição
			_ProtocolReaderScript.read_position(buffer)
		7, 8, 13, 15, 17: # TALKTYPE_CHANNEL_* — u16 channel id
			buffer.get_u16()
		9: # TALKTYPE_RVR_CHANNEL
			buffer.get_u32()
		_:
			pass
	_ProtocolReaderScript.skip_string(buffer)

static func _add_thing_to_tile(buffer: StreamPeerBuffer, map_state, position: Vector3i) -> void:
	var thing_id: int = buffer.get_u16()
	var thing: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id)
	if map_state == null:
		return
	var tile = map_state.get_or_create_tile(position)
	if thing.get("kind") == "creature":
		tile.creatures.append(thing)
		map_state.register_creature(thing)
	else:
		tile.items.append(thing)

static func _remove_thing_at(map_state, position: Vector3i, stack_pos: int) -> void:
	if map_state == null:
		return
	var tile = map_state.get_tile(position)
	if tile == null:
		return
	if stack_pos < tile.creatures.size():
		tile.creatures.remove_at(stack_pos)
	elif stack_pos < tile.creatures.size() + tile.items.size():
		var item_idx: int = stack_pos - tile.creatures.size()
		tile.items.remove_at(item_idx)
	if tile.creatures.is_empty() and tile.items.is_empty():
		map_state.remove_tile(position)
