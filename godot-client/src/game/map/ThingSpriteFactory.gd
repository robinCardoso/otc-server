extends RefCounted

const SPR_PATH := "res://assets/client/Tibia.spr"
const DAT_PATH := "res://assets/client/Tibia.dat"
const TILE_SIZE := 32

const _DatReaderScript := preload("res://src/io/DatReader.gd")
const _SpriteReaderScript := preload("res://src/io/SpriteReader.gd")

static var _database: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var _spr_abs_path: String = ""
static var _sprite_reader: RefCounted = null

static func _sprites():
	if _sprite_reader == null:
		_sprite_reader = _SpriteReaderScript.new()
	return _sprite_reader

static func ensure_loaded() -> void:
	if not _database.is_empty():
		return
	_spr_abs_path = ProjectSettings.globalize_path(SPR_PATH)
	_database = _DatReaderScript.load_dat(ProjectSettings.globalize_path(DAT_PATH))
	_sprites().ensure_index(_spr_abs_path)

static func get_thing(thing_id: int, category: int):
	ensure_loaded()
	return _database[category].get(thing_id)

static func get_item_texture(
	item_id: int,
	tile_pos: Vector3i = Vector3i.ZERO,
	count: int = 1
) -> Texture2D:
	if item_id <= 0:
		return null
	var patterns := _calculate_item_patterns(item_id, tile_pos, count)
	return _get_thing_texture(
		item_id,
		_DatReaderScript.ThingCategory.ITEM,
		patterns.x,
		patterns.y,
		patterns.z
	)

static func get_creature_texture(look_type: int, direction: int = 2, animation_phase: int = 0) -> Texture2D:
	if look_type <= 0:
		return null
	var x_pattern := clampi(direction, 0, 3)
	return _get_thing_texture(look_type, _DatReaderScript.ThingCategory.CREATURE, x_pattern, 0, 0, animation_phase)

## Textura de efeito mágico (Opcode 0x83).
## pattern_x/y vêm de EffectAnimator.get_effect_patterns().
static func get_effect_texture(effect_id: int, anim_phase: int, pattern_x: int = 0, pattern_y: int = 0) -> Texture2D:
	if effect_id <= 0:
		return null
	var thing = get_thing(effect_id, _DatReaderScript.ThingCategory.EFFECT)
	if thing == null:
		return null
	var safe_px := pattern_x % maxi(1, thing.pattern_x)
	var safe_py := pattern_y % maxi(1, thing.pattern_y)
	var safe_phase := anim_phase % maxi(1, thing.animation_phases)
	return _get_thing_texture(effect_id, _DatReaderScript.ThingCategory.EFFECT, safe_px, safe_py, 0, safe_phase)

## Textura de míssil (Opcode 0x85).
## pattern_x/y vêm de EffectAnimator.get_missile_sprite_pattern(direction).
static func get_missile_texture(missile_id: int, pattern_x: int = 1, pattern_y: int = 1) -> Texture2D:
	if missile_id <= 0:
		return null
	var thing = get_thing(missile_id, _DatReaderScript.ThingCategory.MISSILE)
	if thing == null:
		return null
	var safe_px := pattern_x % maxi(1, thing.pattern_x)
	var safe_py := pattern_y % maxi(1, thing.pattern_y)
	return _get_thing_texture(missile_id, _DatReaderScript.ThingCategory.MISSILE, safe_px, safe_py, 0, 0)

## Retorna o número de fases de animação de um efeito.
static func get_effect_animation_phases(effect_id: int) -> int:
	var thing = get_thing(effect_id, _DatReaderScript.ThingCategory.EFFECT)
	if thing == null:
		return 0
	return thing.animation_phases

static func get_screen_offset(thing_id: int, category: int) -> Vector2i:
	var size := get_thing_size(thing_id, category)
	var displacement := get_displacement(thing_id, category)
	return -displacement - Vector2i(size.x - 1, size.y - 1) * TILE_SIZE

static func get_draw_offset_for_item(item_id: int, _tile_pos: Vector3i, _count: int = 1) -> Vector2i:
	return get_screen_offset(item_id, _DatReaderScript.ThingCategory.ITEM)

static func get_draw_offset_for_creature(look_type: int, _direction: int = 2) -> Vector2i:
	return get_screen_offset(look_type, _DatReaderScript.ThingCategory.CREATURE)

static func get_thing_size(thing_id: int, category: int) -> Vector2i:
	var thing = get_thing(thing_id, category)
	if thing == null:
		return Vector2i.ONE
	return Vector2i(int(thing.width), int(thing.height))

static func get_displacement(thing_id: int, category: int) -> Vector2i:
	var thing = get_thing(thing_id, category)
	if thing == null:
		return Vector2i.ZERO
	if thing.has_flag(_DatReaderScript.ATTR_DISPLACEMENT):
		return Vector2i(int(thing.displacement_x), int(thing.displacement_y))
	return Vector2i.ZERO

static func _calculate_item_patterns(item_id: int, tile_pos: Vector3i, count: int) -> Vector3i:
	var thing = get_thing(item_id, _DatReaderScript.ThingCategory.ITEM)
	if thing == null:
		return Vector3i.ZERO

	if thing.has_flag(_DatReaderScript.ATTR_STACKABLE) and thing.pattern_x == 4 and thing.pattern_y == 2:
		if count <= 0:
			return Vector3i.ZERO
		if count < 5:
			return Vector3i(count - 1, 0, 0)
		if count < 10:
			return Vector3i(0, 1, 0)
		if count < 25:
			return Vector3i(1, 1, 0)
		if count < 50:
			return Vector3i(2, 1, 0)
		return Vector3i(3, 1, 0)

	if (
		thing.has_flag(_DatReaderScript.ATTR_FLUID_CONTAINER)
		or thing.has_flag(_DatReaderScript.ATTR_SPLASH)
	):
		var color: int = maxi(count, 0)
		return Vector3i(color % 4 % maxi(1, thing.pattern_x), color / 4 % maxi(1, thing.pattern_y), 0)

	return Vector3i(
		tile_pos.x % maxi(1, thing.pattern_x),
		tile_pos.y % maxi(1, thing.pattern_y),
		tile_pos.z % maxi(1, thing.pattern_z)
	)

static func _get_thing_texture(
	thing_id: int,
	category: int,
	pattern_x: int = 0,
	pattern_y: int = 0,
	pattern_z: int = 0,
	animation_phase: int = 0
) -> Texture2D:
	if thing_id <= 0:
		return null
	ensure_loaded()
	var cache_key := "%d:%d:%d:%d:%d:%d" % [category, thing_id, pattern_x, pattern_y, pattern_z, animation_phase]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	var thing = _database[category].get(thing_id)
	if thing == null:
		return null
	var texture := _build_texture(thing, pattern_x, pattern_y, pattern_z, animation_phase)
	if texture:
		_texture_cache[cache_key] = texture
	return texture

static func _build_texture(thing, pattern_x: int, pattern_y: int, pattern_z: int, animation_phase: int = 0) -> Texture2D:
	if thing.sprites.is_empty():
		return null

	var thing_width: int = int(thing.width)
	var thing_height: int = int(thing.height)
	var combined_img := Image.create(
		thing_width * TILE_SIZE, thing_height * TILE_SIZE, false, Image.FORMAT_RGBA8
	)

	for h in range(thing_height):
		for w in range(thing_width):
			var sprite_id: int = _DatReaderScript.get_sprite_index(
				thing, w, h, 0, pattern_x, pattern_y, pattern_z, animation_phase
			)
			if sprite_id <= 0:
				continue
			var sprite_tex: ImageTexture = _sprites().get_sprite_texture(_spr_abs_path, sprite_id)
			if sprite_tex == null:
				continue
			var dest_x: int = (thing_width - w - 1) * TILE_SIZE
			var dest_y: int = (thing_height - h - 1) * TILE_SIZE
			combined_img.blit_rect(
				sprite_tex.get_image(),
				Rect2i(0, 0, TILE_SIZE, TILE_SIZE),
				Vector2i(dest_x, dest_y)
			)

	return ImageTexture.create_from_image(combined_img)
