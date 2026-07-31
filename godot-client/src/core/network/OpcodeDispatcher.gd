class_name TibiaOpcodeDispatcher
extends RefCounted

const _OpcodeReaderScript := preload("res://src/core/network/GameOpcodeReader.gd")

static func dispatch(
	opcode: int,
	buffer: StreamPeerBuffer,
	world,
	move_context: Dictionary = {}
) -> bool:
	if world == null:
		push_error("OpcodeDispatcher: world nulo.")
		return false
	move_context["world"] = world
	return _OpcodeReaderScript.consume_opcode(opcode, buffer, world.get_map_state(), move_context)

static func parse_login(buffer: StreamPeerBuffer) -> Dictionary:
	return _OpcodeReaderScript.parse_login(buffer)

static func parse_full_map(buffer: StreamPeerBuffer) -> Dictionary:
	return _OpcodeReaderScript.parse_full_map(buffer)
