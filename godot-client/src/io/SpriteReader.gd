# Leitura do Tibia.spr 8.60 (formato OTC / RLE RGBA)
extends RefCounted

const SPRITE_SIZE: int = 32

var _loaded_path: String = ""
var _sprite_count: int = 0
var _addresses: PackedInt32Array = PackedInt32Array()
var _texture_cache: Dictionary = {}

func get_sprite_texture(spr_path: String, sprite_id: int) -> ImageTexture:
	if sprite_id <= 0:
		return null

	var cache_key := "%s:%d" % [spr_path, sprite_id]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	if not ensure_index(spr_path):
		return null
	if sprite_id > _sprite_count:
		return null

	var sprite_address := _addresses[sprite_id - 1]
	if sprite_address == 0:
		return null

	var file := FileAccess.open(spr_path, FileAccess.READ)
	if not file:
		push_error("Não foi possível abrir o arquivo: " + spr_path)
		return null

	file.seek(sprite_address)
	file.get_8()
	file.get_8()
	file.get_8()

	var pixel_data_size := file.get_16()
	var pixels := PackedByteArray()
	pixels.resize(SPRITE_SIZE * SPRITE_SIZE * 4)

	var write_pos := 0
	var read_bytes := 0
	while read_bytes < pixel_data_size and write_pos < pixels.size():
		var transparent_pixels: int = file.get_16()
		var colored_pixels: int = file.get_16()
		read_bytes += 4
		write_pos += transparent_pixels * 4
		for _i in range(colored_pixels):
			if write_pos + 3 >= pixels.size():
				break
			pixels[write_pos] = file.get_8()
			pixels[write_pos + 1] = file.get_8()
			pixels[write_pos + 2] = file.get_8()
			pixels[write_pos + 3] = 0xFF
			write_pos += 4
			read_bytes += 3

	var img := Image.create_from_data(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8, pixels)
	var texture := ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = texture
	return texture

func ensure_index(spr_path: String) -> bool:
	if _loaded_path == spr_path and _sprite_count > 0:
		return true

	var file := FileAccess.open(spr_path, FileAccess.READ)
	if not file:
		push_error("Não foi possível abrir o arquivo: " + spr_path)
		return false

	var signature := file.get_32()
	_sprite_count = file.get_32()
	print("Tibia.spr Signature: ", String.num_uint64(signature))
	print("Sprites Count: ", _sprite_count)

	_addresses.resize(_sprite_count)
	for i in range(_sprite_count):
		_addresses[i] = file.get_32()

	_loaded_path = spr_path
	print("Tibia.spr: índice de %d sprites carregado." % _sprite_count)
	return true

func clear_cache() -> void:
	_texture_cache.clear()
	_loaded_path = ""
	_sprite_count = 0
	_addresses = PackedInt32Array()
