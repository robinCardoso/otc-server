extends RefCounted

const _MapStateScript := preload("res://src/game/map/MapState.gd")
const _DatReaderScript := preload("res://src/io/DatReader.gd")
const _ThingSpriteFactoryScript := preload("res://src/game/map/ThingSpriteFactory.gd")

const MAX_Z := 15
const SEA_FLOOR := 7
const UNDERGROUND_FLOOR := 8
const AWARE_UNDERGROUND_FLOOR_RANGE := 2

static func calc_first_visible_floor(map_state, camera_pos: Vector3i, for_fading: bool = false) -> int:
	var first_floor := 0
	if camera_pos.z > SEA_FLOOR:
		first_floor = maxi(
			camera_pos.z - AWARE_UNDERGROUND_FLOOR_RANGE,
			UNDERGROUND_FLOOR
		)

	if for_fading or camera_pos.z <= 0:
		return clampi(first_floor, 0, MAX_Z)

	for ix in range(-1, 2):
		for iy in range(-1, 2):
			if first_floor >= camera_pos.z:
				break
			var check_pos := Vector3i(camera_pos.x + ix, camera_pos.y + iy, camera_pos.z)
			if not _should_check_occlusion(ix, iy, map_state, check_pos):
				continue

			var upper_pos := check_pos
			var covered_pos := check_pos
			var look_possible := is_look_possible(map_state, check_pos)
			while covered_pos.z > 0 and upper_pos.z >= first_floor:
				upper_pos.z -= 1
				covered_pos.x += 1
				covered_pos.y += 1
				covered_pos.z -= 1

				var upper_tile = map_state.get_tile(upper_pos)
				if upper_tile != null and limits_floors_view(upper_tile, not look_possible):
					first_floor = upper_pos.z + 1
					break

				var covered_tile = map_state.get_tile(covered_pos)
				if covered_tile != null and limits_floors_view(covered_tile, look_possible):
					first_floor = covered_pos.z + 1
					break

	return clampi(first_floor, 0, MAX_Z)

static func calc_last_visible_floor(camera_pos: Vector3i) -> int:
	if camera_pos.z > SEA_FLOOR:
		return clampi(camera_pos.z + AWARE_UNDERGROUND_FLOOR_RANGE, 0, MAX_Z)
	return SEA_FLOOR

static func build_visible_tile_positions(
	camera_pos: Vector3i,
	first_floor: int,
	last_floor: int
) -> Dictionary:
	var by_floor: Dictionary = {}
	for floor_z in range(0, MAX_Z + 1):
		by_floor[floor_z] = []

	var draw_w := _MapStateScript.MAP_WIDTH
	var draw_h := _MapStateScript.MAP_HEIGHT
	var num_diagonals := draw_w + draw_h - 1

	for floor_z in range(last_floor, first_floor - 1, -1):
		var z_lift := camera_pos.z - floor_z
		for diagonal in range(num_diagonals):
			var advance := maxi(diagonal - draw_h, 0)
			var iy := diagonal - advance
			var ix := advance
			while iy >= 0 and ix < draw_w:
				var tile_pos := Vector3i(
					camera_pos.x - _MapStateScript.MAP_LEFT + ix + z_lift,
					camera_pos.y - _MapStateScript.MAP_TOP + iy + z_lift,
					floor_z
				)
				by_floor[floor_z].append(tile_pos)
				iy -= 1
				ix += 1

	return by_floor

static func is_look_possible(map_state, tile_pos: Vector3i) -> bool:
	var tile = map_state.get_tile(tile_pos)
	if tile == null:
		return true
	for item in tile.items:
		var thing = _thing_type(item.get("id", 0))
		if thing != null and thing.blocks_projectile():
			return false
	return true

static func limits_floors_view(tile, is_free_view: bool) -> bool:
	if tile == null or tile.items.is_empty():
		return false
	var thing = _thing_type(tile.items[0].get("id", 0))
	if thing == null or thing.is_dont_hide():
		return false
	if is_free_view:
		return thing.is_ground() or thing.is_on_bottom()
	return thing.is_ground() or (thing.is_on_bottom() and thing.blocks_projectile())

static func _should_check_occlusion(ix: int, iy: int, map_state, check_pos: Vector3i) -> bool:
	if ix == 0 and iy == 0:
		return true
	if absi(ix) == absi(iy):
		return false
	return is_look_possible(map_state, check_pos)

static func _thing_type(item_id: int):
	if item_id <= 0:
		return null
	return _ThingSpriteFactoryScript.get_thing(item_id, _DatReaderScript.ThingCategory.ITEM)
