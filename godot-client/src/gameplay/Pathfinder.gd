class_name TibiaPathfinder
extends RefCounted

## Pathfinding Dijkstra/A* espelhando Map::findPath (map.cpp:852).
## Usa TibiaTileQuery para caminhabilidade — independente de rede/protocolo.

const _TileQueryScript := preload("res://src/gameplay/TileQuery.gd")
const _MapStateScript := preload("res://src/game/map/MapState.gd")

enum Result {
	OK = 0,
	SAME_POSITION = 1,
	IMPOSSIBLE = 2,
	TOO_FAR = 3,
	NO_WAY = 4,
}

enum Flag {
	ALLOW_NOT_SEEN = 1,
	ALLOW_CREATURES = 2,
	ALLOW_NON_PATHABLE = 4,
	ALLOW_NON_WALKABLE = 8,
	IGNORE_CREATURES = 16,
}

const MAX_COMPLEXITY_DEFAULT := 50000
const MAX_AUTOWALK_DIST_860 := 127

static func find_path(
	map_state,
	start_pos: Vector3i,
	goal_pos: Vector3i,
	max_complexity: int = MAX_COMPLEXITY_DEFAULT,
	flags: int = 0,
	player_id: int = 0
) -> Dictionary:
	var empty_dirs: Array[int] = []
	if start_pos == goal_pos:
		return {"directions": empty_dirs, "result": Result.SAME_POSITION}
	if start_pos.z != goal_pos.z:
		return {"directions": empty_dirs, "result": Result.IMPOSSIBLE}

	var goal_tile = map_state.get_tile(goal_pos)
	if goal_tile != null:
		if not _TileQueryScript.is_walkable(
			goal_tile, (flags & Flag.IGNORE_CREATURES) != 0, player_id
		) and (flags & Flag.ALLOW_NON_WALKABLE) == 0:
			return {"directions": empty_dirs, "result": Result.NO_WAY}

	var nodes: Dictionary = {}
	var open: Array = []
	var found_node: Dictionary = {}

	var start_node := _make_node(start_pos)
	nodes[_pos_key(start_pos)] = start_node
	open.append({"node": start_node, "priority": 0.0})
	var current: Dictionary = start_node

	while not current.is_empty():
		if nodes.size() > max_complexity:
			return {"directions": empty_dirs, "result": Result.TOO_FAR}

		if current.pos == goal_pos:
			if found_node.is_empty() or current.cost < found_node.cost:
				found_node = current

		if not found_node.is_empty() and current.total_cost >= found_node.cost:
			break

		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var neighbor_pos := Vector3i(current.pos.x + dx, current.pos.y + dy, current.pos.z)
				if neighbor_pos.x < 0 or neighbor_pos.y < 0:
					continue

				var was_seen := _TileQueryScript.is_tile_known(map_state, neighbor_pos)
				var neighbor_tile = map_state.get_tile(neighbor_pos)
				var has_creature := false
				var not_walkable := true
				var not_pathable := true
				var speed := 100

				if was_seen:
					if neighbor_tile != null:
						has_creature = _TileQueryScript.has_blocking_creature(neighbor_tile, player_id)
						not_walkable = not _TileQueryScript.is_walkable(
							neighbor_tile, (flags & Flag.IGNORE_CREATURES) != 0, player_id
						)
						not_pathable = not _TileQueryScript.is_pathable(neighbor_tile)
						speed = _TileQueryScript.get_ground_speed(neighbor_tile)

				if neighbor_pos != goal_pos:
					if (flags & Flag.ALLOW_NOT_SEEN) == 0 and not was_seen:
						continue
					if was_seen:
						if (flags & Flag.ALLOW_CREATURES) == 0 and has_creature:
							continue
						if (flags & Flag.ALLOW_NON_PATHABLE) == 0 and not_pathable:
							continue
						if (flags & Flag.ALLOW_NON_WALKABLE) == 0 and not_walkable:
							continue
				else:
					if (flags & Flag.ALLOW_NOT_SEEN) == 0 and not was_seen:
						continue
					if was_seen and (flags & Flag.ALLOW_NON_WALKABLE) == 0 and not_walkable:
						continue

				var walk_dir := _direction_from_delta(dx, dy)
				var walk_factor := 3.0 if walk_dir >= 4 else 1.0
				var cost: float = current.cost + (float(speed) * walk_factor) / 100.0

				var key := _pos_key(neighbor_pos)
				var neighbor_node: Dictionary
				if nodes.has(key):
					neighbor_node = nodes[key]
					if neighbor_node.cost <= cost:
						continue
				else:
					neighbor_node = _make_node(neighbor_pos)
					nodes[key] = neighbor_node

				neighbor_node.prev = current
				neighbor_node.cost = cost
				neighbor_node.total_cost = cost + _distance(neighbor_pos, goal_pos)
				neighbor_node.dir = walk_dir
				open.append({"node": neighbor_node, "priority": neighbor_node.total_cost})

		if open.is_empty():
			current = {}
		else:
			open.sort_custom(func(a, b): return a.priority < b.priority)
			current = open.pop_front().node

	if found_node.is_empty():
		return {"directions": empty_dirs, "result": Result.NO_WAY}

	var directions: Array[int] = []
	var walk_node: Dictionary = found_node
	while not walk_node.is_empty() and walk_node.has("prev") and not walk_node.prev.is_empty():
		directions.append(walk_node.dir)
		walk_node = walk_node.prev
	directions.reverse()

	if directions.size() > MAX_AUTOWALK_DIST_860:
		directions.resize(MAX_AUTOWALK_DIST_860)

	return {"directions": directions, "result": Result.OK, "start": start_pos, "goal": goal_pos}

static func translate_position(pos: Vector3i, direction: int) -> Vector3i:
	match direction:
		0: return Vector3i(pos.x, pos.y - 1, pos.z)
		1: return Vector3i(pos.x + 1, pos.y, pos.z)
		2: return Vector3i(pos.x, pos.y + 1, pos.z)
		3: return Vector3i(pos.x - 1, pos.y, pos.z)
		4: return Vector3i(pos.x + 1, pos.y - 1, pos.z)
		5: return Vector3i(pos.x + 1, pos.y + 1, pos.z)
		6: return Vector3i(pos.x - 1, pos.y + 1, pos.z)
		7: return Vector3i(pos.x - 1, pos.y - 1, pos.z)
	return pos

static func _make_node(pos: Vector3i) -> Dictionary:
	return {"pos": pos, "cost": 0.0, "total_cost": 0.0, "prev": {}, "dir": -1}

static func _pos_key(pos: Vector3i) -> String:
	return "%d,%d,%d" % [pos.x, pos.y, pos.z]

static func _distance(a: Vector3i, b: Vector3i) -> float:
	var dx := float(a.x - b.x)
	var dy := float(a.y - b.y)
	return sqrt(dx * dx + dy * dy)

static func _direction_from_delta(dx: int, dy: int) -> int:
	if dx == 0 and dy < 0:
		return 0
	if dx > 0 and dy == 0:
		return 1
	if dx == 0 and dy > 0:
		return 2
	if dx < 0 and dy == 0:
		return 3
	if dx > 0 and dy < 0:
		return 4
	if dx > 0 and dy > 0:
		return 5
	if dx < 0 and dy > 0:
		return 6
	if dx < 0 and dy < 0:
		return 7
	return -1
