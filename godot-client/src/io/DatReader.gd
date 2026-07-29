# DatReader.gd
# Classe para ler o arquivo Tibia.dat (Versão 8.60 estendida ou padrão) na Godot 4.7+
class_name TibiaDatReader
extends Node

enum ThingCategory {
	ITEM = 0,
	CREATURE = 1,
	EFFECT = 2,
	MISSILE = 3
}

# Estrutura para armazenar as propriedades de um ThingType (Item, Criatura, etc.)
class ThingType:
	var id: int
	var category: int
	var flags: Dictionary = {}
	
	# Propriedades específicas lidas se a respectiva flag estiver ativa
	var speed: int = 0          # Se for Ground (0x00)
	var light_level: int = 0    # Se tiver Light (0x0F)
	var light_color: int = 0
	var displacement_x: int = 0 # Se tiver Offset (0x11)
	var displacement_y: int = 0
	var elevation: int = 0      # Se tiver Elevação (0x12)
	var minimap_color: int = 0  # Se tiver Minimap Color (0x19)
	
	# Composição física do objeto na grade 32x32
	var width: int = 1
	var height: int = 1
	var real_size: int = 0
	var layers: int = 1
	var pattern_x: int = 1
	var pattern_y: int = 1
	var pattern_z: int = 1
	var animation_phases: int = 1
	
	# IDs das sprites carregadas do Tibia.spr que compõem este objeto
	var sprites: Array[int] = []

static func load_dat(dat_path: String) -> Dictionary:
	var database = {
		ThingCategory.ITEM: {},
		ThingCategory.CREATURE: {},
		ThingCategory.EFFECT: {},
		ThingCategory.MISSILE: {}
	}
	
	var file = FileAccess.open(dat_path, FileAccess.READ)
	if not file:
		push_error("Não foi possível abrir o arquivo: " + dat_path)
		return database
		
	# 1. Cabeçalho (Header)
	var signature = file.get_32()
	print("Tibia.dat Signature: ", String.num_uint64(signature))
	
	# Contagem de itens por categoria
	var items_count = file.get_16()
	var creatures_count = file.get_16()
	var effects_count = file.get_16()
	var missiles_count = file.get_16()
	
	print("Dat Items: %d, Creatures: %d, Effects: %d, Missiles: %d" % [items_count, creatures_count, effects_count, missiles_count])
	
	# O ID dos itens começa em 100 no formato clássico do Tibia (IDs 1-99 são reservados/nulos)
	_read_category(file, database, ThingCategory.ITEM, 100, items_count)
	_read_category(file, database, ThingCategory.CREATURE, 1, creatures_count)
	_read_category(file, database, ThingCategory.EFFECT, 1, effects_count)
	_read_category(file, database, ThingCategory.MISSILE, 1, missiles_count)
	
	return database

static func _read_category(file: FileAccess, database: Dictionary, category: int, start_id: int, count: int):
	for i in range(1, count + 1):
		var thing_id = start_id + (i - 1)
		var thing = ThingType.new()
		thing.id = thing_id
		thing.category = category
		
		# Ler as flags físicas
		var done = false
		while not done and not file.eof_reached():
			var flag = file.get_8()
			if flag == 0xFF: # Delimitador/Fim das flags de propriedades
				done = true
				break
				
			# Mapear propriedades baseado nas flags
			thing.flags[flag] = true
			
			match flag:
				0x00: # Ground / Chão (Possui velocidade)
					thing.speed = file.get_16()
				0x0F: # Luz (Intensidade e Cor)
					thing.light_level = file.get_16()
					thing.light_color = file.get_16()
				0x11: # Offset de deslocamento na tela
					thing.displacement_x = file.get_16()
					thing.displacement_y = file.get_16()
				0x12: # Elevação (Z-axis de escadas, rampas e objetos altos)
					thing.elevation = file.get_16()
				0x19: # Cor no minimapa
					thing.minimap_color = file.get_16()
				# Outras flags sem dados adicionais a ler
				0x01, 0x02, 0x03, 0x04, 0x08, 0x0A, 0x0B, 0x0C:
					pass
				_:
					# Se for uma flag desconhecida que possa requerer dados adicionais,
					# por garantia ignoramos para não perder a sincronização de leitura de bytes.
					pass
					
		# Ler as dimensões gráficas e número de sprites
		thing.width = file.get_8()
		thing.height = file.get_8()
		if thing.width > 1 or thing.height > 1:
			thing.real_size = file.get_8()
			
		thing.layers = file.get_8()
		thing.pattern_x = file.get_8()
		thing.pattern_y = file.get_8()
		thing.pattern_z = file.get_8()
		thing.animation_phases = file.get_8()
		
		# Quantidade total de IDs de sprites para este objeto
		var total_sprites = (
			thing.width * thing.height * thing.layers * 
			thing.pattern_x * thing.pattern_y * thing.pattern_z * 
			thing.animation_phases
		)
		
		for s in range(total_sprites):
			var sprite_id = file.get_16() # Em 8.60 padrão é U16, em estendidos pode ser U32. 
			thing.sprites.append(sprite_id)
			
		database[category][thing_id] = thing
