class_name TibiaProtocolReader
extends RefCounted

static func peek_u16(buffer: StreamPeerBuffer) -> int:
	var pos := buffer.get_position()
	var value := buffer.get_u16()
	buffer.seek(pos)
	return value

static func read_position(buffer: StreamPeerBuffer) -> Vector3i:
	return Vector3i(buffer.get_u16(), buffer.get_u16(), buffer.get_u8())

static func read_string(buffer: StreamPeerBuffer) -> String:
	var size := buffer.get_u16()
	if size <= 0:
		return ""
	var data := buffer.get_data(size)
	if data[0] != OK:
		return ""
	return data[1].get_string_from_utf8()

static func skip_string(buffer: StreamPeerBuffer) -> void:
	var size := buffer.get_u16()
	if size > 0:
		buffer.seek(buffer.get_position() + size)

# OTC getMappedThing() — pos+stackpos ou creature id (0xFFFF)
static func skip_mapped_thing(buffer: StreamPeerBuffer) -> void:
	var x: int = buffer.get_u16()
	if x != 0xFFFF:
		buffer.get_u16()
		buffer.get_u8()
		buffer.get_u8()
	else:
		buffer.get_u32()
