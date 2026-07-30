extends Node

const _NetworkManagerScript := preload("res://src/core/network/NetworkManager.gd")
const _LoginProtocolScript := preload("res://src/core/network/Protocol.gd")
const _GameProtocolPath := "res://src/core/network/GameProtocol.gd"

enum ConnectionMode {
	NONE,
	LOGIN,
	GAME,
}

signal connection_established(mode: ConnectionMode)
signal connection_failed
signal connection_closed
signal game_server_ready

signal login_failed(reason: String)
signal character_list_received(characters: Array, premium_days: int)
signal game_login_success(login_data: Dictionary)
signal game_login_failed(reason: String)
signal map_parsed(map_state)
signal creature_moved(creature: Dictionary, old_pos: Vector3i, new_pos: Vector3i)
signal map_updated(map_state)
signal walk_cancelled(creature: Dictionary, direction: int)
signal inventory_updated(map_state)
signal container_updated(map_state, container_id: int)

var network_manager
var login_protocol
var game_protocol
var connection_mode: ConnectionMode = ConnectionMode.NONE
var xtea_key_session: Array[int] = [0, 0, 0, 0]
var session_map_state = null
var session_login_data: Dictionary = {}

const _ThingSpriteFactoryScript := preload("res://src/game/map/ThingSpriteFactory.gd")

const DEFAULT_LOGIN_HOST := "127.0.0.1"
const DEFAULT_LOGIN_PORT := 7171


func _ready() -> void:
	network_manager = _NetworkManagerScript.new()
	add_child(network_manager)
	network_manager.connection_established.connect(_on_network_connected)
	network_manager.connection_failed.connect(_on_network_failed)
	network_manager.connection_closed.connect(_on_network_closed)
	call_deferred("_preload_client_assets")

func _preload_client_assets() -> void:
	_ThingSpriteFactoryScript.ensure_loaded()


func connect_to_login_server(
	host: String = DEFAULT_LOGIN_HOST,
	port: int = DEFAULT_LOGIN_PORT
) -> Error:
	_clear_protocols()
	connection_mode = ConnectionMode.LOGIN
	login_protocol = _LoginProtocolScript.new(network_manager)
	add_child(login_protocol)
	_bind_login_protocol_signals()
	return network_manager.connect_to_server(host, port)


func connect_to_game_server(
	ip: String,
	port: int,
	account: String,
	character: String,
	password: String
) -> Error:
	if login_protocol and is_instance_valid(login_protocol):
		xtea_key_session = login_protocol.xtea_key

	_detach_login_protocol()
	network_manager.disconnect_server()

	connection_mode = ConnectionMode.GAME
	var game_proto_script: GDScript = load(_GameProtocolPath) as GDScript
	if game_proto_script == null:
		push_error(
			"GlobalNetwork: falha ao carregar GameProtocol.gd. Verifique erros de parse em GameProtocol/GameOpcodeReader."
		)
		return ERR_CANT_OPEN
	game_protocol = game_proto_script.new(
		network_manager,
		xtea_key_session,
		account,
		character,
		password
	)
	add_child(game_protocol)
	_bind_game_protocol_signals()
	return network_manager.connect_to_server(ip, port)


func send_login_request(account_name: String, password: String) -> void:
	if login_protocol:
		login_protocol.send_login_request(account_name, password)


func close_session() -> void:
	_clear_protocols()
	network_manager.disconnect_server()
	connection_mode = ConnectionMode.NONE


func is_connected_to_game_server() -> bool:
	return connection_mode == ConnectionMode.GAME and network_manager.is_connected_to_host


func send_walk(direction: int) -> void:
	if game_protocol and is_connected_to_game_server():
		game_protocol.send_walk(direction)


func _bind_login_protocol_signals() -> void:
	login_protocol.login_failed.connect(login_failed.emit)
	login_protocol.character_list_received.connect(_on_character_list_received)


func _bind_game_protocol_signals() -> void:
	game_protocol.game_login_success.connect(game_login_success.emit)
	game_protocol.game_login_failed.connect(game_login_failed.emit)
	game_protocol.map_parsed.connect(_on_map_parsed)
	game_protocol.creature_moved.connect(creature_moved.emit)
	game_protocol.map_updated.connect(map_updated.emit)
	game_protocol.walk_cancelled.connect(walk_cancelled.emit)
	game_protocol.inventory_updated.connect(inventory_updated.emit)
	game_protocol.container_updated.connect(container_updated.emit)


func _on_character_list_received(characters: Array, premium_days: int) -> void:
	if login_protocol:
		xtea_key_session = login_protocol.xtea_key
	character_list_received.emit(characters, premium_days)


func _on_map_parsed(map_state) -> void:
	session_map_state = map_state
	if game_protocol:
		session_login_data = game_protocol.login_data
	map_parsed.emit(map_state)

func _on_network_connected() -> void:
	connection_established.emit(connection_mode)
	if connection_mode == ConnectionMode.GAME:
		game_server_ready.emit()


func _on_network_failed() -> void:
	connection_failed.emit()


func _on_network_closed() -> void:
	connection_closed.emit()


func _clear_protocols() -> void:
	_detach_login_protocol()
	_detach_game_protocol()


func _detach_login_protocol() -> void:
	if login_protocol and is_instance_valid(login_protocol):
		login_protocol.detach_from_network()
		login_protocol.queue_free()
	login_protocol = null


func _detach_game_protocol() -> void:
	if game_protocol and is_instance_valid(game_protocol):
		game_protocol.detach_from_network()
		game_protocol.queue_free()
	game_protocol = null
