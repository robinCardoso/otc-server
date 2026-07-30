extends Control

@onready var _map_view = $MapContainer/MapView
@onready var _status_label: Label = $HudLayer/Panel/StatusLabel
@onready var _position_label: Label = $HudLayer/Panel/PositionLabel

var _map_state = null

func _ready() -> void:
	_map_state = GlobalNetwork.session_map_state
	var login_data: Dictionary = GlobalNetwork.session_login_data
	if _map_state == null:
		_status_label.text = "Erro: mapa da sessão não encontrado."
		return
	var player_id: int = login_data.get("player_id", 0)
	_map_view.render(_map_state, player_id)
	if GlobalNetwork.creature_moved.is_connected(_on_creature_moved):
		GlobalNetwork.creature_moved.disconnect(_on_creature_moved)
	GlobalNetwork.creature_moved.connect(_on_creature_moved)
	_status_label.text = "Mundo carregado — use setas ou WASD para andar"
	_update_position_label()
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if not GlobalNetwork.is_connected_to_game_server():
		return
	var direction := _direction_from_key(key_event.keycode)
	if direction < 0:
		return
	if _map_view.is_player_walking():
		return
	GlobalNetwork.send_walk(direction)

static func _direction_from_key(keycode: Key) -> int:
	match keycode:
		KEY_UP, KEY_W:
			return 0 # Norte
		KEY_RIGHT, KEY_D:
			return 1 # Leste
		KEY_DOWN, KEY_S:
			return 2 # Sul
		KEY_LEFT, KEY_A:
			return 3 # Oeste
		KEY_KP_9, KEY_E:
			return 4 # Nordeste
		KEY_KP_3, KEY_C:
			return 5 # Sudeste
		KEY_KP_1, KEY_Z:
			return 6 # Sudoeste
		KEY_KP_7, KEY_Q:
			return 7 # Noroeste
	return -1

func _exit_tree() -> void:
	if GlobalNetwork.creature_moved.is_connected(_on_creature_moved):
		GlobalNetwork.creature_moved.disconnect(_on_creature_moved)

func _on_creature_moved(_creature: Dictionary, _old_pos: Vector3i, _new_pos: Vector3i) -> void:
	_map_view.on_creature_moved(_creature, _old_pos, _new_pos)
	_update_position_label()

func _update_position_label() -> void:
	if _map_state != null:
		_position_label.text = "Posição: %s | Tiles: %d" % [_map_state.player_pos, _map_state.tile_count()]
