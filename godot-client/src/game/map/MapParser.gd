class_name TibiaMapParser
extends RefCounted

const _MapStateScript := preload("res://src/game/map/MapState.gd")
const _MapTileScript := preload("res://src/game/map/MapTile.gd")
const _ProtocolReaderScript := preload("res://src/core/network/ProtocolReader.gd")
const _ProtocolDebugScript := preload("res://src/core/network/ProtocolDebug.gd")
const _ThingReaderScript := preload("res://src/io/ThingReader.gd")

const SEA_FLOOR := 7
const UNDERGROUND_FLOOR := 8
const UNDERGROUND_RANGE := 2
# TFS GetTileDescription() envia no maximo 10 things por tile (server/src/protocolgame.cpp).
const MAX_THINGS_PER_TILE := 10

static func parse_full_map(buffer: StreamPeerBuffer):
	_ProtocolDebugScript.begin_opcode(0x64, buffer)
	var map_start := buffer.get_position()
	var map_state = _MapStateScript.new()
	var player_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	map_state.player_pos = player_pos

	var start_x: int = player_pos.x - _MapStateScript.MAP_LEFT
	var start_y: int = player_pos.y - _MapStateScript.MAP_TOP
	_ProtocolDebugScript.map_parse_begin(0x64, buffer, player_pos.z)
	var skip_final: int = read_map_description(
		buffer,
		map_state,
		start_x,
		start_y,
		player_pos.z,
		_MapStateScript.MAP_WIDTH,
		_MapStateScript.MAP_HEIGHT,
	)
	_consume_map_trailer(buffer)
	_ProtocolDebugScript.map_parse_end(buffer, skip_final)

	var remaining := buffer.get_available_bytes()
	if remaining > 0:
		var next_b: int = buffer.data_array[buffer.get_position()] if remaining > 0 else -1
		# Apos mapa: inventario (0x78/0x79), stats (0xA0), luz (0x82), etc.
		if next_b not in [0x65, 0x66, 0x67, 0x68, 0x6D, 0x78, 0x79, 0x83, 0xA0, 0xA1, 0x82, 0x8D, 0xA2, 0xA7, 0xB4, 0xD2, 0xBE, 0xBF, 0x0A, 0xB5, 0x6E, 0x6F, 0x70, 0x71, 0x72]:
			push_warning(
				"MapParser: %d bytes apos mapa (opcode esperado, got 0x%02X). Hex: %s" % [
					remaining, next_b, _peek_hex(buffer, 12)
				]
			)

	var consumed := buffer.get_position() - map_start
	print(
		"MapParser: Mapa parseado em %s com %d tiles (%d bytes). Proximos bytes: %s" % [
			map_state.player_pos,
			map_state.tile_count(),
			consumed,
			_peek_hex(buffer, 8),
		]
	)
	_ProtocolDebugScript.end_opcode(0x64, buffer)
	return map_state

# OTC setMapDescription()
# Usa MAP_WIDTH/HEIGHT de MapState (25×20 no protocolo 860) — ver comentário em MapState.gd.
static func read_map_description(
	buffer: StreamPeerBuffer,
	map_state,
	start_x: int,
	start_y: int,
	center_z: int,
	width: int,
	height: int
) -> int:
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

	var skip := 0  # OTC setMapDescription() — skip 0 le tile; >0 pula celulas.
	var z := start_z
	_ProtocolDebugScript.map_parse_note_floor(center_z)
	while true:
		skip = _read_floor(
			buffer, map_state, start_x, start_y, z, width, height, center_z - z, skip
		)
		if z == end_z:
			break
		z += z_step
	_consume_pending_skip(buffer, skip)
	return skip

# OTC parseUpdateTile() → setTileDescription(); TFS acrescenta 0x00/0xFF após as things.
static func read_update_tile(buffer: StreamPeerBuffer, map_state, position: Vector3i) -> void:
	read_tile_description(buffer, map_state, position)

# OTC parseFloorChangeUp() — andares extras após subir escada (860 sem posição no pacote).
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
	_consume_pending_skip(buffer, skip)

# OTC parseFloorChangeDown()
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
	_consume_pending_skip(buffer, skip)

static func _consume_pending_skip(buffer: StreamPeerBuffer, skip: int) -> void:
	if skip < 0 or buffer.get_available_bytes() < 2:
		return
	if _ProtocolReaderScript.peek_u16(buffer) >= 0xFF00:
		buffer.get_u16()

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
		for ny in range(height):
			var tile_pos := Vector3i(start_x + nx + offset, start_y + ny + offset, z)
			if skip == 0:
				skip = read_tile_description(buffer, map_state, tile_pos)
			else:
				map_state.remove_tile(tile_pos)
				skip -= 1
	return skip

# OTC setTileDescription() — lê things até marcador u16 >= 0xFF00.
static func read_tile_description(buffer: StreamPeerBuffer, map_state, position: Vector3i) -> int:
	map_state.remove_tile(position)

	if buffer.get_available_bytes() < 2:
		return 0

	if _ProtocolReaderScript.peek_u16(buffer) >= 0xFF00:
		var skip_count := buffer.get_u16() & 0xFF
		_ProtocolDebugScript.map_parse_skip(skip_count)
		return skip_count

	var tile = _MapTileScript.new()
	for stack_pos in range(256):
		if buffer.get_available_bytes() < 2:
			push_warning(
				"MapParser: buffer curto no tile %s (stack %d)." % [position, stack_pos]
			)
			break

		if _ProtocolReaderScript.peek_u16(buffer) >= 0xFF00:
			if not tile.items.is_empty() or not tile.creatures.is_empty():
				map_state.set_tile(position, tile)
				_ProtocolDebugScript.map_parse_tile_added()
			var skip_count := buffer.get_u16() & 0xFF
			_ProtocolDebugScript.map_parse_skip(skip_count)
			return skip_count

		if stack_pos > MAX_THINGS_PER_TILE:
			push_warning(
				"MapParser: too many things em %s (stack %d)." % [position, stack_pos]
			)

		var thing_id := _ProtocolReaderScript.read_u16(buffer)
		if thing_id == 0:
			if stack_pos > 0 and _ProtocolReaderScript.peek_u16(buffer) >= 0xFF00:
				if not tile.items.is_empty() or not tile.creatures.is_empty():
					map_state.set_tile(position, tile)
					_ProtocolDebugScript.map_parse_tile_added()
				var skip_count := buffer.get_u16() & 0xFF
				_ProtocolDebugScript.map_parse_skip(skip_count)
				return skip_count
			push_warning("MapParser: thing id 0 no tile %s (stack %d)." % [position, stack_pos])
			break

		var thing: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id)
		if thing.get("kind") == "creature":
			tile.creatures.append(thing)
			map_state.register_creature(thing)
			_ProtocolDebugScript.map_parse_thing("creature")
		else:
			tile.items.append(thing)
			_ProtocolDebugScript.map_parse_thing("item")

	if not tile.items.is_empty() or not tile.creatures.is_empty():
		map_state.set_tile(position, tile)
		_ProtocolDebugScript.map_parse_tile_added()
	return 0

static func _peek_hex(buffer: StreamPeerBuffer, count: int) -> String:
	var pos := buffer.get_position()
	var data := buffer.data_array
	var parts: PackedStringArray = []
	for i in range(mini(count, data.size() - pos)):
		parts.append("%02X" % data[pos + i])
	return " ".join(parts) if not parts.is_empty() else "(fim)"

# TFS GetMapDescription() pode encerrar com skip byte + 0xFF apos o ultimo andar.
static func _consume_map_trailer(buffer: StreamPeerBuffer) -> void:
	while buffer.get_available_bytes() >= 2:
		if _ProtocolReaderScript.peek_u16(buffer) >= 0xFF00:
			buffer.get_u16()
		else:
			break

# Fim do arquivo
