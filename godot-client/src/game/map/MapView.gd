extends Node2D

const _MapStateScript := preload("res://src/game/map/MapState.gd")
const _MapVisibilityScript := preload("res://src/game/map/MapVisibility.gd")
const _ThingSpriteFactoryScript := preload("res://src/game/map/ThingSpriteFactory.gd")
const _DatReaderScript := preload("res://src/io/DatReader.gd")
const CreatureWalkerScript := preload("res://src/game/creature/CreatureWalker.gd")
const EffectAnimatorScript := preload("res://src/game/effects/EffectAnimator.gd")

const TILE_SIZE := 32
const MAX_ELEVATION := 24
const OFFSET_FACTOR := 1

var _drawables: Array[Dictionary] = []
var _map_state = null
var _player_id: int = 0
var _camera_pos := Vector3i.ZERO
var _top_corrections: Dictionary = {}
var _tile_render_states: Dictionary = {}

func _process(_delta: float) -> void:
	var needs_redraw := false
	if _has_walking_creatures():
		needs_redraw = true
	if _map_state != null:
		if _map_state.active_missiles.size() > 0:
			needs_redraw = true
		if _map_state.active_animated_texts.size() > 0:
			needs_redraw = true
		if not needs_redraw:
			for tile in _map_state.tiles.values():
				if tile.effects.size() > 0:
					needs_redraw = true
					break
	if needs_redraw:
		queue_redraw()

func on_creature_moved(_creature: Dictionary, _old_pos: Vector3i, _new_pos: Vector3i) -> void:
	queue_redraw()

func render(map_state, player_id: int) -> void:
	_map_state = map_state
	_player_id = player_id
	_camera_pos = map_state.player_pos
	_drawables.clear()
	_top_corrections.clear()
	_tile_render_states.clear()

	var first_floor := _MapVisibilityScript.calc_first_visible_floor(map_state, _camera_pos)
	var last_floor := _MapVisibilityScript.calc_last_visible_floor(_camera_pos)
	if last_floor < first_floor:
		last_floor = first_floor

	var tiles_by_floor: Dictionary = _MapVisibilityScript.build_visible_tile_positions(
		_camera_pos, first_floor, last_floor
	)

	var all_tile_positions: Array = []
	for floor_z in range(last_floor, first_floor - 1, -1):
		all_tile_positions.append_array(tiles_by_floor.get(floor_z, []))
	_precalculate_corpse_corrections(all_tile_positions)

	for floor_z in range(last_floor, first_floor - 1, -1):
		var tile_positions: Array = tiles_by_floor.get(floor_z, [])
		_render_floor(floor_z, tile_positions)

	queue_redraw()
	print(
		"MapView: %d sprites | andares %d-%d | câmera %s" % [
			_drawables.size(), first_floor, last_floor, _camera_pos
		]
	)

func _has_walking_creatures() -> bool:
	for drawable in _drawables:
		if drawable.has("creature") and drawable.creature.get("is_walking", false):
			return true
	return false

func _camera_reference_pos() -> Vector3i:
	var player := _find_player_creature()
	if player != null and player.get("is_walking", false):
		return player.get("from_tile_pos", _map_state.player_pos)
	return _map_state.player_pos

func _find_player_creature() -> Dictionary:
	if _map_state == null or _player_id <= 0:
		return {}
	for drawable in _drawables:
		if drawable.has("creature") and drawable.creature.get("id", 0) == _player_id:
			return drawable.creature
	return {}

func is_player_walking() -> bool:
	var player := _find_player_creature()
	return not player.is_empty() and player.get("is_walking", false)

func _get_camera_offset() -> Vector2:
	var player := _find_player_creature()
	if player.is_empty():
		return Vector2.ZERO
	if player.get("is_walking", false):
		return CreatureWalkerScript.get_walk_offset(player)
	return Vector2.ZERO

func _draw() -> void:
	var camera_offset := _get_camera_offset()
	for drawable in _drawables:
		var pos: Vector2
		var tex: Texture2D
		
		if drawable.has("creature"):
			var creature: Dictionary = drawable.creature
			var was_walking: bool = creature.get("is_walking", false)
			CreatureWalkerScript.update_walk(creature)
			pos = _creature_screen_position(creature, drawable.get("draw_elevation", 0), camera_offset)
			if was_walking and not creature.get("is_walking", false):
				queue_redraw()

			var look_type: int = creature.get("look_type", 0)
			if look_type <= 0 and creature.has("look_type_ex"):
				look_type = creature.get("look_type_ex", 0)
			var anim_phases := _creature_anim_phases(look_type)
			var anim_phase := CreatureWalkerScript.get_anim_phase(creature, anim_phases)
			tex = _ThingSpriteFactoryScript.get_creature_texture(
				look_type, creature.get("direction", 2), anim_phase
			)
		else:
			pos = drawable.position - camera_offset
			tex = drawable.texture
			
		if tex == null: continue
		
		var tint: Color = drawable.get("tint", Color.WHITE)
		if tint == Color.WHITE:
			draw_texture(tex, pos)
		else:
			draw_texture(tex, pos, tint)

	# Mísseis: renderizados por cima de tudo, por andar
	if _map_state != null:
		_draw_all_missiles(camera_offset)
		_draw_animated_texts(camera_offset)

func _render_floor(_floor_z: int, tile_positions: Array) -> void:
	for tile_pos in tile_positions:
		var tile = _map_state.get_tile(tile_pos)
		if tile == null:
			continue
		_reset_tile_render_state(tile_pos)
		_draw_ground(tile, tile_pos)

	for tile_pos in tile_positions:
		var tile = _map_state.get_tile(tile_pos)
		if tile == null:
			continue
		_draw_bottom(tile, tile_pos)
		_draw_creatures(tile_pos, tile, tile_pos)
		_draw_top(tile_pos, tile, tile_pos)

func _precalculate_corpse_corrections(tile_positions: Array) -> void:
	for tile_pos in tile_positions:
		var tile = _map_state.get_tile(tile_pos)
		if tile == null:
			continue
		var corpse_size := Vector2i.ZERO
		for i in range(tile.items.size() - 1, -1, -1):
			var thing = _item_thing(tile.items[i].get("id", 0))
			if thing == null or not thing.is_lying_corpse():
				continue
			corpse_size.x = maxi(corpse_size.x, int(thing.width) - 1)
			corpse_size.y = maxi(corpse_size.y, int(thing.height) - 1)

		for x in range(-corpse_size.x, 1):
			for y in range(-corpse_size.y, 1):
				if x == 0 and y == 0:
					continue
				var neighbor_key := _tile_key(tile_pos + Vector3i(x, y, 0))
				_top_corrections[neighbor_key] = _top_corrections.get(neighbor_key, 0) + 1

func _reset_tile_render_state(tile_pos: Vector3i) -> void:
	var key := _tile_key(tile_pos)
	_tile_render_states[key] = {"draw_elevation": 0, "top_draws": 0}

func _tile_state(tile_pos: Vector3i) -> Dictionary:
	var key := _tile_key(tile_pos)
	if not _tile_render_states.has(key):
		_tile_render_states[key] = {"draw_elevation": 0, "top_draws": 0}
	return _tile_render_states[key]

func _top_correction(tile_pos: Vector3i) -> int:
	return _top_corrections.get(_tile_key(tile_pos), 0)

func _draw_ground(tile, tile_pos: Vector3i) -> void:
	var state := _tile_state(tile_pos)
	state.draw_elevation = 0
	state.top_draws = 0

	for item in tile.items:
		var thing = _item_thing(item.get("id", 0))
		if thing == null:
			continue
		if not thing.is_ground() and not thing.is_ground_border():
			break
		_append_item_drawable(item, tile_pos, state.draw_elevation)
		state.draw_elevation = mini(state.draw_elevation + thing.get_elevation_value(), MAX_ELEVATION)

func _draw_bottom(tile, tile_pos: Vector3i) -> void:
	var state := _tile_state(tile_pos)
	var after_bottom := false
	var corpse_size := Vector2i.ZERO

	for item in tile.items:
		var thing = _item_thing(item.get("id", 0))
		if thing == null:
			continue
		if thing.is_on_bottom():
			after_bottom = true
		if not thing.is_ground() and not thing.is_ground_border() and not thing.is_on_bottom():
			break
		if not after_bottom:
			continue
		_append_item_drawable(item, tile_pos, state.draw_elevation)
		state.draw_elevation = mini(state.draw_elevation + thing.get_elevation_value(), MAX_ELEVATION)

	for i in range(tile.items.size() - 1, -1, -1):
		var item: Dictionary = tile.items[i]
		var thing = _item_thing(item.get("id", 0))
		if thing == null:
			continue
		if thing.is_on_top() or thing.is_on_bottom() or thing.is_ground_border() or thing.is_ground():
			break
		_append_item_drawable(item, tile_pos, state.draw_elevation)
		state.draw_elevation = mini(state.draw_elevation + thing.get_elevation_value(), MAX_ELEVATION)
		if thing.is_lying_corpse():
			corpse_size.x = maxi(corpse_size.x, int(thing.width) - 1)
			corpse_size.y = maxi(corpse_size.y, int(thing.height) - 1)

	_redraw_neighbors_for_corpse(tile_pos, corpse_size)

func _redraw_neighbors_for_corpse(tile_pos: Vector3i, corpse_size: Vector2i) -> void:
	var source_dest := _tile_base_position(tile_pos)
	for x in range(-corpse_size.x, 1):
		for y in range(-corpse_size.y, 1):
			if x == 0 and y == 0:
				continue
			var neighbor_pos := tile_pos + Vector3i(x, y, 0)
			var neighbor_tile = _map_state.get_tile(neighbor_pos)
			if neighbor_tile == null:
				continue
			var redraw_dest := source_dest + Vector2(x, y) * TILE_SIZE
			_draw_creatures(tile_pos, neighbor_tile, neighbor_pos, redraw_dest)
			_draw_top(tile_pos, neighbor_tile, neighbor_pos, redraw_dest)

func _draw_creatures(_source_tile_pos: Vector3i, tile, tile_pos: Vector3i, base_pos: Vector2 = Vector2(-1, -1)) -> void:
	var state := _tile_state(tile_pos)
	if state.top_draws < _top_correction(tile_pos):
		return
	var draw_pos := base_pos if base_pos.x >= 0.0 else _tile_base_position(tile_pos)
	_draw_creatures_at(tile, tile_pos, draw_pos)

func _draw_creatures_at(tile, tile_pos: Vector3i, base_pos: Vector2) -> void:
	var elevation: int = _tile_state(tile_pos).draw_elevation
	for creature in tile.creatures:
		_append_creature_drawable(creature, base_pos, elevation)

func _draw_top(_source_tile_pos: Vector3i, tile, tile_pos: Vector3i, base_pos: Vector2 = Vector2(-1, -1)) -> void:
	var state := _tile_state(tile_pos)
	if state.top_draws < _top_correction(tile_pos):
		state.top_draws += 1
		return
	state.top_draws += 1
	var draw_pos := base_pos if base_pos.x >= 0.0 else _tile_base_position(tile_pos)
	_draw_top_at(tile, tile_pos, draw_pos)

func _draw_top_at(tile, tile_pos: Vector3i, base_pos: Vector2) -> void:
	var elevation: int = _tile_state(tile_pos).draw_elevation
	for item in tile.items:
		var thing = _item_thing(item.get("id", 0))
		if thing == null or not thing.is_on_top():
			continue
		_append_item_drawable_at(item, tile_pos, base_pos, elevation)
		elevation = mini(elevation + thing.get_elevation_value(), MAX_ELEVATION)
	# Efeitos: desenhados após criaturas e antes de on-top (seguindo tile.cpp:drawTop)
	_draw_tile_effects_at(tile, tile_pos, base_pos, elevation)

func _append_item_drawable(item: Dictionary, tile_pos: Vector3i, draw_elevation: int) -> void:
	_append_item_drawable_at(item, tile_pos, _tile_base_position(tile_pos), draw_elevation)

func _append_item_drawable_at(
	item: Dictionary,
	tile_pos: Vector3i,
	base_pos: Vector2,
	draw_elevation: int
) -> void:
	var item_id: int = item.get("id", 0)
	var texture: Texture2D = _ThingSpriteFactoryScript.get_item_texture(
		item_id, tile_pos, item.get("count", 1)
	)
	if texture == null:
		return
	var screen_offset: Vector2i = _ThingSpriteFactoryScript.get_draw_offset_for_item(
		item_id, tile_pos, item.get("count", 1)
	)
	var elevation_offset := Vector2(-draw_elevation * OFFSET_FACTOR, -draw_elevation * OFFSET_FACTOR)
	_drawables.append({
		"position": base_pos + Vector2(screen_offset) + elevation_offset,
		"texture": texture,
	})

func _append_creature_drawable(creature: Dictionary, _base_pos: Vector2, draw_elevation: int) -> void:
	var entry := {
		"creature": creature,
		"draw_elevation": draw_elevation,
	}
	if creature.get("id", 0) == _player_id:
		entry["tint"] = Color(1.0, 1.05, 1.1)
	_drawables.append(entry)

func _tile_base_position(tile_pos: Vector3i) -> Vector2:
	var camera_pos := _camera_reference_pos() if _map_state != null else _camera_pos
	var z_shift: int = camera_pos.z - tile_pos.z
	var dest := Vector2i(
		(tile_pos.x - camera_pos.x + _MapStateScript.MAP_LEFT - z_shift) * TILE_SIZE,
		(tile_pos.y - camera_pos.y + _MapStateScript.MAP_TOP - z_shift) * TILE_SIZE
	)
	return Vector2(dest.x, dest.y)

func _creature_screen_position(
	creature: Dictionary,
	draw_elevation: int,
	camera_offset: Vector2
) -> Vector2:
	var look_type: int = creature.get("look_type", 0)
	if look_type <= 0 and creature.has("look_type_ex"):
		look_type = creature.get("look_type_ex", 0)
	var screen_offset: Vector2i = _ThingSpriteFactoryScript.get_draw_offset_for_creature(
		look_type, creature.get("direction", 2)
	)
	var anchor_tile: Vector3i
	if creature.get("is_walking", false):
		anchor_tile = creature.get("from_tile_pos", creature.get("tile_pos", Vector3i.ZERO))
	else:
		anchor_tile = creature.get("tile_pos", Vector3i.ZERO)
	var elevation_offset := Vector2(-draw_elevation * OFFSET_FACTOR, -draw_elevation * OFFSET_FACTOR)
	var walk_offset := CreatureWalkerScript.get_walk_offset(creature)
	return _tile_base_position(anchor_tile) + Vector2(screen_offset) + elevation_offset + walk_offset - camera_offset

func _creature_anim_phases(look_type: int) -> int:
	if look_type <= 0:
		return 1
	var thing = _ThingSpriteFactoryScript.get_thing(
		look_type, _DatReaderScript.ThingCategory.CREATURE
	)
	if thing == null:
		return 1
	return maxi(int(thing.animation_phases), 1)

func _item_thing(item_id: int):
	if item_id <= 0:
		return null
	return _ThingSpriteFactoryScript.get_thing(item_id, _DatReaderScript.ThingCategory.ITEM)

static func _tile_key(tile_pos: Vector3i) -> String:
	return "%d,%d,%d" % [tile_pos.x, tile_pos.y, tile_pos.z]

# ---------------------------------------------------------------------------
# EFEITOS MÁGICOS por Tile (Opcode 0x83)
# ---------------------------------------------------------------------------
func _draw_tile_effects_at(tile, _tile_pos: Vector3i, base_pos: Vector2, elevation: int) -> void:
	if tile.effects.is_empty():
		return
	var elevation_offset := Vector2(-elevation * OFFSET_FACTOR, -elevation * OFFSET_FACTOR)
	var to_remove: Array[int] = []
	for i in range(tile.effects.size()):
		var effect: Dictionary = tile.effects[i]
		var effect_id: int = effect.get("effect_id", 0)
		var total_phases := _ThingSpriteFactoryScript.get_effect_animation_phases(effect_id)
		var phase := EffectAnimatorScript.get_effect_phase(effect, total_phases)
		if phase < 0:
			to_remove.append(i)
			continue
		var patterns := EffectAnimatorScript.get_effect_patterns(effect, 1, 1)
		var tex := _ThingSpriteFactoryScript.get_effect_texture(
			effect_id, phase, patterns.x, patterns.y
		)
		if tex == null:
			continue
		draw_texture(tex, base_pos + elevation_offset)
	# Remover em ordem reversa para não quebrar índices
	for i in range(to_remove.size() - 1, -1, -1):
		tile.effects.remove_at(to_remove[i])

# ---------------------------------------------------------------------------
# MÍSSEIS (Opcode 0x85)
# ---------------------------------------------------------------------------
func _draw_all_missiles(camera_offset: Vector2) -> void:
	if _map_state.active_missiles.is_empty():
		return
	var to_remove: Array[int] = []
	for i in range(_map_state.active_missiles.size()):
		var missile: Dictionary = _map_state.active_missiles[i]
		# Só renderiza mísseis do andar visível
		var from_pos: Vector3i = missile.get("from_pos", Vector3i.ZERO)
		if from_pos.z != _camera_pos.z:
			if not EffectAnimatorScript.is_missile_alive(missile):
				to_remove.append(i)
			continue
		if not EffectAnimatorScript.is_missile_alive(missile):
			to_remove.append(i)
			continue
		var missile_id: int = missile.get("missile_id", 0)
		var direction: int = missile.get("direction", 8)
		var pattern := EffectAnimatorScript.get_missile_sprite_pattern(direction)
		var tex := _ThingSpriteFactoryScript.get_missile_texture(missile_id, pattern[0], pattern[1])
		if tex == null:
			continue
		var base := _tile_base_position(from_pos)
		var offset := EffectAnimatorScript.get_missile_screen_offset(missile)
		draw_texture(tex, base + offset - camera_offset)
	for i in range(to_remove.size() - 1, -1, -1):
		_map_state.active_missiles.remove_at(to_remove[i])

# ---------------------------------------------------------------------------
# TEXTO ANIMADO (Opcode 0x84)
# ---------------------------------------------------------------------------
func _draw_animated_texts(camera_offset: Vector2) -> void:
	if _map_state.active_animated_texts.is_empty():
		return
	var to_remove: Array[int] = []
	for i in range(_map_state.active_animated_texts.size()):
		var entry: Dictionary = _map_state.active_animated_texts[i]
		var state := EffectAnimatorScript.get_animated_text_state(entry)
		if not state.get("alive", false):
			to_remove.append(i)
			continue
		var tile_pos: Vector3i = entry.get("tile_pos", Vector3i.ZERO)
		if tile_pos.z != _camera_pos.z:
			continue
		var base := _tile_base_position(tile_pos)
		var y_off: float = state.get("y_offset", 0.0)
		var alpha: float = state.get("alpha", 1.0)
		var raw_color: int = entry.get("color", 215)
		var text: String = entry.get("text", "")
		# Converter cor 8-bit Tibia para Color RGBA
		var r := ((raw_color / 36) % 6) * 51
		var g := ((raw_color / 6) % 6) * 51
		var b := (raw_color % 6) * 51
		var color := Color(r / 255.0, g / 255.0, b / 255.0, alpha)
		var draw_pos := base - camera_offset + Vector2(0.0, y_off) + Vector2(4.0, -24.0)
		draw_string(ThemeDB.fallback_font, draw_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, color)
	for i in range(to_remove.size() - 1, -1, -1):
		_map_state.active_animated_texts.remove_at(to_remove[i])
