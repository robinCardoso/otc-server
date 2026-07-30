# DatReader.gd
# Leitura do Tibia.dat 8.60 (formato OTClient / ThingAttr)
class_name TibiaDatReader
extends Node

enum ThingCategory {
	ITEM = 0,
	CREATURE = 1,
	EFFECT = 2,
	MISSILE = 3
}

# ThingAttr — espelha client/src/client/thingtype.h (protocolo 8.60)
const ATTR_GROUND := 0
const ATTR_GROUND_BORDER := 1
const ATTR_ON_BOTTOM := 2
const ATTR_ON_TOP := 3
const ATTR_FLUID_CONTAINER := 10
const ATTR_SPLASH := 11
const ATTR_STACKABLE := 5
const ATTR_WRITABLE := 8
const ATTR_WRITABLE_ONCE := 9
const ATTR_BLOCK_PROJECTILE := 14
const ATTR_LIGHT := 21
const ATTR_DONT_HIDE := 22
const ATTR_DISPLACEMENT := 24
const ATTR_ELEVATION := 25
const ATTR_LYING_CORPSE := 26
const ATTR_MINIMAP_COLOR := 28
const ATTR_LENS_HELP := 29
const ATTR_CLOTH := 32
const ATTR_MARKET := 33
const ATTR_USABLE := 34
const ATTR_BONES := 38
const ATTR_CHARGEABLE := 254
const ATTR_LAST := 255

class ThingType:
	var id: int
	var category: int
	var flags: Dictionary = {}

	var speed: int = 0
	var light_level: int = 0
	var light_color: int = 0
	var displacement_x: int = 0
	var displacement_y: int = 0
	var elevation: int = 0
	var minimap_color: int = 0

	var width: int = 1
	var height: int = 1
	var real_size: int = 0
	var layers: int = 1
	var pattern_x: int = 1
	var pattern_y: int = 1
	var pattern_z: int = 1
	var animation_phases: int = 1
	var sprites: Array[int] = []

	func has_flag(flag: int) -> bool:
		return flags.has(flag)

	func is_ground() -> bool:
		return has_flag(ATTR_GROUND)

	func is_ground_border() -> bool:
		return has_flag(ATTR_GROUND_BORDER)

	func is_on_bottom() -> bool:
		return has_flag(ATTR_ON_BOTTOM)

	func is_on_top() -> bool:
		return has_flag(ATTR_ON_TOP)

	func is_lying_corpse() -> bool:
		return has_flag(ATTR_LYING_CORPSE)

	func is_dont_hide() -> bool:
		return has_flag(ATTR_DONT_HIDE)

	func blocks_projectile() -> bool:
		return has_flag(ATTR_BLOCK_PROJECTILE)

	func get_elevation_value() -> int:
		return elevation

	func get_ground_speed() -> int:
		if is_ground() or is_ground_border():
			return speed
		return 0

static func load_dat(dat_path: String) -> Dictionary:
	var database = {
		ThingCategory.ITEM: {},
		ThingCategory.CREATURE: {},
		ThingCategory.EFFECT: {},
		ThingCategory.MISSILE: {},
	}

	var file := FileAccess.open(dat_path, FileAccess.READ)
	if not file:
		push_error("Não foi possível abrir o arquivo: " + dat_path)
		return database

	var signature := file.get_32()
	print("Tibia.dat Signature: ", String.num_uint64(signature))

	var items_count := file.get_16()
	var creatures_count := file.get_16()
	var effects_count := file.get_16()
	var missiles_count := file.get_16()
	print(
		"Dat Items: %d, Creatures: %d, Effects: %d, Missiles: %d" % [
			items_count, creatures_count, effects_count, missiles_count
		]
	)

	_read_category(file, database, ThingCategory.ITEM, 100, items_count)
	_read_category(file, database, ThingCategory.CREATURE, 1, creatures_count)
	_read_category(file, database, ThingCategory.EFFECT, 1, effects_count)
	_read_category(file, database, ThingCategory.MISSILE, 1, missiles_count)
	return database

static func _read_category(
	file: FileAccess,
	database: Dictionary,
	category: int,
	start_id: int,
	count: int
) -> void:
	for i in range(1, count + 1):
		var thing_id := start_id + (i - 1)
		var thing := ThingType.new()
		thing.id = thing_id
		thing.category = category
		_read_attributes(file, thing)

		thing.width = file.get_8()
		thing.height = file.get_8()
		if thing.width > 1 or thing.height > 1:
			thing.real_size = file.get_8()

		thing.layers = file.get_8()
		thing.pattern_x = file.get_8()
		thing.pattern_y = file.get_8()
		thing.pattern_z = file.get_8()
		thing.animation_phases = file.get_8()

		var total_sprites := (
			thing.width * thing.height * thing.layers
			* thing.pattern_x * thing.pattern_y * thing.pattern_z
			* thing.animation_phases
		)
		for _s in range(total_sprites):
			thing.sprites.append(file.get_16())

		database[category][thing_id] = thing

static func _read_attributes(file: FileAccess, thing: ThingType) -> void:
	while not file.eof_reached():
		var flag := file.get_8()
		if flag == ATTR_LAST:
			return

		thing.flags[flag] = true
		match flag:
			ATTR_GROUND:
				thing.speed = file.get_16()
			ATTR_WRITABLE, ATTR_WRITABLE_ONCE, ATTR_MINIMAP_COLOR, ATTR_LENS_HELP, ATTR_CLOTH, ATTR_USABLE:
				file.get_16()
			ATTR_LIGHT:
				thing.light_level = file.get_16()
				thing.light_color = file.get_16()
			ATTR_DISPLACEMENT:
				thing.displacement_x = file.get_16()
				thing.displacement_y = file.get_16()
			ATTR_ELEVATION:
				thing.elevation = file.get_16()
			ATTR_MARKET:
				file.get_16()
				file.get_16()
				file.get_16()
				var name_size := file.get_16()
				if name_size > 0:
					file.seek(file.get_position() + name_size)
				file.get_16()
				file.get_16()
			ATTR_BONES:
				for _i in range(8):
					file.get_16()
			_:
				pass

static func get_sprite_index(
	thing: ThingType,
	w: int,
	h: int,
	layer: int = 0,
	pattern_x: int = 0,
	pattern_y: int = 0,
	pattern_z: int = 0,
	anim: int = 0
) -> int:
	var index := anim
	index = index * thing.pattern_z + pattern_z
	index = index * thing.pattern_y + pattern_y
	index = index * thing.pattern_x + pattern_x
	index = index * thing.layers + layer
	index = index * thing.height + h
	index = index * thing.width + w
	if index < 0 or index >= thing.sprites.size():
		return 0
	return thing.sprites[index]
