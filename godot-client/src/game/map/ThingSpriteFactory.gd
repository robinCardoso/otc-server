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

## Textura composta com camadas de outfit (head/body/legs/feet + addons).
static func get_creature_outfit_texture(creature: Dictionary, direction: int, animation_phase: int = 0) -> Texture2D:
	var look_type: int = creature.get("look_type", 0)
	if look_type <= 0 and creature.has("look_type_ex"):
		look_type = creature.get("look_type_ex", 0)
	if look_type <= 0:
		return null

	var x_pattern := clampi(direction, 0, 3)
	var addons: int = creature.get("look_addons", 0)
	var head: int = creature.get("look_head", 0)
	var body: int = creature.get("look_body", 0)
	var legs: int = creature.get("look_legs", 0)
	var feet: int = creature.get("look_feet", 0)

	var thing = get_thing(look_type, _DatReaderScript.ThingCategory.CREATURE)
	if thing == null:
		return null

	var cache_key := "outfit:%d:%d:%d:%d:%d:%d:%d:%d:%d" % [
		look_type, x_pattern, animation_phase, addons, head, body, legs, feet, thing.layers
	]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	var composite := _build_creature_outfit_image(
		thing, look_type, x_pattern, animation_phase, addons, head, body, legs, feet
	)
	if composite == null:
		return get_creature_texture(look_type, direction, animation_phase)

	var texture := ImageTexture.create_from_image(composite)
	_texture_cache[cache_key] = texture
	return texture

## Paleta HSI de outfit (espelha Color::getOutfitColor do OTC).
static func get_outfit_color(color_index: int) -> Color:
	const HSI_SI_VALUES := 7
	const HSI_H_STEPS := 19
	var color := color_index
	if color >= HSI_H_STEPS * HSI_SI_VALUES:
		color = 0

	var loc1 := 0.0
	var loc2 := 0.0
	var loc3 := 0.0
	if color % HSI_H_STEPS != 0:
		loc1 = float(color % HSI_H_STEPS) / 18.0
		loc2 = 1.0
		loc3 = 1.0
		match int(color / HSI_H_STEPS):
			0:
				loc2 = 0.25
				loc3 = 1.0
			1:
				loc2 = 0.25
				loc3 = 0.75
			2:
				loc2 = 0.50
				loc3 = 0.75
			3:
				loc2 = 0.667
				loc3 = 0.75
			4:
				loc2 = 1.0
				loc3 = 1.0
			5:
				loc2 = 1.0
				loc3 = 0.75
			6:
				loc2 = 1.0
				loc3 = 0.50
	else:
		loc3 = 1.0 - float(color) / float(HSI_H_STEPS * HSI_SI_VALUES)

	if loc3 == 0.0:
		return Color.BLACK
	if loc2 == 0.0:
		var gray := int(loc3 * 255.0)
		return Color8(gray, gray, gray)

	var red := 0.0
	var green := 0.0
	var blue := 0.0
	if loc1 < 1.0 / 6.0:
		red = loc3
		blue = loc3 * (1.0 - loc2)
		green = blue + (loc3 - blue) * 6.0 * loc1
	elif loc1 < 2.0 / 6.0:
		green = loc3
		blue = loc3 * (1.0 - loc2)
		red = green - (loc3 - blue) * (6.0 * loc1 - 1.0)
	elif loc1 < 3.0 / 6.0:
		green = loc3
		red = loc3 * (1.0 - loc2)
		blue = red + (loc3 - red) * (6.0 * loc1 - 2.0)
	elif loc1 < 4.0 / 6.0:
		blue = loc3
		red = loc3 * (1.0 - loc2)
		green = blue - (loc3 - red) * (6.0 * loc1 - 3.0)
	elif loc1 < 5.0 / 6.0:
		blue = loc3
		green = loc3 * (1.0 - loc2)
		red = green + (loc3 - green) * (6.0 * loc1 - 4.0)
	else:
		red = loc3
		green = loc3 * (1.0 - loc2)
		blue = red - (loc3 - green) * (6.0 * loc1 - 5.0)
	return Color(red, green, blue)

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

static func _build_creature_outfit_image(
	thing,
	look_type: int,
	x_pattern: int,
	animation_phase: int,
	addons: int,
	head: int,
	body: int,
	legs: int,
	feet: int
) -> Image:
	var thing_width: int = int(thing.width)
	var thing_height: int = int(thing.height)
	var combined_img := Image.create(
		thing_width * TILE_SIZE, thing_height * TILE_SIZE, false, Image.FORMAT_RGBA8
	)

	var head_c := get_outfit_color(head)
	var body_c := get_outfit_color(body)
	var legs_c := get_outfit_color(legs)
	var feet_c := get_outfit_color(feet)

	for y_pattern in range(maxi(thing.pattern_y, 1)):
		if y_pattern > 0 and (addons & (1 << (y_pattern - 1))) == 0:
			continue
		if thing.layers <= 1:
			_blit_creature_pattern(
				combined_img, thing, look_type, x_pattern, y_pattern, 0, animation_phase, 0, true
			)
		else:
			_blit_creature_pattern(
				combined_img, thing, look_type, x_pattern, y_pattern, 0, animation_phase, 0, true
			)
			var mask_img := Image.create(
				thing_width * TILE_SIZE, thing_height * TILE_SIZE, false, Image.FORMAT_RGBA8
			)
			_blit_creature_pattern(
				mask_img, thing, look_type, x_pattern, y_pattern, 1, animation_phase, 0, false
			)
			_apply_outfit_mask(combined_img, mask_img, head_c, body_c, legs_c, feet_c)

	return combined_img

static func _blit_creature_pattern(
	target: Image,
	thing,
	look_type: int,
	x_pattern: int,
	y_pattern: int,
	layer: int,
	animation_phase: int,
	blend_mode: int,
	blend_with_existing: bool
) -> void:
	var thing_width: int = int(thing.width)
	var thing_height: int = int(thing.height)
	for h in range(thing_height):
		for w in range(thing_width):
			var sprite_id: int = _DatReaderScript.get_sprite_index(
				thing, w, h, layer, x_pattern, y_pattern, 0, animation_phase
			)
			if sprite_id <= 0:
				continue
			var sprite_tex: ImageTexture = _sprites().get_sprite_texture(_spr_abs_path, sprite_id)
			if sprite_tex == null:
				continue
			var dest_x: int = (thing_width - w - 1) * TILE_SIZE
			var dest_y: int = (thing_height - h - 1) * TILE_SIZE
			var sprite_img := sprite_tex.get_image()
			if blend_with_existing:
				_blend_image_rect(target, sprite_img, Rect2i(dest_x, dest_y, TILE_SIZE, TILE_SIZE), blend_mode)
			else:
				target.blit_rect(sprite_img, Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Vector2i(dest_x, dest_y))

static func _apply_outfit_mask(
	base_img: Image,
	mask_img: Image,
	head_c: Color,
	body_c: Color,
	legs_c: Color,
	feet_c: Color
) -> void:
	for y in range(mask_img.get_height()):
		for x in range(mask_img.get_width()):
			var m := mask_img.get_pixel(x, y)
			if m.a < 0.01:
				continue
			var tinted := Color(
				m.r * head_c.r + m.g * body_c.r + m.b * legs_c.r + m.a * feet_c.r,
				m.r * head_c.g + m.g * body_c.g + m.b * legs_c.g + m.a * feet_c.g,
				m.r * head_c.b + m.g * body_c.b + m.b * legs_c.b + m.a * feet_c.b,
				clampf(m.r + m.g + m.b + m.a, 0.0, 1.0)
			)
			var base_px := base_img.get_pixel(x, y)
			if base_px.a < 0.01:
				base_img.set_pixel(x, y, tinted)
			else:
				base_img.set_pixel(x, y, base_px.lerp(tinted, tinted.a))

static func _blend_image_rect(target: Image, source: Image, dest_rect: Rect2i, _blend_mode: int) -> void:
	for y in range(dest_rect.size.y):
		for x in range(dest_rect.size.x):
			var src_px := source.get_pixel(x, y)
			if src_px.a < 0.01:
				continue
			var dst_px := target.get_pixel(dest_rect.position.x + x, dest_rect.position.y + y)
			if dst_px.a < 0.01:
				target.set_pixel(dest_rect.position.x + x, dest_rect.position.y + y, src_px)
			else:
				target.set_pixel(
					dest_rect.position.x + x, dest_rect.position.y + y, dst_px.lerp(src_px, src_px.a)
				)
