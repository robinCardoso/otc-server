class_name TibiaMapManager
extends RefCounted

const _MapStateScript := preload("res://src/game/map/MapState.gd")
const _MapTileScript := preload("res://src/game/map/MapTile.gd")

var state  # TibiaMapState

func _init(initial_state = null) -> void:
	state = initial_state if initial_state != null else _MapStateScript.new()

func adopt_state(new_state) -> void:
	state = new_state

func set_player_pos(pos: Vector3i) -> void:
	state.player_pos = pos

func get_player_pos() -> Vector3i:
	return state.player_pos

func get_tile(pos: Vector3i):
	return state.get_tile(pos)

func get_or_create_tile(pos: Vector3i):
	return state.get_or_create_tile(pos)

func set_tile(pos: Vector3i, tile) -> void:
	state.set_tile(pos, tile)

func remove_tile(pos: Vector3i) -> void:
	state.remove_tile(pos)

func tile_count() -> int:
	return state.tile_count()

func add_thing_to_tile(position: Vector3i, thing: Dictionary) -> void:
	var tile = get_or_create_tile(position)
	if thing.get("kind") == "creature":
		thing["tile_pos"] = position
		tile.creatures.append(thing)
		state.register_creature(thing)
	else:
		tile.items.append(thing)

# Opcode 0x6B — OTC parseTileTransformThing (getMappedThing + getThing)
func transform_thing(mapped: Dictionary, new_thing: Dictionary) -> void:
	var pos: Vector3i
	var stack_pos: int = -1
	var creature_id: int = mapped.get("creature_id", 0)

	if creature_id > 0:
		var creature: Dictionary = state.find_creature_by_id(creature_id)
		if creature.is_empty():
			return
		pos = creature.get("tile_pos", Vector3i.ZERO)
		var tile = get_tile(pos)
		if tile == null:
			return
		for i in range(tile.creatures.size()):
			if tile.creatures[i].get("id", 0) == creature_id:
				stack_pos = i
				break
		if stack_pos < 0:
			return
	else:
		pos = mapped.get("pos", Vector3i.ZERO)
		stack_pos = mapped.get("stack_pos", 0)

	remove_thing_at(pos, stack_pos)
	add_thing_to_tile(pos, new_thing)

func remove_thing_at(position: Vector3i, stack_pos: int) -> void:
	var tile = get_tile(position)
	if tile == null:
		return
	if stack_pos < tile.creatures.size():
		var creature: Dictionary = tile.creatures[stack_pos]
		tile.creatures.remove_at(stack_pos)
		if creature.get("id", 0) > 0:
			state.creature_index.erase(creature["id"])
	elif stack_pos < tile.creatures.size() + tile.items.size():
		var item_idx: int = stack_pos - tile.creatures.size()
		tile.items.remove_at(item_idx)
	if tile.creatures.is_empty() and tile.items.is_empty():
		remove_tile(position)
