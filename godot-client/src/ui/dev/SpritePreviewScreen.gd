extends Control

const _SpriteReaderScript := preload("res://src/io/SpriteReader.gd")

const SPR_PATH := "res://assets/client/Tibia.spr"
const DAT_PATH := "res://assets/client/Tibia.dat"

var _sprite_reader: RefCounted = null

@onready var _texture_rect: TextureRect = $CanvasLayer/Control/TextureRect
@onready var _item_id_spin: SpinBox = $CanvasLayer/Control/Panel/SpinBox
@onready var _status_label: Label = $CanvasLayer/Control/Panel/LabelStatus

var _dat_database: Dictionary = {}
var _spr_cache: Dictionary = {}

func _ready() -> void:
	_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var abs_dat_path := ProjectSettings.globalize_path(DAT_PATH)
	_status_label.text = "Carregando Tibia.dat..."
	_dat_database = TibiaDatReader.load_dat(abs_dat_path)

	var total_items: int = _dat_database[TibiaDatReader.ThingCategory.ITEM].size()
	_item_id_spin.max_value = 100 + total_items - 1
	_item_id_spin.value = 100
	_load_item(100)

func _load_item(item_id: int) -> void:
	_status_label.text = "Buscando item %d..." % item_id

	var items_dict: Dictionary = _dat_database[TibiaDatReader.ThingCategory.ITEM]
	if not items_dict.has(item_id):
		_status_label.text = "Item %d não encontrado!" % item_id
		_texture_rect.texture = null
		return

	var thing: TibiaDatReader.ThingType = items_dict[item_id]
	_status_label.text = "Item %d: %dx%d (Layers: %d, Sprites: %d)" % [
		item_id, thing.width, thing.height, thing.layers, thing.sprites.size()
	]

	if thing.sprites.is_empty():
		_texture_rect.texture = null
		return

	var abs_spr_path := ProjectSettings.globalize_path(SPR_PATH)
	var final_width := thing.width * 32
	var final_height := thing.height * 32
	var combined_img := Image.create(final_width, final_height, false, Image.FORMAT_RGBA8)

	var sprite_index := 0
	for w in range(thing.width):
		for h in range(thing.height):
			if sprite_index >= thing.sprites.size():
				break
			var sprite_id: int = thing.sprites[sprite_index]
			sprite_index += 1

			if sprite_id <= 0:
				continue

			var sprite_tex: ImageTexture = _spr_cache.get(sprite_id)
			if not sprite_tex:
				if _sprite_reader == null:
					_sprite_reader = _SpriteReaderScript.new()
				sprite_tex = _sprite_reader.get_sprite_texture(abs_spr_path, sprite_id)
				if sprite_tex:
					_spr_cache[sprite_id] = sprite_tex

			if sprite_tex:
				var sprite_img := sprite_tex.get_image()
				var dest_x := (thing.width - w - 1) * 32
				var dest_y := (thing.height - h - 1) * 32
				combined_img.blit_rect(sprite_img, Rect2i(0, 0, 32, 32), Vector2i(dest_x, dest_y))

	_texture_rect.texture = ImageTexture.create_from_image(combined_img)

func _on_button_pressed() -> void:
	_load_item(int(_item_id_spin.value))
