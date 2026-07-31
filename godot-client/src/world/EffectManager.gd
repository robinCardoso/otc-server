class_name TibiaEffectManager
extends RefCounted

const _EffectAnimatorScript := preload("res://src/game/effects/EffectAnimator.gd")
const _ProtocolReaderScript := preload("res://src/core/network/ProtocolReader.gd")

var _map = null

func _init(map_manager) -> void:
	_map = map_manager

func add_magic_effect(buffer: StreamPeerBuffer) -> void:
	var tile_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var effect_id := buffer.get_u8()
	if effect_id <= 0:
		return
	var tile = _map.get_or_create_tile(tile_pos)
	tile.effects.append({
		"effect_id": effect_id,
		"tile_pos": tile_pos,
		"start_ms": Time.get_ticks_msec(),
	})

func add_animated_text(buffer: StreamPeerBuffer) -> void:
	var tile_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var color := buffer.get_u8()
	var text: String = _ProtocolReaderScript.read_string(buffer)
	_map.state.active_animated_texts.append({
		"text": text,
		"color": color,
		"tile_pos": tile_pos,
		"start_ms": Time.get_ticks_msec(),
	})

func add_missile(buffer: StreamPeerBuffer) -> void:
	var from_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var to_pos: Vector3i = _ProtocolReaderScript.read_position(buffer)
	var missile_id := buffer.get_u8()
	if missile_id <= 0:
		return
	var animator := _EffectAnimatorScript
	var duration: int = animator.calc_missile_duration(from_pos, to_pos)
	var direction: int = animator.calc_missile_direction(from_pos, to_pos)
	var dx := float(to_pos.x - from_pos.x) * 32.0
	var dy := float(to_pos.y - from_pos.y) * 32.0
	_map.state.active_missiles.append({
		"missile_id": missile_id,
		"from_pos": from_pos,
		"to_pos": to_pos,
		"direction": direction,
		"delta_pixels": Vector2(dx, dy),
		"duration_ms": duration,
		"start_ms": Time.get_ticks_msec(),
	})
