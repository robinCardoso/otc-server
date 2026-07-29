# SpriteReader.gd
class_name TibiaSpriteReader
extends Node

const SPRITE_SIZE: int = 32

static func get_sprite_texture(spr_path: String, sprite_id: int) -> ImageTexture:
	if sprite_id <= 0:
		return null
		
	var file = FileAccess.open(spr_path, FileAccess.READ)
	if not file:
		push_error("Não foi possível abrir o arquivo: " + spr_path)
		return null
		
	# 1. Leitura do Cabeçalho (Tibia.spr 8.60 estendido/OTClient)
	var signature = file.get_32()
	var sprite_count = file.get_32()
	var sprites_offset = 8 # 4 bytes signature + 4 bytes count
	
	print("Tibia.spr Signature: ", String.num_uint64(signature))
	print("Sprites Count: ", sprite_count)
	
	if sprite_id > sprite_count:
		push_error("Sprite ID %d está além do limite total de sprites: %d" % [sprite_id, sprite_count])
		return null

	# 2. Localizar o endereço da sprite
	var index_offset = sprites_offset + (sprite_id - 1) * 4
	file.seek(index_offset)
	var sprite_address = file.get_32()
	
	print("Sprite Address para ID %d: %d" % [sprite_id, sprite_address])
	
	if sprite_address == 0:
		# Sprite vazia/transparente
		return null
		
	# 3. Ir para o endereço da sprite
	file.seek(sprite_address)
	
	# Pular os 3 bytes de transparência (RGB da cor chave magenta)
	var r_key = file.get_8()
	var g_key = file.get_8()
	var b_key = file.get_8()
	
	var pixel_data_size = file.get_16()
	print("Tamanho dos dados compactados (bytes): ", pixel_data_size)
	
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	
	var write_pos = 0 # Em pixels (0 a 1024)
	var read_bytes = 0
	
	# 4. Descompressão RLE
	while read_bytes < pixel_data_size and write_pos < (SPRITE_SIZE * SPRITE_SIZE):
		var transparent_pixels = file.get_16()
		var colored_pixels = file.get_16()
		read_bytes += 4
		
		# Pular pixels transparentes
		write_pos += transparent_pixels
		
		# Adicionar pixels coloridos
		for i in range(colored_pixels):
			if write_pos >= (SPRITE_SIZE * SPRITE_SIZE):
				break
			var r = file.get_8()
			var g = file.get_8()
			var b = file.get_8()
			read_bytes += 3
			
			var x = write_pos % SPRITE_SIZE
			var y = write_pos / SPRITE_SIZE
			
			img.set_pixel(x, y, Color(r / 255.0, g / 255.0, b / 255.0, 1.0))
			write_pos += 1
			
	return ImageTexture.create_from_image(img)
