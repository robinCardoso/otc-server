extends Control

const ITEM_SLOT_SCENE := preload("res://src/ui/game_hud/ItemSlotView.tscn")

@onready var _map_view = $MapContainer/MapView
@onready var _status_label: Label = $HudLayer/Panel/StatusLabel
@onready var _position_label: Label = $HudLayer/Panel/PositionLabel
@onready var _inventory_slots: VBoxContainer = $HudLayer/InventoryPanel/InventorySlots
@onready var _container_content: VBoxContainer = $HudLayer/ContainerPanel/ContainerScroll/ContainerContent
@onready var _container_empty_label: Label = $HudLayer/ContainerPanel/ContainerScroll/ContainerContent/EmptyLabel
@onready var _panel: Panel = $HudLayer/Panel

var _map_state = null
var _player_id: int = 0
var _inventory_slot_views: Dictionary = {}  # slot int -> ItemSlotView
var _hp_bar: ProgressBar
var _mana_bar: ProgressBar
var _hp_label: Label
var _mana_label: Label
var _level_label: Label

func _ready() -> void:
	_map_state = GlobalNetwork.session_map_state
	if GlobalNetwork.session_world != null:
		_map_state = GlobalNetwork.session_world.get_map_state()
	var login_data: Dictionary = GlobalNetwork.session_login_data
	if _map_state == null:
		_status_label.text = "Erro: mapa da sessão não encontrado."
		return
	_player_id = login_data.get("player_id", 0)
	_build_stats_bars()
	_build_inventory_slots()
	_map_view.render(_map_state, _player_id)
	_connect_signals()
	_connect_auto_walk()
	_status_label.text = "Mundo carregado — WASD para andar, Shift+clique para auto-walk"
	_update_position_label()
	_refresh_inventory_slots()
	_refresh_container_slots()
	_refresh_player_stats_from_controller()
	set_process_unhandled_input(true)

func _build_stats_bars() -> void:
	var stats_box := VBoxContainer.new()
	stats_box.name = "StatsBox"
	stats_box.add_theme_constant_override("separation", 4)
	_panel.add_child(stats_box)
	stats_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	stats_box.offset_left = 280.0
	stats_box.offset_top = 8.0
	stats_box.offset_right = 500.0
	stats_box.offset_bottom = 72.0

	_level_label = Label.new()
	_level_label.text = "Nv. --"
	_level_label.add_theme_font_size_override("font_size", 11)
	stats_box.add_child(_level_label)

	_hp_label = Label.new()
	_hp_label.text = "HP: -- / --"
	_hp_label.add_theme_font_size_override("font_size", 10)
	stats_box.add_child(_hp_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(200, 10)
	_hp_bar.max_value = 100.0
	_hp_bar.value = 0.0
	_hp_bar.show_percentage = false
	stats_box.add_child(_hp_bar)

	_mana_label = Label.new()
	_mana_label.text = "Mana: -- / --"
	_mana_label.add_theme_font_size_override("font_size", 10)
	stats_box.add_child(_mana_label)

	_mana_bar = ProgressBar.new()
	_mana_bar.custom_minimum_size = Vector2(200, 10)
	_mana_bar.max_value = 100.0
	_mana_bar.value = 0.0
	_mana_bar.show_percentage = false
	stats_box.add_child(_mana_bar)

func _connect_auto_walk() -> void:
	var world = GlobalNetwork.session_world
	if world == null:
		return
	var player: TibiaPlayerController = world.player
	player.auto_walk.step_requested.connect(_on_auto_walk_step_requested)
	player.auto_walk.finished.connect(_on_auto_walk_finished)
	player.auto_walk.failed.connect(_on_auto_walk_failed)
	player.auto_walk.stopped.connect(_on_auto_walk_stopped)

func _on_auto_walk_step_requested(direction: int) -> void:
	GlobalNetwork.send_walk(direction)

func _on_auto_walk_finished() -> void:
	_status_label.text = "Auto-walk concluído."

func _on_auto_walk_failed(result: int) -> void:
	_status_label.text = "Auto-walk falhou (código %d)." % result

func _on_auto_walk_stopped() -> void:
	_status_label.text = "Auto-walk cancelado."

## API pública para o agente OPCODES / world — chamada via GlobalNetwork.player_stats_updated.
func update_player_stats(stats: Dictionary) -> void:
	var hp: int = stats.get("health", 0)
	var max_hp: int = maxi(stats.get("max_health", 1), 1)
	var mana: int = stats.get("mana", 0)
	var max_mana: int = maxi(stats.get("max_mana", 1), 1)
	var level: int = stats.get("level", 0)
	var level_pct: int = stats.get("level_percent", 0)

	_hp_label.text = "HP: %d / %d" % [hp, max_hp]
	_mana_label.text = "Mana: %d / %d" % [mana, max_mana]
	_level_label.text = "Nv. %d (%d%%)" % [level, level_pct]
	_hp_bar.max_value = float(max_hp)
	_hp_bar.value = float(hp)
	_mana_bar.max_value = float(max_mana)
	_mana_bar.value = float(mana)

func _refresh_player_stats_from_controller() -> void:
	var world = GlobalNetwork.session_world
	if world == null:
		return
	update_player_stats(world.player.get_stats())

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
	if GlobalNetwork.has_signal("player_stats_updated"):
		GlobalNetwork.player_stats_updated.connect(_on_player_stats_updated)

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
	if GlobalNetwork.has_signal("player_stats_updated") and GlobalNetwork.player_stats_updated.is_connected(_on_player_stats_updated):
		GlobalNetwork.player_stats_updated.disconnect(_on_player_stats_updated)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and mouse.shift_pressed:
			_try_auto_walk_to_mouse(mouse.position)
			return
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
	var world = GlobalNetwork.session_world
	if world != null:
		world.player.stop_auto_walk()
	if _map_view.is_player_walking():
		return
	if world != null and not world.player.can_walk():
		return
	GlobalNetwork.send_walk(direction)

func _try_auto_walk_to_mouse(screen_pos: Vector2) -> void:
	var world = GlobalNetwork.session_world
	if world == null or _map_state == null:
		return
	var local_pos := _map_view.to_local(screen_pos)
	var tile_pos := _map_view.screen_to_tile(local_pos)
	if world.player.auto_walk_to(tile_pos):
		world.player.try_auto_walk_step()
		_status_label.text = "Auto-walk para %s..." % tile_pos

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

func _on_creature_moved(creature: Dictionary, _old_pos: Vector3i, _new_pos: Vector3i) -> void:
	_map_view.on_creature_moved(creature, _old_pos, _new_pos)
	_update_position_label()
	var world = GlobalNetwork.session_world
	if world != null:
		world.player.on_creature_moved(creature)

func _on_map_updated(map_state) -> void:
	_map_state = map_state
	_map_view.render(_map_state, _player_id)
	_update_position_label()

func _on_walk_cancelled(creature: Dictionary, direction: int) -> void:
	_map_view.render(_map_state, _player_id)
	_update_position_label()
	var world = GlobalNetwork.session_world
	if world != null:
		world.player.on_walk_cancelled()

func _on_player_stats_updated(stats: Dictionary) -> void:
	update_player_stats(stats)

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
