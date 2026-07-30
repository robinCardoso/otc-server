extends Panel

signal character_selected(char_data: Dictionary)
signal cancelled()

@onready var _premium_label: Label = $VBox/PremiumLabel
@onready var _item_list: ItemList = $VBox/ItemList

func _ready() -> void:
	visible = false

func setup(characters: Array, premium_days: int) -> void:
	_premium_label.text = "Premium: %d dias" % premium_days
	_item_list.clear()

	for char_info in characters:
		var item_text := "%s (%s)" % [char_info.name, char_info.world]
		var idx := _item_list.add_item(item_text)
		_item_list.set_item_metadata(idx, char_info)

	if _item_list.get_item_count() > 0:
		_item_list.select(0)

	visible = true

func _on_enter_pressed() -> void:
	var selected_indices := _item_list.get_selected_items()
	if selected_indices.is_empty():
		return

	var char_data: Dictionary = _item_list.get_item_metadata(selected_indices[0])
	visible = false
	character_selected.emit(char_data)

func _on_cancel_pressed() -> void:
	visible = false
	cancelled.emit()
