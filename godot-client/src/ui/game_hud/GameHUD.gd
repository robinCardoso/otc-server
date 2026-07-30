extends Control

const ITEM_SLOT_SCENE := preload("res://src/ui/game_hud/ItemSlotView.tscn")

@onready var _map_view = $MapContainer/MapView
@onready var _status_label: Label = $HudLayer/Panel/StatusLabel
@onready var _position_label: Label = $HudLayer/Panel/PositionLabel
@onready var _inventory_slots: VBoxContainer = $HudLayer/InventoryPanel/InventorySlots
@onready var _container_content: VBoxContainer = $HudLayer/ContainerPanel/ContainerScroll/ContainerContent
@onready var _container_empty_label: Label = $HudLayer/ContainerPanel/ContainerScroll/ContainerContent/EmptyLabel

var _map_state = null
var _player_id: int = 0
var _inventory_slot_views: Dictionary = {}  # slot int -> ItemSlotView

func _ready() -> void:
	_map_state = GlobalNetwork.session_map_state
	var login_data: Dictionary = GlobalNetwork.session_login_data
	if _map_state == null:
		_status_label.text = "Erro: mapa da sessão não encontrado."
		return
	_player_id = login_data.get("player_id", 0)
	_build_inventory_slots()
	_map_view.render(_map_state, _player_id)
	_connect_signals()
	_status_label.text = "Mundo carregado — use setas ou WASD para andar"
	_update_position_label()
	_refresh_inventory_slots()
	_refresh_container_slots()
	set_process_unhandled_input(true)

func _build_inventory_slots() -> void:
	for child in _inventory_slots.get_children():
		child.queue_free()
	_inventory_slot_views.clear()

	for slot in range(1, 11):
		var slot_name: String = _map_state.SLOT_NAMES.get(slot, "Slot %d" % slot)
		var row := _make_equipment_row(slot_name)
		_inventory_slots.add_child(row)
		_inventory_slot_views[slot] = row.get_meta("slot_view")

func _make_equipment_row(slot_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var slot_view: TibiaItemSlotView = ITEM_SLOT_SCENE.instantiate()
	row.add_child(slot_view)

	var name_label := Label.new()
	name_label.text = slot_name
	name_label.custom_minimum_size = Vector2(72, TibiaItemSlotView.ICON_AREA)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)

	row.set_meta("slot_view", slot_view)
	return row

func _instantiate_item_slot() -> TibiaItemSlotView:
	return ITEM_SLOT_SCENE.instantiate()

func _connect_signals() -> void:
	_disconnect_signals()
	GlobalNetwork.creature_moved.connect(_on_creature_moved)
	GlobalNetwork.map_updated.connect(_on_map_updated)
	GlobalNetwork.walk_cancelled.connect(_on_walk_cancelled)
	GlobalNetwork.inventory_updated.connect(_on_inventory_updated)
	GlobalNetwork.container_updated.connect(_on_container_updated)

func _disconnect_signals() -> void:
	if GlobalNetwork.creature_moved.is_connected(_on_creature_moved):
		GlobalNetwork.creature_moved.disconnect(_on_creature_moved)
	if GlobalNetwork.map_updated.is_connected(_on_map_updated):
		GlobalNetwork.map_updated.disconnect(_on_map_updated)
	if GlobalNetwork.walk_cancelled.is_connected(_on_walk_cancelled):
		GlobalNetwork.walk_cancelled.disconnect(_on_walk_cancelled)
	if GlobalNetwork.inventory_updated.is_connected(_on_inventory_updated):
		GlobalNetwork.inventory_updated.disconnect(_on_inventory_updated)
	if GlobalNetwork.container_updated.is_connected(_on_container_updated):
		GlobalNetwork.container_updated.disconnect(_on_container_updated)

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
	_disconnect_signals()

func _on_creature_moved(_creature: Dictionary, _old_pos: Vector3i, _new_pos: Vector3i) -> void:
	_map_view.on_creature_moved(_creature, _old_pos, _new_pos)
	_update_position_label()

func _on_map_updated(map_state) -> void:
	_map_state = map_state
	_map_view.render(_map_state, _player_id)
	_update_position_label()

func _on_walk_cancelled(_creature: Dictionary, _direction: int) -> void:
	_map_view.render(_map_state, _player_id)
	_update_position_label()

func _on_inventory_updated(map_state) -> void:
	_map_state = map_state
	_refresh_inventory_slots()

func _on_container_updated(map_state, _container_id: int) -> void:
	_map_state = map_state
	_refresh_container_slots()

func _update_position_label() -> void:
	if _map_state != null:
		_position_label.text = "Posição: %s | Tiles: %d" % [_map_state.player_pos, _map_state.tile_count()]

func _refresh_inventory_slots() -> void:
	if _map_state == null:
		return
	for slot in _inventory_slot_views:
		var slot_view = _inventory_slot_views[slot]
		var item: Dictionary = _map_state.get_inventory_item(slot)
		if item.is_empty():
			slot_view.clear()
		else:
			slot_view.set_item(item)

func _refresh_container_slots() -> void:
	for child in _container_content.get_children():
		if child != _container_empty_label:
			child.queue_free()

	if _map_state == null or _map_state.containers.is_empty():
		_container_empty_label.visible = true
		return

	_container_empty_label.visible = false
	for container_id in _map_state.containers:
		var container: Dictionary = _map_state.containers[container_id]
		_container_content.add_child(_build_container_section(container_id, container))

func _build_container_section(container_id: int, container: Dictionary) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var title := Label.new()
	var items: Array = container.get("items", [])
	title.text = "%s (#%d) — %d/%d" % [
		container.get("name", "Container"),
		container_id,
		items.size(),
		container.get("capacity", 0),
	]
	title.add_theme_font_size_override("font_size", 11)
	section.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	section.add_child(grid)

	var capacity: int = maxi(int(container.get("capacity", items.size())), items.size())
	for i in range(capacity):
		var slot: TibiaItemSlotView = _instantiate_item_slot()
		grid.add_child(slot)
		if i < items.size():
			var item: Dictionary = items[i]
			if not item.is_empty():
				slot.set_item(item)

	return section
