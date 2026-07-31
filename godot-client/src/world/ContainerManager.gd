class_name TibiaContainerManager
extends RefCounted

const _ThingReaderScript := preload("res://src/io/ThingReader.gd")
const _ProtocolReaderScript := preload("res://src/core/network/ProtocolReader.gd")

var _map = null

func _init(map_manager) -> void:
	_map = map_manager

func open(buffer: StreamPeerBuffer) -> int:
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
	_map.state.open_container(container_id, {
		"id": container_id,
		"item": container_item,
		"name": container_name,
		"capacity": capacity,
		"has_parent": has_parent,
		"items": items,
	})
	return container_id

func close(buffer: StreamPeerBuffer) -> int:
	var container_id := buffer.get_u8()
	_map.state.close_container(container_id)
	return container_id

func add_item(buffer: StreamPeerBuffer) -> int:
	var container_id := buffer.get_u8()
	var thing_id := buffer.get_u16()
	var item: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id)
	var container: Dictionary = _map.state.get_container(container_id)
	if container.is_empty():
		return -1
	var items: Array = container.get("items", [])
	items.append(item)
	container["items"] = items
	return container_id

func update_item(buffer: StreamPeerBuffer) -> int:
	var container_id := buffer.get_u8()
	var slot := buffer.get_u8()
	var thing_id := buffer.get_u16()
	var item: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id)
	var container: Dictionary = _map.state.get_container(container_id)
	if container.is_empty():
		return -1
	var items: Array = container.get("items", [])
	while items.size() <= slot:
		items.append({})
	items[slot] = item
	container["items"] = items
	return container_id

func remove_item(buffer: StreamPeerBuffer) -> int:
	var container_id := buffer.get_u8()
	var slot := buffer.get_u8()
	var container: Dictionary = _map.state.get_container(container_id)
	if container.is_empty():
		return -1
	var items: Array = container.get("items", [])
	if slot >= 0 and slot < items.size():
		items.remove_at(slot)
	container["items"] = items
	return container_id

func get_all() -> Dictionary:
	return _map.state.containers
