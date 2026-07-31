class_name TibiaGameWorld
extends RefCounted

const _MapManagerScript := preload("res://src/world/MapManager.gd")
const _CreatureManagerScript := preload("res://src/world/CreatureManager.gd")
const _EffectManagerScript := preload("res://src/world/EffectManager.gd")
const _InventoryManagerScript := preload("res://src/world/InventoryManager.gd")
const _ContainerManagerScript := preload("res://src/world/ContainerManager.gd")
const _PlayerControllerScript := preload("res://src/gameplay/PlayerController.gd")

var map = null
var creatures = null
var effects = null
var inventory = null
var containers = null
var player = null

func _init(initial_map_state = null) -> void:
	map = _MapManagerScript.new(initial_map_state)
	creatures = _CreatureManagerScript.new(map)
	effects = _EffectManagerScript.new(map)
	inventory = _InventoryManagerScript.new(map)
	containers = _ContainerManagerScript.new(map)
	player = _PlayerControllerScript.new(map, creatures)

func get_map_state():
	return map.state

func adopt_map_state(new_state) -> void:
	map.adopt_state(new_state)

func bind_login(login_data: Dictionary) -> void:
	player.bind_login(login_data)

func can_walk() -> bool:
	return player.can_walk()

func after_map_parsed() -> void:
	_index_creatures_from_tiles()

func _index_creatures_from_tiles() -> void:
	for tile_key in map.state.tiles:
		var tile = map.state.tiles[tile_key]
		var parts: PackedStringArray = String(tile_key).split(",")
		if parts.size() != 3:
			continue
		var tile_pos := Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
		for creature in tile.creatures:
			creatures.register(creature, tile_pos)
