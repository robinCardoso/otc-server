class_name TibiaInventoryManager
extends RefCounted

const _ThingReaderScript := preload("res://src/io/ThingReader.gd")

var _map = null

func _init(map_manager) -> void:
	_map = map_manager

func add_item(buffer: StreamPeerBuffer) -> void:
	var slot := buffer.get_u8()
	var thing_id := buffer.get_u16()
	var item: Dictionary = _ThingReaderScript.read_thing(buffer, thing_id)
	_map.state.set_inventory_item(slot, item)

func remove_item(buffer: StreamPeerBuffer) -> void:
	var slot := buffer.get_u8()
	_map.state.set_inventory_item(slot, {})

func get_item(slot: int) -> Dictionary:
	return _map.state.get_inventory_item(slot)

func get_all() -> Dictionary:
	return _map.state.inventory
