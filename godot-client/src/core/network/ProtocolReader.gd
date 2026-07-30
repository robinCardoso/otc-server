class_name TibiaProtocolReader
extends RefCounted

const _DebugScript := preload("res://src/core/network/ProtocolDebug.gd")

static func peek_u16(buffer: StreamPeerBuffer) -> int:
	if _DebugScript.DEBUG_PROTOCOL:
		return _DebugScript.peek_u16(buffer)
	var pos := buffer.get_position()
	var value := buffer.get_u16()
	buffer.seek(pos)
	return value

static func read_u8(buffer: StreamPeerBuffer) -> int:
	if _DebugScript.DEBUG_PROTOCOL:
		return _DebugScript.read_u8(buffer)
	return buffer.get_u8()

static func read_u16(buffer: StreamPeerBuffer) -> int:
	if _DebugScript.DEBUG_PROTOCOL:
		return _DebugScript.read_u16(buffer)
	return buffer.get_u16()

static func read_u32(buffer: StreamPeerBuffer) -> int:
	if _DebugScript.DEBUG_PROTOCOL:
		return _DebugScript.read_u32(buffer)
	return buffer.get_u32()

static func read_position(buffer: StreamPeerBuffer) -> Vector3i:
	if _DebugScript.DEBUG_PROTOCOL:
		return _DebugScript.read_position(buffer)
	return Vector3i(buffer.get_u16(), buffer.get_u16(), buffer.get_u8())

static func read_string(buffer: StreamPeerBuffer) -> String:
	if buffer.get_available_bytes() < 2:
		return ""
	var size := read_u16(buffer)
	if size <= 0:
		return ""
	var remain := buffer.get_available_bytes()
	if size > remain:
		push_warning(
			"ProtocolReader: string size %d excede buffer (%d bytes restantes)." % [size, remain]
		)
		return ""
	var data := buffer.get_data(size)
	if data[0] != OK:
		return ""
	if _DebugScript.DEBUG_PROTOCOL:
		_DebugScript.trace("String", data[1].get_string_from_utf8(), buffer, buffer.get_position() - size)
	return data[1].get_string_from_utf8()

static func skip_string(buffer: StreamPeerBuffer) -> void:
	if buffer.get_available_bytes() < 2:
		return
	var size := buffer.get_u16()
	var remain := buffer.get_available_bytes()
	if size <= 0:
		return
	if size > remain:
		push_warning(
			"ProtocolReader: skip_string size %d excede buffer (%d bytes restantes)." % [size, remain]
		)
		buffer.seek(buffer.get_position() + remain)
		return
	buffer.seek(buffer.get_position() + size)

# OTC getMappedThing() — pos+stackpos ou creature id (0xFFFF)
static func skip_mapped_thing(buffer: StreamPeerBuffer) -> void:
	var x: int = read_u16(buffer)
	if x != 0xFFFF:
		read_u16(buffer)
		read_u8(buffer)
		read_u8(buffer)
	else:
		read_u32(buffer)
