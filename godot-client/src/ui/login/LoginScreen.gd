extends Control

@onready var _status_label: Label = $CanvasLayer/Control/LabelStatus
@onready var _acc_input: LineEdit = $CanvasLayer/Control/PanelLogin/LineEditAcc
@onready var _pass_input: LineEdit = $CanvasLayer/Control/PanelLogin/LineEditPass
@onready var _char_list_dialog: Panel = $CanvasLayer/Control/CharListDialog


func _ready() -> void:
	_bind_network_signals()
	_acc_input.text_changed.connect(_on_account_text_changed)
	_char_list_dialog.character_selected.connect(_on_character_selected)
	_char_list_dialog.cancelled.connect(_on_char_list_cancelled)


func _exit_tree() -> void:
	_unbind_network_signals()


func _bind_network_signals() -> void:
	GlobalNetwork.connection_established.connect(_on_connected)
	GlobalNetwork.connection_failed.connect(_on_connection_failed)
	GlobalNetwork.connection_closed.connect(_on_connection_closed)
	GlobalNetwork.login_failed.connect(_on_login_failed)
	GlobalNetwork.character_list_received.connect(_on_character_list_received)
	GlobalNetwork.game_login_success.connect(_on_game_login_success)
	GlobalNetwork.game_login_failed.connect(_on_game_login_failed)
	GlobalNetwork.map_parsed.connect(_on_map_parsed)


func _unbind_network_signals() -> void:
	if GlobalNetwork.connection_established.is_connected(_on_connected):
		GlobalNetwork.connection_established.disconnect(_on_connected)
	if GlobalNetwork.connection_failed.is_connected(_on_connection_failed):
		GlobalNetwork.connection_failed.disconnect(_on_connection_failed)
	if GlobalNetwork.connection_closed.is_connected(_on_connection_closed):
		GlobalNetwork.connection_closed.disconnect(_on_connection_closed)
	if GlobalNetwork.login_failed.is_connected(_on_login_failed):
		GlobalNetwork.login_failed.disconnect(_on_login_failed)
	if GlobalNetwork.character_list_received.is_connected(_on_character_list_received):
		GlobalNetwork.character_list_received.disconnect(_on_character_list_received)
	if GlobalNetwork.game_login_success.is_connected(_on_game_login_success):
		GlobalNetwork.game_login_success.disconnect(_on_game_login_success)
	if GlobalNetwork.game_login_failed.is_connected(_on_game_login_failed):
		GlobalNetwork.game_login_failed.disconnect(_on_game_login_failed)
	if GlobalNetwork.map_parsed.is_connected(_on_map_parsed):
		GlobalNetwork.map_parsed.disconnect(_on_map_parsed)


func _on_account_text_changed(new_text: String) -> void:
	if "@" in new_text:
		_status_label.text = "AVISO: Não use e-mail! Use o Nome da Conta do jogo."
		_acc_input.modulate = Color(1.2, 0.4, 0.4)
	elif _status_label.text == "AVISO: Não use e-mail! Use o Nome da Conta do jogo.":
		_status_label.text = "Pronto"
		_acc_input.modulate = Color.WHITE


func _on_connected(mode: GlobalNetwork.ConnectionMode) -> void:
	if mode == GlobalNetwork.ConnectionMode.GAME:
		_status_label.text = "Conectado ao Game Server! Aguardando desafio..."
		return

	_status_label.text = "Conectado! Enviando login..."
	GlobalNetwork.send_login_request(_acc_input.text, _pass_input.text)


func _on_connection_failed() -> void:
	_status_label.text = "Erro: Não foi possível conectar ao servidor."


func _on_connection_closed() -> void:
	if _status_label.text == "Conectado! Enviando login...":
		_status_label.text = "Conexão encerrada pelo servidor."


func _on_login_failed(reason: String) -> void:
	_status_label.text = "Falha no Login: " + reason


func _on_character_list_received(characters: Array, premium_days: int) -> void:
	_status_label.text = "Logado! Personagens: %d | Premium: %d dias" % [characters.size(), premium_days]
	_char_list_dialog.setup(characters, premium_days)


func _on_char_list_cancelled() -> void:
	_status_label.text = "Pronto"


func _on_character_selected(char_data: Dictionary) -> void:
	_status_label.text = "Conectando ao Game Server..."
	print(
		"Selecionado: %s para conectar no Game Server %s:%d" % [
			char_data.name, char_data.ip, char_data.port
		]
	)
	GlobalNetwork.connect_to_game_server(
		char_data.ip,
		char_data.port,
		_acc_input.text,
		char_data.name,
		_pass_input.text
	)


func _on_game_login_success(login_data: Dictionary) -> void:
	_status_label.text = "Mundo conectado! Player ID: %d" % login_data.get("player_id", 0)


func _on_map_parsed(_map_state) -> void:
	_status_label.text = "Carregando sprites do mapa..."
	await get_tree().process_frame
	const _ThingSpriteFactoryScript := preload("res://src/game/map/ThingSpriteFactory.gd")
	_ThingSpriteFactoryScript.ensure_loaded()
	var map_state = GlobalNetwork.session_map_state
	var warmed := 0
	for tile_key in map_state.tiles:
		var parts: PackedStringArray = String(tile_key).split(",")
		if parts.size() != 3:
			continue
		var tile_pos := Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
		var tile = map_state.tiles[tile_key]
		for item in tile.items:
			_ThingSpriteFactoryScript.get_item_texture(
				item.get("id", 0), tile_pos, item.get("count", 1)
			)
			warmed += 1
		for creature in tile.creatures:
			var look_type: int = creature.get("look_type", 0)
			if look_type <= 0:
				look_type = creature.get("look_type_ex", 0)
			_ThingSpriteFactoryScript.get_creature_texture(
				look_type, creature.get("direction", 2)
			)
			warmed += 1
		if warmed % 64 == 0:
			_status_label.text = "Carregando sprites... (%d)" % warmed
			await get_tree().process_frame
	get_tree().change_scene_to_file("res://src/ui/game_hud/GameHUD.tscn")


func _on_game_login_failed(reason: String) -> void:
	_status_label.text = "Erro no Jogo: " + reason


func _on_button_login_pressed() -> void:
	_status_label.text = "Conectando ao servidor local..."
	GlobalNetwork.connect_to_login_server()
