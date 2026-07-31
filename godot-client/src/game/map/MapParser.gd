class_name TibiaMapParser
extends RefCounted

const _MapStateScript := preload("res://src/game/map/MapState.gd")
const _MapTileScript := preload("res://src/game/map/MapTile.gd")
const _ProtocolReaderScript := preload("res://src/core/network/ProtocolReader.gd")
const _ProtocolDebugScript := preload("res://src/core/network/ProtocolDebug.gd")
const _ThingReaderScript := preload("res://src/io/ThingReader.gd")
const _DesyncScript := preload("res://src/dev/MapDesyncDiagnostics.gd")

const SEA_FLOOR := 7
const UNDERGROUND_FLOOR := 8
const UNDERGROUND_RANGE := 2
const MAX_THINGS_PER_TILE := 10

static var _logged_first_tile_desync := false
static var _full_map_parse_active := false
static var _parse_failed := false

static func parse_full_map(buffer: StreamPeerBuffer) -> Dictionary:
	_full_map_parse_active = true
	_parse_failed = false
	_ProtocolDebugScript.begin_opcode(0x64, buffer)
	if not _ThingReaderScript.run_item_read_self_tests():
		push_warning("MapParser: ThingReader self-tests falharam — parse de mapa pode desyncar.")
	var map_start := buffer.get_position()
	var map_state = _MapStateScript.new()
	var player_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	map_state.player_pos = player_pos
	_DesyncScript.begin_map(player_pos)
	_logged_first_tile_desync = false

	var start_x: int = player_pos.x - _MapStateScript.MAP_LEFT
	var start_y: int = player_pos.y - _MapStateScript.MAP_TOP
	_ProtocolDebugScript.map_parse_begin(0x64, buffer, player_pos.z)
	read_map_description(
		buffer,
		map_state,
		start_x,
		start_y,
		player_pos.z,
		_MapStateScript.MAP_WIDTH,
		_MapStateScript.MAP_HEIGHT,
	)
	_ProtocolDebugScript.map_parse_end(buffer, 0)

	var ok := not _parse_failed
	var remaining := buffer.get_available_bytes()
	if ok and remaining > 0:
		var next_b: int = buffer.data_array[buffer.get_position()]
		if next_b not in [0x65, 0x66, 0x67, 0x68, 0x6D, 0x78, 0x79, 0x83, 0xA0, 0xA1, 0x82, 0x8D, 0xA2, 0xA7, 0xB4, 0xD2, 0xBE, 0xBF, 0x0A, 0xB5, 0x6E, 0x6F, 0x70, 0x71, 0x72]:
			push_warning(
				"MapParser: %d bytes apos mapa (opcode esperado, got 0x%02X). Hex: %s" % [
					remaining, next_b, _peek_hex(buffer, 12)
				]
			)

	var consumed := buffer.get_position() - map_start
	print(
		"MapParser: Mapa parseado em %s com %d tiles (%d bytes). Proximos bytes: %s%s" % [
			map_state.player_pos,
			map_state.tile_count(),
			consumed,
			_peek_hex(buffer, 8),
			"" if ok else " [FALHOU — desync]",
		]
	)
	_ProtocolDebugScript.end_opcode(0x64, buffer)
	_full_map_parse_active = false
	if not ok:
		return {
			"ok": false,
			"state": map_state,
			"error": "desync no parse do tile (ver MapDesync no console)",
		}
	return {"ok": true, "state": map_state}

# OTC setMapDescription()
static func read_map_description(
	buffer: StreamPeerBuffer,
	map_state,
	start_x: int,
	start_y: int,
	center_z: int,
	width: int,
	height: int
) -> void:
	var start_z: int
	var end_z: int
	var z_step: int
	if center_z > SEA_FLOOR:
		start_z = center_z - UNDERGROUND_RANGE
		end_z = mini(center_z + UNDERGROUND_RANGE, 15)
		z_step = 1
	else:
		start_z = SEA_FLOOR
		end_z = 0
		z_step = -1

	var skip := 0
	var z := start_z
	_ProtocolDebugScript.map_parse_note_floor(center_z)
	while true:
		if _full_map_parse_active and _parse_failed:
			break
		skip = _read_floor(
			buffer, map_state, start_x, start_y, z, width, height, center_z - z, skip
		)
		if z == end_z:
			break
		z += z_step

	if not _parse_failed or not _full_map_parse_active:
		_consume_trailing_map_skip(buffer)

static func read_update_tile(buffer: StreamPeerBuffer, map_state, position: Vector3i) -> void:
	read_tile_description(buffer, map_state, position)

static func read_floor_change_up(buffer: StreamPeerBuffer, map_state) -> void:
	var old_pos: Vector3i = map_state.player_pos
	var pos := Vector3i(old_pos.x, old_pos.y, old_pos.z - 1)
	var new_pos := Vector3i(pos.x + 1, pos.y + 1, pos.z)
	map_state.player_pos = new_pos

	var start_x: int = pos.x - _MapStateScript.MAP_LEFT
	var start_y: int = pos.y - _MapStateScript.MAP_TOP
	var skip := 0

	if pos.z == SEA_FLOOR:
		for z in range(SEA_FLOOR - UNDERGROUND_RANGE, -1, -1):
			skip = _read_floor(
				buffer, map_state, start_x, start_y, z,
				_MapStateScript.MAP_WIDTH, _MapStateScript.MAP_HEIGHT,
				8 - z, skip
			)
	elif pos.z > SEA_FLOOR:
		skip = _read_floor(
			buffer, map_state, start_x, start_y, pos.z - UNDERGROUND_RANGE,
			_MapStateScript.MAP_WIDTH, _MapStateScript.MAP_HEIGHT, 3, skip
		)

static func read_floor_change_down(buffer: StreamPeerBuffer, map_state) -> void:
	var old_pos: Vector3i = map_state.player_pos
	var pos := Vector3i(old_pos.x, old_pos.y, old_pos.z + 1)
	var new_pos := Vector3i(pos.x - 1, pos.y - 1, pos.z)
	map_state.player_pos = new_pos

	var start_x: int = pos.x - _MapStateScript.MAP_LEFT
	var start_y: int = pos.y - _MapStateScript.MAP_TOP
	var skip := 0

	if pos.z == UNDERGROUND_FLOOR:
		var j := -1
		for z in range(pos.z, pos.z + UNDERGROUND_RANGE + 1):
			skip = _read_floor(
				buffer, map_state, start_x, start_y, z,
				_MapStateScript.MAP_WIDTH, _MapStateScript.MAP_HEIGHT,
				j, skip
			)
			j -= 1
	elif pos.z > UNDERGROUND_FLOOR and pos.z < 14:
		skip = _read_floor(
			buffer, map_state, start_x, start_y, pos.z + UNDERGROUND_RANGE,
			_MapStateScript.MAP_WIDTH, _MapStateScript.MAP_HEIGHT, -3, skip
		)

# OTC setFloorDescription()
static func _read_floor(
	buffer: StreamPeerBuffer,
	map_state,
	start_x: int,
	start_y: int,
	z: int,
	width: int,
	height: int,
	offset: int,
	skip: int
) -> int:
	_ProtocolDebugScript.map_parse_note_floor(z)
	for nx in range(width):
		if _full_map_parse_active and _parse_failed:
			break
		for ny in range(height):
			if _full_map_parse_active and _parse_failed:
				break
			var tile_pos := Vector3i(start_x + nx + offset, start_y + ny + offset, z)
			if skip == 0:
				skip = read_tile_description(buffer, map_state, tile_pos)
			else:
				map_state.remove_tile(tile_pos)
				skip -= 1
	return skip

# OTC setTileDescription() — protocolgameparse.cpp:3274
static func read_tile_description(buffer: StreamPeerBuffer, map_state, position: Vector3i) -> int:
	map_state.remove_tile(position)
	_DesyncScript.begin_tile(buffer, position)

	if buffer.get_available_bytes() < 2:
		_fail_tile_parse(buffer, position, 0, -1, "buffer curto no inicio do tile")
		return 0

	# Tile vazio no wire: apenas marcador skip (sem things).
	if _ProtocolReaderScript.peek_u16(buffer) >= 0xFF00:
		var empty_skip := buffer.get_u16() & 0xFF
		_ProtocolDebugScript.map_parse_skip(empty_skip)
		return empty_skip

	var tile = _MapTileScript.new()
	var reported_stack_overflow := false
	for stack_pos in range(256):
		if buffer.get_available_bytes() < 2:
			_fail_tile_parse(buffer, position, stack_pos, -1, "buffer curto antes do thing id")
			return 0

		if _ProtocolReaderScript.peek_u16(buffer) >= 0xFF00:
			if not tile.items.is_empty() or not tile.creatures.is_empty():
				map_state.set_tile(position, tile)
				_ProtocolDebugScript.map_parse_tile_added()
			_DesyncScript.end_tile_ok(buffer, position)
			var skip_count := buffer.get_u16() & 0xFF
			_ProtocolDebugScript.map_parse_skip(skip_count)
			return skip_count

		if stack_pos > MAX_THINGS_PER_TILE and not reported_stack_overflow:
			reported_stack_overflow = true
			_report_tile_desync(
				buffer,
				position,
				stack_pos,
				_ProtocolReaderScript.peek_u16(buffer),
				"too many things sem marcador 0xFF (OTC continua ate marker)"
			)

		var thing_id := _ProtocolReaderScript.read_u16(buffer)
		if thing_id == 0:
			_fail_tile_parse(buffer, position, stack_pos, thing_id, "thing id 0")
			return 0

		if not _ThingReaderScript.is_creature_marker(thing_id) and not _ThingReaderScript.is_valid_item_id(thing_id):
			_fail_tile_parse(
				buffer,
				position,
				stack_pos,
				thing_id,
				"thing id %d invalido (provavel desync — bytes 0x%04X)" % [thing_id, thing_id & 0xFFFF]
			)
			return 0

		var thing: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id, true)
		if thing.get("parse_error", false):
			_fail_tile_parse(buffer, position, stack_pos, thing_id, "falha ao ler payload do thing")
			return 0

		if thing.get("kind") == "creature":
			tile.creatures.append(thing)
			thing["tile_pos"] = position
			map_state.register_creature(thing)
			_DesyncScript.note_thing("creature", thing.get("id", thing_id))
			_ProtocolDebugScript.map_parse_thing("creature")
		else:
			tile.items.append(thing)
			_DesyncScript.note_thing("item", thing_id, " count=%d" % thing.get("count", 1))
			_ProtocolDebugScript.map_parse_thing("item")

	return 0

static func _consume_trailing_map_skip(buffer: StreamPeerBuffer) -> void:
	# TFS GetMapDescription() envia skip+0xFF apos o ultimo andar se skip >= 0.
	if buffer.get_available_bytes() >= 2 and _ProtocolReaderScript.peek_u16(buffer) >= 0xFF00:
		var trailing := buffer.get_u16() & 0xFF
		_ProtocolDebugScript.map_parse_skip(trailing)
		print("MapParser: marcador final do mapa consumido (skip=%d)." % trailing)

static func _fail_tile_parse(
	buffer: StreamPeerBuffer,
	position: Vector3i,
	stack_pos: int,
	thing_id: int,
	reason: String
) -> void:
	if _full_map_parse_active:
		_parse_failed = true
	_report_tile_desync(buffer, position, stack_pos, thing_id, reason)

static func _report_tile_desync(
	buffer: StreamPeerBuffer,
	position: Vector3i,
	stack_pos: int,
	thing_id: int,
	reason: String
) -> void:
	_DesyncScript.report(buffer, position, stack_pos, thing_id, reason)
	if not _logged_first_tile_desync:
		_logged_first_tile_desync = true
		push_error(
			"MapParser: primeiro desync em %s stack %d | %s | proximos bytes: %s" % [
				position, stack_pos, reason, _peek_hex(buffer, 24)
			]
		)

static func _peek_hex(buffer: StreamPeerBuffer, count: int) -> String:
	var pos := buffer.get_position()
	var data := buffer.data_array
	var parts: PackedStringArray = []
	for i in range(mini(count, data.size() - pos)):
		parts.append("%02X" % data[pos + i])
	return " ".join(parts) if not parts.is_empty() else "(fim)"
