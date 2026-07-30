class_name TibiaMapParser
extends RefCounted

const _MapStateScript := preload("res://src/game/map/MapState.gd")
const _MapTileScript := preload("res://src/game/map/MapTile.gd")
const _ProtocolReaderScript := preload("res://src/core/network/ProtocolReader.gd")
const _ThingReaderScript := preload("res://src/io/ThingReader.gd")

const SEA_FLOOR := 7
const UNDERGROUND_RANGE := 2

static func parse_full_map(buffer: StreamPeerBuffer):
	var map_start := buffer.get_position()
	var map_state = _MapStateScript.new()
	var player_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	map_state.player_pos = player_pos

	var start_x: int = player_pos.x - _MapStateScript.MAP_LEFT
	var start_y: int = player_pos.y - _MapStateScript.MAP_TOP
	read_map_description(
		buffer,
		map_state,
		start_x,
		start_y,
		player_pos.z,
		_MapStateScript.MAP_WIDTH,
		_MapStateScript.MAP_HEIGHT,
	)

	var remaining := buffer.get_available_bytes()
	if remaining > 0:
		var next_b: int = buffer.data_array[buffer.get_position()] if remaining > 0 else -1
		# Apos mapa completo o TFS envia 0x83 (efeito), opcodes de move (0x65-0x68) etc.
		if next_b not in [0x65, 0x66, 0x67, 0x68, 0x6D, 0x78, 0x79, 0x83, 0xA0, 0xA1, 0x82, 0x8D, 0xA2, 0xB4, 0xD2]:
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
	return map_state

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
	while true:
		skip = _read_floor(
			buffer, map_state, start_x, start_y, z, width, height, center_z - z, skip
		)
		if z == end_z:
			break
		z += z_step

# OTC parseUpdateTile() → setTileDescription()
static func read_update_tile(buffer: StreamPeerBuffer, map_state, position: Vector3i) -> void:
	read_tile_description(buffer, map_state, position)

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
	for nx in range(width):
		for ny in range(height):
			var tile_pos := Vector3i(start_x + nx + offset, start_y + ny + offset, z)
			if skip == 0:
				skip = read_tile_description(buffer, map_state, tile_pos)
			else:
				map_state.remove_tile(tile_pos)
				skip -= 1
	return skip

# OTC setTileDescription()
static func read_tile_description(buffer: StreamPeerBuffer, map_state, position: Vector3i) -> int:
	map_state.remove_tile(position)

	if buffer.get_available_bytes() < 2:
		return 0

	if _ProtocolReaderScript.peek_u16(buffer) >= 0xFF00:
		return buffer.get_u16() & 0xFF

	var tile = _MapTileScript.new()
	for stack_pos in range(256):
		if buffer.get_available_bytes() < 2:
			push_warning(
				"MapParser: buffer curto no tile %s (stack %d)." % [position, stack_pos]
			)
			if not tile.items.is_empty() or not tile.creatures.is_empty():
				map_state.set_tile(position, tile)
			return 0

		if _ProtocolReaderScript.peek_u16(buffer) >= 0xFF00:
			var end_marker := buffer.get_u16()
			if not tile.items.is_empty() or not tile.creatures.is_empty():
				map_state.set_tile(position, tile)
			return end_marker & 0xFF

		var thing_id := buffer.get_u16()
		if thing_id == 0:
			push_warning("MapParser: thing id 0 no tile %s (stack %d)." % [position, stack_pos])
			if not tile.items.is_empty() or not tile.creatures.is_empty():
				map_state.set_tile(position, tile)
			return 0

		var thing: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id)
		if thing.get("kind") == "creature":
			tile.creatures.append(thing)
			map_state.register_creature(thing)
		else:
			tile.items.append(thing)

	push_warning("MapParser: tile %s sem marcador 0xFF00 apos 256 things." % position)
	if not tile.items.is_empty() or not tile.creatures.is_empty():
		map_state.set_tile(position, tile)
	return 0

static func _peek_hex(buffer: StreamPeerBuffer, count: int) -> String:
	var pos := buffer.get_position()
	var data := buffer.data_array
	var parts: PackedStringArray = []
	for i in range(mini(count, data.size() - pos)):
		parts.append("%02X" % data[pos + i])
	return " ".join(parts) if not parts.is_empty() else "(fim)"

# Fim do arquivo
