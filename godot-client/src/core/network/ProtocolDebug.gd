class_name TibiaProtocolDebug
extends RefCounted

# Fase 1 — ferramentas de depuração do protocolo (sem mudar arquitetura).
# Ative apenas uma flag por vez se o log ficar muito verboso.

const DEBUG_PROTOCOL := false
const DEBUG_MAP_PARSE := false

const _MAP_OPCODES: Array[int] = [0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0xBE, 0xBF]

static var _opcode_name: String = ""
static var _map_stats: Dictionary = {}

# ---------------------------------------------------------------------------
# DEBUG_PROTOCOL — rastreio byte a byte (estilo OTClient)
# ---------------------------------------------------------------------------

static func begin_opcode(opcode: int, buffer: StreamPeerBuffer) -> void:
	if not DEBUG_PROTOCOL:
		return
	_opcode_name = "0x%02X" % (opcode & 0xFF)
	var pos := buffer.get_position()
	var remain := buffer.get_available_bytes()
	print(
		"> Opcode %s\nBytes antes........%d\nBytes restantes....%d\n-----------------" % [
			_opcode_name, pos, remain
		]
	)

static func end_opcode(opcode: int, buffer: StreamPeerBuffer) -> void:
	if not DEBUG_PROTOCOL:
		return
	print(
		"< Opcode 0x%02X finalizado | pos=%d | restantes=%d\n" % [
			opcode & 0xFF, buffer.get_position(), buffer.get_available_bytes()
		]
	)

static func trace(label: String, value: Variant, buffer: StreamPeerBuffer, pos_before: int) -> void:
	if not DEBUG_PROTOCOL:
		return
	print(
		"Read %-14s %s\nRead Position.... %d" % [
			label, str(value), buffer.get_position()
		]
	)

static func trace_peek(label: String, value: Variant, buffer: StreamPeerBuffer) -> void:
	if not DEBUG_PROTOCOL:
		return
	print(
		"Peek %-14s %s\nRead Position.... %d (sem avancar)" % [
			label, str(value), buffer.get_position()
		]
	)

static func read_u8(buffer: StreamPeerBuffer) -> int:
	var pos := buffer.get_position()
	var value := buffer.get_u8()
	trace("U8", value, buffer, pos)
	return value

static func read_u16(buffer: StreamPeerBuffer) -> int:
	var pos := buffer.get_position()
	var value := buffer.get_u16()
	trace("U16", value, buffer, pos)
	return value

static func read_u32(buffer: StreamPeerBuffer) -> int:
	var pos := buffer.get_position()
	var value := buffer.get_u32()
	trace("U32", value, buffer, pos)
	return value

static func read_position(buffer: StreamPeerBuffer) -> Vector3i:
	var pos := buffer.get_position()
	var value := Vector3i(buffer.get_u16(), buffer.get_u16(), buffer.get_u8())
	trace("Position", value, buffer, pos)
	return value

static func peek_u16(buffer: StreamPeerBuffer) -> int:
	var pos := buffer.get_position()
	var value := buffer.get_u16()
	buffer.seek(pos)
	trace_peek("U16", value, buffer)
	return value

# ---------------------------------------------------------------------------
# DEBUG_MAP_PARSE — profiler de parse de mapa
# ---------------------------------------------------------------------------

static func map_parse_begin(opcode: int, buffer: StreamPeerBuffer, floor_z: int = -1) -> void:
	if not DEBUG_MAP_PARSE:
		return
	_map_stats = {
		"opcode": opcode & 0xFF,
		"pos_before": buffer.get_position(),
		"time_start_us": Time.get_ticks_usec(),
		"tiles": 0,
		"things": 0,
		"creatures": 0,
		"skips": 0,
		"floor": floor_z,
	}

static func map_parse_note_floor(floor_z: int) -> void:
	if not DEBUG_MAP_PARSE or _map_stats.is_empty():
		return
	_map_stats["floor"] = floor_z

static func map_parse_tile_added() -> void:
	if not DEBUG_MAP_PARSE or _map_stats.is_empty():
		return
	_map_stats["tiles"] += 1

static func map_parse_thing(kind: String) -> void:
	if not DEBUG_MAP_PARSE or _map_stats.is_empty():
		return
	_map_stats["things"] += 1
	if kind == "creature":
		_map_stats["creatures"] += 1

static func map_parse_skip(count: int) -> void:
	if not DEBUG_MAP_PARSE or _map_stats.is_empty():
		return
	_map_stats["skips"] += 1
	if DEBUG_PROTOCOL:
		print("MapParse skip marker = %d" % count)

static func map_parse_end(buffer: StreamPeerBuffer, skip_final: int = 0) -> void:
	if not DEBUG_MAP_PARSE or _map_stats.is_empty():
		return
	var pos_after := buffer.get_position()
	var elapsed_ms := float(Time.get_ticks_usec() - int(_map_stats.time_start_us)) / 1000.0
	print(
		"""--- MapParse Profiler ---
Opcode.............0x%02X
Bytes antes........%d
Bytes depois.......%d
Consumidos.........%d
Tiles..............%d
Things.............%d
Creatures..........%d
Skips..............%d
Floor..............%d
Skip final.........%d
Tempo..............%.2f ms
-------------------------""" % [
			_map_stats.opcode,
			_map_stats.pos_before,
			pos_after,
			pos_after - _map_stats.pos_before,
			_map_stats.tiles,
			_map_stats.things,
			_map_stats.creatures,
			_map_stats.skips,
			_map_stats.get("floor", -1),
			skip_final,
			elapsed_ms,
		]
	)
	_map_stats.clear()

static func is_map_opcode(opcode: int) -> bool:
	return (opcode & 0xFF) in _MAP_OPCODES
