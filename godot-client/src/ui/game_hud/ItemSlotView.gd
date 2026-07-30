class_name TibiaItemSlotView
extends PanelContainer

const _ThingSpriteFactoryScript := preload("res://src/game/map/ThingSpriteFactory.gd")

const ICON_AREA := 32

@onready var _icon_rect: TextureRect = $Margin/Clip/Icon
@onready var _count_label: Label = $Margin/Clip/Count

func set_item(item: Dictionary) -> void:
	if item.is_empty():
		clear()
		return

	var item_id: int = item.get("id", 0)
	if item_id <= 0:
		clear()
		return

	_ThingSpriteFactoryScript.ensure_loaded()
	var count: int = item.get("count", 1)
	var texture: Texture2D = _ThingSpriteFactoryScript.get_item_texture(
		item_id, Vector3i.ZERO, count
	)
	_apply_icon_layout(item_id, texture)

	var show_count := count > 1
	_count_label.visible = show_count
	if show_count:
		_count_label.text = str(count)

	tooltip_text = "Item %d" % item_id if count <= 1 else "Item %d x%d" % [item_id, count]

func clear() -> void:
	_icon_rect.texture = null
	_icon_rect.scale = Vector2.ONE
	_icon_rect.position = Vector2.ZERO
	_count_label.visible = false
	_count_label.text = ""
	tooltip_text = ""

func _apply_icon_layout(item_id: int, texture: Texture2D) -> void:
	if texture == null:
		return
	var tex_size: Vector2 = texture.get_size()
	var scale_factor := minf(minf(ICON_AREA / tex_size.x, ICON_AREA / tex_size.y), 1.0)
	var scaled_size := tex_size * scale_factor
	var draw_offset: Vector2i = _ThingSpriteFactoryScript.get_draw_offset_for_item(
		item_id, Vector3i.ZERO, 1
	)
	var pos := Vector2(
		(ICON_AREA - scaled_size.x) * 0.5,
		(ICON_AREA - scaled_size.y) * 0.5,
	) + Vector2(draw_offset) * scale_factor
	_icon_rect.texture = texture
	_icon_rect.position = pos
	_icon_rect.scale = Vector2(scale_factor, scale_factor)
	_icon_rect.custom_minimum_size = tex_size
