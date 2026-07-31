class_name TibiaMapDesyncDiagnostics
extends RefCounted

# Ative para rastrear o primeiro desync no parse do mapa (0x64).
const ENABLED := true

static var _active := false
static var _player_pos := Vector3i.ZERO
static var _last_good_tile := Vector3i.ZERO
static var _last_good_buffer_pos := 0
static var _tile_buffer_start := 0
static var _current_tile := Vector3i.ZERO
static var _things_on_tile: Array[String] = []
static var _reported := false

static func begin_map(player_pos: Vector3i) -> void:
	if not ENABLED:
		return
	_active = true
	_reported = false
	_player_pos = player_pos
	_last_good_tile = Vector3i(-1, -1, -1)
	_last_good_buffer_pos = 0

static func begin_tile(buffer: StreamPeerBuffer, tile_pos: Vector3i) -> void:
	if not _active:
		return
	_current_tile = tile_pos
	_tile_buffer_start = buffer.get_position()
	_things_on_tile.clear()

static func note_thing(kind: String, thing_id: int, extra: String = "") -> void:
	if not _active:
		return
	var entry := "%s id=%d%s" % [kind, thing_id, extra]
	_things_on_tile.append(entry)

static func end_tile_ok(buffer: StreamPeerBuffer, tile_pos: Vector3i) -> void:
	if not _active:
		return
	_last_good_tile = tile_pos
	_last_good_buffer_pos = buffer.get_position()

static func report(
	buffer: StreamPeerBuffer,
	tile_pos: Vector3i,
	stack_pos: int,
	thing_id: int,
	reason: String
) -> void:
	if not _active or _reported:
		return
	_reported = true
	var tile_hex := _hex_at(buffer, _tile_buffer_start, 48)
	var here_hex := _hex_at(buffer, buffer.get_position(), 32)
	push_error(
		"""MapDesync: %s
  Tile..............%s (player=%s)
  Stack.............%d
  Thing id..........%d (0x%04X)
  Things no tile....%d (%s)
  Buffer tile start.%d
  Buffer now........%d
  Ultimo tile OK....%s @ %d
  Hex @ tile start..%s
  Hex @ erro........%s""" % [
			reason,
			tile_pos,
			_player_pos,
			stack_pos,
			thing_id,
			thing_id & 0xFFFF,
			_things_on_tile.size(),
			", ".join(_things_on_tile) if not _things_on_tile.is_empty() else "(nenhum)",
			_tile_buffer_start,
			buffer.get_position(),
			_last_good_tile,
			_last_good_buffer_pos,
			tile_hex,
			here_hex,
		]
	)

static func _hex_at(buffer: StreamPeerBuffer, pos: int, count: int) -> String:
	var data: PackedByteArray = buffer.data_array
	var parts: PackedStringArray = []
	for i in range(mini(count, data.size() - pos)):
		if pos + i < 0:
			break
		parts.append("%02X" % data[pos + i])
	return " ".join(parts) if not parts.is_empty() else "(vazio)"
