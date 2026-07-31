extends RefCounted

const _MapParserScript := preload("res://src/game/map/MapParser.gd")
const _MapStateScript := preload("res://src/game/map/MapState.gd")
const _ProtocolReaderScript := preload("res://src/core/network/ProtocolReader.gd")
const _ProtocolDebugScript := preload("res://src/core/network/ProtocolDebug.gd")
const _ThingReaderScript := preload("res://src/io/ThingReader.gd")
const _ThingSpriteFactoryPath := "res://src/game/map/ThingSpriteFactory.gd"
const _DatReaderPath := "res://src/io/DatReader.gd"
const _CreatureWalkerScript := preload("res://src/game/creature/CreatureWalker.gd")
const _EffectAnimatorPath := "res://src/game/effects/EffectAnimator.gd"

static var _sprite_factory_script: GDScript
static var _dat_reader_script: GDScript
static var _effect_animator_script: GDScript

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
	_ProtocolDebugScript.begin_opcode(opcode, buffer)
	var handled := _consume_opcode_body(opcode, buffer, map_state, move_context)
	_ProtocolDebugScript.end_opcode(opcode, buffer)
	return handled

static func _consume_opcode_body(
	opcode: int,
	buffer: StreamPeerBuffer,
	map_state = null,
	move_context: Dictionary = {}
) -> bool:
	match opcode:
		0x78: # AddInventoryItem — OTC parseAddInventoryItem
			_handle_inventory_add(buffer, map_state, move_context)
		0x79: # RemoveInventoryItem — OTC parseRemoveInventoryItem
			_handle_inventory_remove(buffer, map_state, move_context)
		0x65: # MapMoveNorth — OTC parseMapMoveNorth
			var pos: Vector3i = map_state.player_pos
			pos.y -= 1
			map_state.player_pos = pos
			_map_read_description(
				0x65, buffer, map_state, move_context,
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
			_map_read_description(
				0x66, buffer, map_state, move_context,
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
			_map_read_description(
				0x67, buffer, map_state, move_context,
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
			_map_read_description(
				0x68, buffer, map_state, move_context,
				pos.x - _MapStateScript.MAP_LEFT,
				pos.y - _MapStateScript.MAP_TOP,
				pos.z,
				1,
				_MapStateScript.MAP_HEIGHT,
			)
		0x69: # UpdateTile — OTC parseUpdateTile
			var tile_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
			_MapParserScript.read_update_tile(buffer, map_state, tile_pos)
			move_context["map_updated"] = true
		0x6A: # CreateOnMap
			var create_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
			_add_thing_to_tile(buffer, map_state, create_pos, move_context)
			move_context["map_updated"] = true
		0x6B: # ChangeOnMap — OTC parseTileTransformThing (inclui CreatureTurn 0x63)
			_handle_change_on_map(buffer, map_state, move_context)
		0x6C: # DeleteOnMap — OTC parseTileRemoveThing
			_remove_mapped_thing(buffer, map_state, move_context)
			move_context["map_updated"] = true
		0x83:
			_handle_magic_effect(buffer, map_state, move_context)
		0x84:
			_handle_animated_text(buffer, map_state, move_context)
		0x85:
			_handle_distance_missile(buffer, map_state, move_context)
		0x8C:
			_handle_creature_health(buffer, map_state, move_context)
		0x8D:
			_handle_creature_light(buffer, map_state, move_context)
		0x8E:
			_handle_creature_outfit(buffer, map_state, move_context)
		0x8F:
			_handle_creature_speed(buffer, map_state, move_context)
		0x90: # CreatureSkull
			buffer.get_u32()
			buffer.get_u8()
		0x91: # CreatureParty
			buffer.get_u32()
			buffer.get_u8()
		0x6E: # OpenContainer — OTC parseOpenContainer
			_handle_open_container(buffer, map_state, move_context)
		0x82:
			buffer.get_u8()
			buffer.get_u8()
		0xA0: # PlayerStats — OTC parsePlayerStats (TFS AddPlayerStats)
			_handle_player_stats(buffer, move_context)
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
		0xB4: # TextMessage — OTC parseTextMessage (TFS sendTextMessage; NÃO é CreatureTurn)
			_handle_text_message(buffer, move_context)
		0xB5: # CancelWalk — OTC parseCancelWalk
			_handle_cancel_walk(buffer, map_state, move_context)
		0xB7:
			for _i in range(7):
				buffer.get_u8()
		0xB8:
			buffer.get_u8()
		0xD2: # VIP add — OTC parseVipAdd (860)
			buffer.get_u32()
			_ProtocolReaderScript.skip_string(buffer)
			buffer.get_u8()
		0x32: # GameExtendedOpcode — OTC parseExtendedOpcode (860: GameExtendedOpcode)
			_handle_extended_opcode(buffer, move_context)
		0x6F: # CloseContainer
			_handle_close_container(buffer, map_state, move_context)
		0xBE: # Floor change up — OTC parseFloorChangeUp / TFS MoveUpCreature
			_ProtocolDebugScript.map_parse_begin(0xBE, buffer, map_state.player_pos.z)
			_MapParserScript.read_floor_change_up(buffer, map_state)
			_ProtocolDebugScript.map_parse_end(buffer, -1)
			move_context["map_updated"] = true
		0xBF: # Floor change down — OTC parseFloorChangeDown / TFS MoveDownCreature
			_ProtocolDebugScript.map_parse_begin(0xBF, buffer, map_state.player_pos.z)
			_MapParserScript.read_floor_change_down(buffer, map_state)
			_ProtocolDebugScript.map_parse_end(buffer, -1)
			move_context["map_updated"] = true
		0xA4: # Spell cooldown
			buffer.get_u8()
			buffer.get_u32()
		0xA5: # Spell group cooldown
			buffer.get_u8()
			buffer.get_u32()
		0x6D: # MoveCreature
			var move_result: Dictionary = _handle_creature_move(buffer, map_state, move_context)
			if not move_result.is_empty():
				move_context["last_move"] = move_result
		0x70: # ContainerAddItem — OTC parseContainerAddItem
			_handle_container_add_item(buffer, map_state, move_context)
		0x71: # ContainerUpdateItem
			_handle_container_update_item(buffer, map_state, move_context)
		0x72: # ContainerRemoveItem
			_handle_container_remove_item(buffer, map_state, move_context)
		0x7A: # OpenNpcTrade — TFS sendShop / OTC parseOpenNpcTrade (860)
			_skip_npc_shop(buffer)
		0x7B: # PlayerGoods — TFS sendSaleItemList / OTC parsePlayerGoods (860)
			_skip_player_goods(buffer)
		0x7C: # CloseNpcTrade — TFS sendCloseShop (vazio)
			pass
		0x7D, 0x7E: # OwnTrade / CounterTrade — TFS sendTradeItemRequest
			_skip_trade_request(buffer)
		0x7F: # CloseTrade — TFS sendCloseTrade (vazio)
			pass
		_:
			push_warning("GameOpcodeReader: Opcode 0x%02X nao implementado." % (opcode & 0xFF))
			return false
	return true

static func _map_read_description(
	opcode: int,
	buffer: StreamPeerBuffer,
	map_state,
	move_context: Dictionary,
	start_x: int,
	start_y: int,
	center_z: int,
	width: int,
	height: int
) -> void:
	_ProtocolDebugScript.map_parse_begin(opcode, buffer, center_z)
	var skip_final: int = 0
	_MapParserScript.read_map_description(
		buffer, map_state, start_x, start_y, center_z, width, height
	)
	_ProtocolDebugScript.map_parse_end(buffer, skip_final)
	move_context["map_updated"] = true

static func parse_login(buffer: StreamPeerBuffer) -> Dictionary:
	var player_id := buffer.get_u32()
	var beat_duration := buffer.get_u16()
	var can_report_bugs := buffer.get_u8()
	return {
		"player_id": player_id,
		"beat_duration": beat_duration,
		"can_report_bugs": can_report_bugs,
	}

static func parse_full_map(buffer: StreamPeerBuffer) -> Dictionary:
	return _MapParserScript.parse_full_map(buffer)

static func _parse_player_stats(buffer: StreamPeerBuffer) -> Dictionary:
	# OTC parsePlayerStats + TFS AddPlayerStats — protocolo 8.60
	# u16 hp, u16 maxHp, u32 freeCap/100, u32 exp, u16 lvl, u8 lvl%,
	# u16 mana, u16 maxMana, u8 ml, u8 ml%, u8 soul, u16 stamina
	var health := buffer.get_u16()
	var max_health := buffer.get_u16()
	var free_capacity := float(buffer.get_u32()) / 100.0
	var experience := buffer.get_u32()
	var level := buffer.get_u16()
	var level_percent := buffer.get_u8()
	var mana := buffer.get_u16()
	var max_mana := buffer.get_u16()
	var magic_level := buffer.get_u8()
	var magic_level_percent := buffer.get_u8()
	var soul := buffer.get_u8()
	var stamina := buffer.get_u16()
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

static func _handle_player_stats(buffer: StreamPeerBuffer, move_context: Dictionary) -> void:
	var stats: Dictionary = _parse_player_stats(buffer)
	var world = _world_from(move_context)
	if world != null:
		world.player.apply_stats(stats)
	move_context["player_stats"] = stats

static func _read_mapped_thing(buffer: StreamPeerBuffer) -> Dictionary:
	# OTC getMappedThing() — pos+stackpos ou creature id (0xFFFF)
	var x := buffer.get_u16()
	if x != 0xFFFF:
		return {
			"pos": Vector3i(x, buffer.get_u16(), buffer.get_u8()),
			"stack_pos": buffer.get_u8(),
			"creature_id": 0,
		}
	return {
		"pos": Vector3i.ZERO,
		"stack_pos": -1,
		"creature_id": buffer.get_u32(),
	}

static func _handle_change_on_map(
	buffer: StreamPeerBuffer,
	map_state,
	move_context: Dictionary
) -> void:
	var mapped: Dictionary = _read_mapped_thing(buffer)
	var thing_id := buffer.get_u16()
	var new_thing: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id)
	var world = _world_from(move_context)

	# TFS sendCreatureTurn: 0x6B + mapped + 0x63 + u32 id + u8 direction
	if thing_id == _ThingReaderScript.CREATURE_TURN:
		var creature_id: int = new_thing.get("id", 0)
		var direction: int = new_thing.get("direction", 0)
		if world != null:
			world.creatures.turn(creature_id, direction)
		elif map_state != null:
			var creature: Dictionary = map_state.find_creature_by_id(creature_id)
			if not creature.is_empty():
				creature["direction"] = direction
		move_context["creature_turn"] = {"id": creature_id, "direction": direction}
		move_context["map_updated"] = true
		return

	if world != null:
		world.map.transform_thing(mapped, new_thing)
	elif map_state != null:
		_transform_thing_on_map(map_state, mapped, new_thing)
	move_context["map_updated"] = true

static func _transform_thing_on_map(map_state, mapped: Dictionary, new_thing: Dictionary) -> void:
	var pos: Vector3i
	var stack_pos: int = -1
	var creature_id: int = mapped.get("creature_id", 0)

	if creature_id > 0:
		var creature: Dictionary = map_state.find_creature_by_id(creature_id)
		if creature.is_empty():
			return
		pos = creature.get("tile_pos", Vector3i.ZERO)
		var tile = map_state.get_tile(pos)
		if tile == null:
			return
		for i in range(tile.creatures.size()):
			if tile.creatures[i].get("id", 0) == creature_id:
				stack_pos = i
				break
		if stack_pos < 0:
			return
	else:
		pos = mapped.get("pos", Vector3i.ZERO)
		stack_pos = mapped.get("stack_pos", 0)

	_remove_thing_at(map_state, pos, stack_pos)
	var tile = map_state.get_or_create_tile(pos)
	if new_thing.get("kind") == "creature":
		new_thing["tile_pos"] = pos
		tile.creatures.append(new_thing)
		map_state.register_creature(new_thing)
	else:
		tile.items.append(new_thing)

# OTC parseTextMessage — modo padrão 860: u8 mode + string
static func _handle_text_message(buffer: StreamPeerBuffer, move_context: Dictionary) -> void:
	var mode := buffer.get_u8()
	var text: String = _ProtocolReaderScript.read_string(buffer)
	move_context["text_message"] = {"mode": mode, "text": text}

# OTC parseExtendedOpcode — u8 opcode + string; opcode 0 habilita envio
static func _handle_extended_opcode(buffer: StreamPeerBuffer, move_context: Dictionary) -> void:
	var ext_opcode := buffer.get_u8()
	var payload: String = _ProtocolReaderScript.read_string(buffer)
	if ext_opcode == 0:
		move_context["extended_opcode_enabled"] = true
	else:
		print(
			"GameOpcodeReader: ExtendedOpcode %d (%d bytes): %s" % [
				ext_opcode, payload.length(), payload.substr(0, 64)
			]
		)
	move_context["extended_opcode"] = {"opcode": ext_opcode, "payload": payload}

static func _skip_player_skills(buffer: StreamPeerBuffer) -> void:
	for _i in range(7):
		buffer.get_u8()
		buffer.get_u8()

static func _world_from(move_context: Dictionary):
	return move_context.get("world")

static func _handle_creature_move(
	buffer: StreamPeerBuffer,
	map_state,
	move_context: Dictionary
) -> Dictionary:
	var world = _world_from(move_context)
	if world != null:
		return world.creatures.move(buffer, move_context)
	if map_state == null:
		return {}
	push_warning("GameOpcodeReader: 0x6D sem GameWorld — pacote ignorado.")
	return {}

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
static func _handle_magic_effect(buffer: StreamPeerBuffer, map_state, move_context: Dictionary = {}) -> void:
	var world = _world_from(move_context)
	if world != null:
		world.effects.add_magic_effect(buffer)
		return
	if map_state == null:
		return
	var tile_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var effect_id := buffer.get_u8()
	if effect_id <= 0:
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
static func _handle_animated_text(buffer: StreamPeerBuffer, map_state, move_context: Dictionary = {}) -> void:
	var world = _world_from(move_context)
	if world != null:
		world.effects.add_animated_text(buffer)
		return
	if map_state == null:
		return
	var tile_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var color := buffer.get_u8()
	var text: String = _ProtocolReaderScript.read_string(buffer)
	map_state.active_animated_texts.append({
		"text": text,
		"color": color,
		"tile_pos": tile_pos,
		"start_ms": Time.get_ticks_msec(),
	})

# ---------------------------------------------------------------------------
# DISTANCE MISSILE — Opcode 0x85
# ---------------------------------------------------------------------------
static func _handle_distance_missile(buffer: StreamPeerBuffer, map_state, move_context: Dictionary = {}) -> void:
	var world = _world_from(move_context)
	if world != null:
		world.effects.add_missile(buffer)
		return
	if map_state == null:
		return
	var from_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var to_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var missile_id := buffer.get_u8()
	if missile_id <= 0:
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
static func _handle_creature_health(buffer: StreamPeerBuffer, map_state, move_context: Dictionary = {}) -> void:
	var creature_id := buffer.get_u32()
	var health_percent := buffer.get_u8()
	var world = _world_from(move_context)
	if world != null:
		world.creatures.update_health(creature_id, health_percent)
		return
	if map_state == null:
		return
	var creature: Dictionary = map_state.find_creature_by_id(creature_id)
	if not creature.is_empty():
		creature["health_percent"] = health_percent

# ---------------------------------------------------------------------------
# CREATURE LIGHT — Opcode 0x8D (TFS 8.60)
# ---------------------------------------------------------------------------
static func _handle_creature_light(buffer: StreamPeerBuffer, map_state, move_context: Dictionary = {}) -> void:
	var creature_id := buffer.get_u32()
	var light_level := buffer.get_u8()
	var light_color := buffer.get_u8()
	var world = _world_from(move_context)
	if world != null:
		world.creatures.update_light(creature_id, light_level, light_color)
		return
	if map_state == null:
		return
	var creature: Dictionary = map_state.find_creature_by_id(creature_id)
	if not creature.is_empty():
		creature["light_level"] = light_level
		creature["light_color"] = light_color

# ---------------------------------------------------------------------------
# CREATURE OUTFIT — Opcode 0x8E (TFS 8.60)
# ---------------------------------------------------------------------------
static func _handle_creature_outfit(buffer: StreamPeerBuffer, map_state, move_context: Dictionary = {}) -> void:
	var creature_id := buffer.get_u32()
	var outfit_data := {}
	_ThingReaderScript.read_outfit(buffer, outfit_data)
	var world = _world_from(move_context)
	if world != null:
		world.creatures.apply_outfit(creature_id, outfit_data)
		return
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
static func _handle_creature_speed(buffer: StreamPeerBuffer, map_state, move_context: Dictionary = {}) -> void:
	var creature_id := buffer.get_u32()
	var speed := buffer.get_u16()
	var world = _world_from(move_context)
	if world != null:
		world.creatures.update_speed(creature_id, speed)
		return
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

# TFS sendShop (0x7A): u8 count + AddShopItem por entrada (860, sem nome do NPC).
static func _skip_npc_shop(buffer: StreamPeerBuffer) -> void:
	if buffer.get_available_bytes() < 1:
		return
	var count := buffer.get_u8()
	for _i in range(count):
		if buffer.get_available_bytes() < 2:
			return
		buffer.get_u16() # clientId
		if buffer.get_available_bytes() < 1:
			return
		buffer.get_u8()  # fluid subtype ou 0x00
		_ProtocolReaderScript.skip_string(buffer)
		if buffer.get_available_bytes() < 12:
			return
		buffer.get_u32() # weight
		buffer.get_u32() # buyPrice
		buffer.get_u32() # sellPrice

# TFS sendSaleItemList (0x7B): dinheiro u32 + lista de itens vendáveis.
static func _skip_player_goods(buffer: StreamPeerBuffer) -> void:
	if buffer.get_available_bytes() < 5:
		return
	buffer.get_u32()
	var count := buffer.get_u8()
	for _i in range(count):
		if buffer.get_available_bytes() < 3:
			return
		buffer.get_u16()
		buffer.get_u8()

# TFS sendTradeItemRequest (0x7D/0x7E): nome + itens do trade.
static func _skip_trade_request(buffer: StreamPeerBuffer) -> void:
	if buffer.get_available_bytes() < 3:
		push_warning("GameOpcodeReader: trade request truncado.")
		return
	_ProtocolReaderScript.skip_string(buffer)
	if buffer.get_available_bytes() < 1:
		return
	var count := buffer.get_u8()
	for _i in range(count):
		if buffer.get_available_bytes() < 2:
			push_warning("GameOpcodeReader: trade request item truncado.")
			return
		var item_id := buffer.get_u16()
		_ThingReaderScript.skip_item(buffer, item_id)

static func _skip_open_container(buffer: StreamPeerBuffer) -> void:
	buffer.get_u8()
	_ThingReaderScript.skip_thing(buffer)
	_ProtocolReaderScript.skip_string(buffer)
	buffer.get_u8()
	buffer.get_u8()
	var item_count: int = buffer.get_u8()
	for _i in range(item_count):
		_ThingReaderScript.skip_thing(buffer)

static func _handle_inventory_add(buffer: StreamPeerBuffer, map_state, move_context: Dictionary) -> void:
	var world = _world_from(move_context)
	if world != null:
		world.inventory.add_item(buffer)
		move_context["inventory_updated"] = true
		return
	var slot := buffer.get_u8()
	var thing_id := buffer.get_u16()
	var item: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id)
	if map_state == null:
		return
	map_state.set_inventory_item(slot, item)
	move_context["inventory_updated"] = true

static func _handle_inventory_remove(buffer: StreamPeerBuffer, map_state, move_context: Dictionary) -> void:
	var world = _world_from(move_context)
	if world != null:
		world.inventory.remove_item(buffer)
		move_context["inventory_updated"] = true
		return
	var slot := buffer.get_u8()
	if map_state != null:
		map_state.set_inventory_item(slot, {})
		move_context["inventory_updated"] = true

static func _handle_open_container(buffer: StreamPeerBuffer, map_state, move_context: Dictionary) -> void:
	var world = _world_from(move_context)
	if world != null:
		var container_id: int = world.containers.open(buffer)
		if container_id >= 0:
			move_context["container_updated"] = container_id
		return
	var container_id := buffer.get_u8()
	var container_thing_id := buffer.get_u16()
	var container_item: Dictionary = _ThingReaderScript.read_thing(buffer, container_thing_id)
	var container_name: String = _ProtocolReaderScript.read_string(buffer)
	var capacity := buffer.get_u8()
	var has_parent := buffer.get_u8() != 0
	var item_count: int = buffer.get_u8()
	var items: Array[Dictionary] = []
	for _i in range(item_count):
		var item_id := buffer.get_u16()
		items.append(_ThingReaderScript.read_thing(buffer, item_id))
	if map_state != null:
		map_state.open_container(container_id, {
			"id": container_id,
			"item": container_item,
			"name": container_name,
			"capacity": capacity,
			"has_parent": has_parent,
			"items": items,
		})
		move_context["container_updated"] = container_id

static func _handle_close_container(buffer: StreamPeerBuffer, map_state, move_context: Dictionary) -> void:
	var world = _world_from(move_context)
	if world != null:
		var container_id: int = world.containers.close(buffer)
		if container_id >= 0:
			move_context["container_updated"] = container_id
		return
	var container_id := buffer.get_u8()
	if map_state != null:
		map_state.close_container(container_id)
		move_context["container_updated"] = container_id

static func _handle_container_add_item(buffer: StreamPeerBuffer, map_state, move_context: Dictionary) -> void:
	var world = _world_from(move_context)
	if world != null:
		var container_id: int = world.containers.add_item(buffer)
		if container_id >= 0:
			move_context["container_updated"] = container_id
		return
	var container_id := buffer.get_u8()
	var thing_id := buffer.get_u16()
	var item: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id)
	if map_state == null:
		return
	var container: Dictionary = map_state.get_container(container_id)
	if container.is_empty():
		return
	var items: Array = container.get("items", [])
	items.append(item)
	container["items"] = items
	move_context["container_updated"] = container_id

static func _handle_container_update_item(buffer: StreamPeerBuffer, map_state, move_context: Dictionary) -> void:
	var world = _world_from(move_context)
	if world != null:
		var container_id: int = world.containers.update_item(buffer)
		if container_id >= 0:
			move_context["container_updated"] = container_id
		return
	var container_id := buffer.get_u8()
	var slot := buffer.get_u8()
	var thing_id := buffer.get_u16()
	var item: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id)
	if map_state == null:
		return
	var container: Dictionary = map_state.get_container(container_id)
	if container.is_empty():
		return
	var items: Array = container.get("items", [])
	while items.size() <= slot:
		items.append({})
	items[slot] = item
	container["items"] = items
	move_context["container_updated"] = container_id

static func _handle_container_remove_item(buffer: StreamPeerBuffer, map_state, move_context: Dictionary) -> void:
	var world = _world_from(move_context)
	if world != null:
		var container_id: int = world.containers.remove_item(buffer)
		if container_id >= 0:
			move_context["container_updated"] = container_id
		return
	var container_id := buffer.get_u8()
	var slot := buffer.get_u8()
	if map_state == null:
		return
	var container: Dictionary = map_state.get_container(container_id)
	if container.is_empty():
		return
	var items: Array = container.get("items", [])
	if slot >= 0 and slot < items.size():
		items.remove_at(slot)
	container["items"] = items
	move_context["container_updated"] = container_id

static func _handle_cancel_walk(buffer: StreamPeerBuffer, map_state, move_context: Dictionary) -> void:
	var direction := buffer.get_u8()
	var world = _world_from(move_context)
	if world != null:
		var cancel_data: Dictionary = world.creatures.cancel_walk(direction, world.player.player_id)
		if not cancel_data.is_empty():
			move_context["walk_cancel"] = cancel_data
		return
	if map_state == null:
		return
	var player_id: int = move_context.get("player_id", 0)
	if player_id <= 0:
		return
	var found := _find_creature_by_id(map_state, player_id)
	if found.is_empty():
		return
	var creature: Dictionary = found.creature
	var tile = found.tile
	var tile_pos: Vector3i = found.tile_pos
	var tile_idx: int = found.index

	if creature.get("is_walking", false):
		var from_pos: Vector3i = creature.get("from_tile_pos", tile_pos)
		_creature_walker().cancel_walk(creature, direction)
		tile.creatures.remove_at(tile_idx)
		if tile.creatures.is_empty() and tile.items.is_empty():
			map_state.remove_tile(tile_pos)
		var revert_tile = map_state.get_or_create_tile(from_pos)
		revert_tile.creatures.append(creature)
		creature["tile_pos"] = from_pos
		map_state.player_pos = from_pos
	else:
		creature["direction"] = direction

	move_context["walk_cancel"] = {
		"creature": creature,
		"direction": direction,
		"player_pos": map_state.player_pos,
	}

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

static func _add_thing_to_tile(
	buffer: StreamPeerBuffer,
	map_state,
	position: Vector3i,
	move_context: Dictionary = {}
) -> void:
	var thing_id: int = buffer.get_u16()
	var thing: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id)
	if map_state == null:
		return
	var world = _world_from(move_context)
	if world != null:
		world.map.add_thing_to_tile(position, thing)
		return
	var tile = map_state.get_or_create_tile(position)
	if thing.get("kind") == "creature":
		thing["tile_pos"] = position
		tile.creatures.append(thing)
		map_state.register_creature(thing)
	else:
		tile.items.append(thing)

static func _remove_mapped_thing(buffer: StreamPeerBuffer, map_state, move_context: Dictionary = {}) -> void:
	var x := buffer.get_u16()
	if x == 0xFFFF:
		var creature_id := buffer.get_u32()
		var world = _world_from(move_context)
		if world != null:
			var found = world.creatures.find_location(creature_id)
			var tile = found.get("tile")
			var index = found.get("index", -1)
			if tile != null and index >= 0:
				tile.creatures.remove_at(index)
			return
		if map_state != null and map_state.has_method("find_creature_by_id"):
			var found = _find_creature_by_id(map_state, creature_id)
			var tile = found.get("tile")
			var index = found.get("index", -1)
			if tile != null and index >= 0:
				tile.creatures.remove_at(index)
	else:
		var remove_pos := Vector3i(x, buffer.get_u16(), buffer.get_u8())
		var stack_pos := buffer.get_u8()
		var world = _world_from(move_context)
		if world != null:
			world.map.remove_thing_at(remove_pos, stack_pos)
			return
		_remove_thing_at(map_state, remove_pos, stack_pos)

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
