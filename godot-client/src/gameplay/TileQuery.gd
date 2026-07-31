class_name TibiaTileQuery
extends RefCounted

## Consultas de caminhabilidade sobre TibiaMapState (espelha tile.cpp / map.cpp).
## Não depende de world managers — recebe map_state diretamente.

const _ThingSpriteFactoryScript := preload("res://src/game/map/ThingSpriteFactory.gd")
const _DatReaderScript := preload("res://src/io/DatReader.gd")

# OTC DatOpts (const.h)
const ATTR_BLOCK_WALK := 12
const ATTR_BLOCK_PATHFIND := 15

const DEFAULT_GROUND_SPEED := 150

static func get_ground_speed(tile) -> int:
	if tile == null or tile.items.is_empty():
		return DEFAULT_GROUND_SPEED
	for item in tile.items:
		var thing = _item_thing(item.get("id", 0))
		if thing == null:
			continue
		var speed: int = thing.get_ground_speed()
		if speed > 0:
			return speed
	return DEFAULT_GROUND_SPEED

static func has_ground(tile) -> bool:
	if tile == null or tile.items.is_empty():
		return false
	for item in tile.items:
		var thing = _item_thing(item.get("id", 0))
		if thing != null and thing.is_ground():
			return true
	return false

static func is_walkable(tile, ignore_creatures: bool = false, player_id: int = 0) -> bool:
	if not has_ground(tile):
		return false
	for item in tile.items:
		var thing = _item_thing(item.get("id", 0))
		if thing != null and thing.flags.has(ATTR_BLOCK_WALK):
			return false
	if not ignore_creatures:
		for creature in tile.creatures:
			var cid: int = creature.get("id", 0)
			if cid > 0 and cid != player_id:
				return false
	return true

static func is_pathable(tile) -> bool:
	if tile == null:
		return true
	for item in tile.items:
		var thing = _item_thing(item.get("id", 0))
		if thing != null and thing.flags.has(ATTR_BLOCK_PATHFIND):
			return false
	return true

static func has_blocking_creature(tile, player_id: int = 0) -> bool:
	if tile == null:
		return false
	for creature in tile.creatures:
		var cid: int = creature.get("id", 0)
		if cid > 0 and cid != player_id:
			return true
	return false

static func is_tile_known(map_state, pos: Vector3i) -> bool:
	return map_state.get_tile(pos) != null

static func _item_thing(item_id: int):
	if item_id <= 0:
		return null
	return _ThingSpriteFactoryScript.get_thing(item_id, _DatReaderScript.ThingCategory.ITEM)
