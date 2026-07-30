class_name TibiaMapState
extends RefCounted

const MAP_WIDTH := 18
const MAP_HEIGHT := 14
const MAP_LEFT := 8
const MAP_RIGHT := 9
const MAP_TOP := 6
const MAP_BOTTOM := 7
const _MapTileScript := preload("res://src/game/map/MapTile.gd")

var player_pos := Vector3i.ZERO
var tiles: Dictionary = {}

# Efeitos voláteis não ligados a um tile fixo
var active_missiles: Array[Dictionary] = []       # Opcode 0x85
var active_animated_texts: Array[Dictionary] = [] # Opcode 0x84

# Índice rápido creature_id → creature Dictionary (O(1) lookup)
var creature_index: Dictionary = {}  # { int: Dictionary }

func register_creature(creature: Dictionary) -> void:
	var cid: int = creature.get("id", 0)
	if cid > 0:
		creature_index[cid] = creature

func find_creature_by_id(creature_id: int) -> Dictionary:
	return creature_index.get(creature_id, {})

func set_tile(position: Vector3i, tile) -> void:
	tiles[_tile_key(position)] = tile

func remove_tile(position: Vector3i) -> void:
	tiles.erase(_tile_key(position))

func get_tile(position: Vector3i):
	return tiles.get(_tile_key(position))

func get_tile_at(x: int, y: int, z: int):
	return get_tile(Vector3i(x, y, z))

func get_or_create_tile(position: Vector3i):
	var tile = get_tile(position)
	if tile == null:
		tile = _MapTileScript.new()
		set_tile(position, tile)
	return tile

func tile_count() -> int:
	return tiles.size()

static func _tile_key(position: Vector3i) -> String:
	return "%d,%d,%d" % [position.x, position.y, position.z]
