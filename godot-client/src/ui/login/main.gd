# main.gd
extends Node2D

@onready var texture_rect = $CanvasLayer/Control/TextureRect
@onready var item_id_spin = $CanvasLayer/Control/Panel/SpinBox
@onready var status_label = $CanvasLayer/Control/Panel/LabelStatus

const SPR_PATH = "res://client/assets/Tibia.spr"
const DAT_PATH = "res://client/assets/Tibia.dat"

var dat_database: Dictionary = {}
var spr_cache: Dictionary = {}

func _ready():
	texture_rect.texture_filter = TEXTURE_FILTER_NEAREST
	
	# Carregar o banco de dados de itens do Tibia.dat
	var abs_dat_path = ProjectSettings.globalize_path(DAT_PATH)
	status_label.text = "Carregando Tibia.dat..."
	dat_database = TibiaDatReader.load_dat(abs_dat_path)
	
	# Mudar o máximo do SpinBox para o número real de itens lidos
	var total_items = dat_database[TibiaDatReader.ThingCategory.ITEM].size()
	item_id_spin.max_value = 100 + total_items - 1
	item_id_spin.value = 100 # Chão clássico (ex: ID 100)
	
	load_item(100)
	
	# Inicializar componentes de rede
	_setup_network()
	
	# Adicionar validação de e-mail na conta
	var acc_input = $CanvasLayer/Control/PanelLogin/LineEditAcc
	acc_input.text_changed.connect(_on_account_text_changed)

func _on_account_text_changed(new_text: String):
	if "@" in new_text:
		status_label.text = "AVISO: Não use e-mail! Use o Nome da Conta do jogo."
		$CanvasLayer/Control/PanelLogin/LineEditAcc.modulate = Color(1.2, 0.4, 0.4)
	else:
		if status_label.text == "AVISO: Não use e-mail! Use o Nome da Conta do jogo.":
			status_label.text = "Pronto"
		$CanvasLayer/Control/PanelLogin/LineEditAcc.modulate = Color(1.0, 1.0, 1.0)


var network_manager: TibiaNetworkManager
var protocol: TibiaProtocol

func _setup_network():
	var net_script = load("res://src/core/network/NetworkManager.gd")
	network_manager = net_script.new()
	add_child(network_manager)
	
	var proto_script = load("res://src/core/network/Protocol.gd")
	protocol = proto_script.new(network_manager)
	add_child(protocol)
	
	# Escutar conexões
	network_manager.connection_established.connect(_on_connected)
	network_manager.connection_failed.connect(_on_connection_failed)
	network_manager.connection_closed.connect(_on_connection_closed)
	
	# Escutar respostas do protocolo
	protocol.login_failed.connect(_on_login_failed)
	protocol.character_list_received.connect(_on_character_list_received)

func _on_connected():
	status_label.text = "Conectado! Enviando login..."
	var acc = $CanvasLayer/Control/PanelLogin/LineEditAcc.text
	var password = $CanvasLayer/Control/PanelLogin/LineEditPass.text
	protocol.send_login_request(acc, password)

func _on_connection_failed():
	status_label.text = "Erro: Não foi possível conectar ao servidor."

func _on_connection_closed():
	# Só mostramos conexão encerrada se não tivermos recebido erro antes
	if status_label.text == "Conectado! Enviando login...":
		status_label.text = "Conexão encerrada pelo servidor."

func _on_login_failed(reason: String):
	status_label.text = "Falha no Login: " + reason

var selected_character_data: Dictionary = {}
var char_list_panel: Panel = null

func _on_character_list_received(characters: Array, premium_days: int):
	status_label.text = "Logado! Personagens: %d | Premium: %d dias" % [characters.size(), premium_days]
	
	# Fechar lista anterior se houver
	if char_list_panel and is_instance_valid(char_list_panel):
		char_list_panel.queue_free()
		
	# Criar o Painel de Lista de Personagens dinamicamente
	char_list_panel = Panel.new()
	char_list_panel.name = "CharListPanel"
	char_list_panel.custom_minimum_size = Vector2(320, 240)
	
	# Centralizar o painel
	char_list_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	$CanvasLayer/Control.add_child(char_list_panel)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	char_list_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Selecione o Personagem:"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var item_list = ItemList.new()
	item_list.name = "ItemList"
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(item_list)
	
	for char_info in characters:
		var item_text = "%s (%s)" % [char_info.name, char_info.world]
		var idx = item_list.add_item(item_text)
		item_list.set_item_metadata(idx, char_info)
		
	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	var btn_entrar = Button.new()
	btn_entrar.text = "Entrar no Jogo"
	btn_entrar.custom_minimum_size = Vector2(120, 30)
	btn_entrar.pressed.connect(func():
		var selected_indices = item_list.get_selected_items()
		if selected_indices.size() > 0:
			var char_data = item_list.get_item_metadata(selected_indices[0])
			selected_character_data = char_data
			status_label.text = "Conectando ao Game Server com: %s" % char_data.name
			print("Selecionado: %s para conectar no Game Server %s:%d" % [char_data.name, char_data.ip, char_data.port])
			# Aqui futuramente faremos a conexão com a porta 7172
			char_list_panel.queue_free()
		else:
			status_label.text = "Selecione um personagem primeiro!"
	)
	hbox.add_child(btn_entrar)
	
	var btn_cancelar = Button.new()
	btn_cancelar.text = "Cancelar"
	btn_cancelar.custom_minimum_size = Vector2(100, 30)
	btn_cancelar.pressed.connect(func():
		char_list_panel.queue_free()
		status_label.text = "Pronto"
	)
	hbox.add_child(btn_cancelar)
	
	# Selecionar o primeiro por padrão
	if item_list.get_item_count() > 0:
		item_list.select(0)


func load_item(item_id: int):
	status_label.text = "Buscando item %d..." % item_id
	
	var items_dict = dat_database[TibiaDatReader.ThingCategory.ITEM]
	if not items_dict.has(item_id):
		status_label.text = "Item %d não encontrado!" % item_id
		texture_rect.texture = null
		return
		
	var thing: TibiaDatReader.ThingType = items_dict[item_id]
	status_label.text = "Item %d: %dx%d (Layers: %d, Sprites: %d)" % [
		item_id, thing.width, thing.height, thing.layers, thing.sprites.size()
	]
	
	if thing.sprites.size() == 0:
		texture_rect.texture = null
		return
		
	# Obter o caminho absoluto do Tibia.spr
	var abs_spr_path = ProjectSettings.globalize_path(SPR_PATH)
	
	# Criar uma imagem combinada baseada no tamanho do Item (cada bloco = 32x32)
	var final_width = thing.width * 32
	var final_height = thing.height * 32
	var combined_img = Image.create(final_width, final_height, false, Image.FORMAT_RGBA8)
	
	# Iterar e desenhar as sprites do item na ordem correta do grid
	# Tibia organiza de cima para baixo, direita para a esquerda.
	var sprite_index = 0
	for w in range(thing.width):
		for h in range(thing.height):
			if sprite_index >= thing.sprites.size():
				break
			var sprite_id = thing.sprites[sprite_index]
			sprite_index += 1
			
			if sprite_id > 0:
				var sprite_tex = spr_cache.get(sprite_id)
				if not sprite_tex:
					# Carregar do disco se não estiver no cache
					sprite_tex = TibiaSpriteReader.get_sprite_texture(abs_spr_path, sprite_id)
					if sprite_tex:
						spr_cache[sprite_id] = sprite_tex
				
				if sprite_tex:
					var sprite_img = sprite_tex.get_image()
					# Calcular a posição correta no desenho combinado (Tibia desenha de baixo/direita invertido às vezes,
					# mas o básico é o grid normal. Vamos posicionar no grid regular).
					var dest_x = (thing.width - w - 1) * 32
					var dest_y = (thing.height - h - 1) * 32
					
					combined_img.blit_rect(sprite_img, Rect2i(0, 0, 32, 32), Vector2i(dest_x, dest_y))
					
	var combined_texture = ImageTexture.create_from_image(combined_img)
	texture_rect.texture = combined_texture

func _on_button_pressed():
	var id = int(item_id_spin.value)
	load_item(id)

func _on_button_login_pressed():
	status_label.text = "Conectando ao servidor local..."
	# Iniciar conexão com a porta clássica do Login Server (7171)
	network_manager.connect_to_server("127.0.0.1", 7171)
