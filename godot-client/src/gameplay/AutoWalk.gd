class_name TibiaAutoWalk
extends RefCounted

## Fila de passos para auto-walk (espelha LocalPlayer::autoWalk / setAutoWalkPath).
## Emite step_requested(direction) — o caller envia o pacote quando o protocolo estiver pronto.

const _PathfinderScript := preload("res://src/gameplay/Pathfinder.gd")

signal step_requested(direction: int)
signal finished()
signal failed(result: int)
signal stopped()

var _destination := Vector3i.ZERO
var _directions: Array[int] = []
var _index: int = 0
var _active: bool = false

func is_active() -> bool:
	return _active

func get_destination() -> Vector3i:
	return _destination

func remaining_steps() -> int:
	if not _active:
		return 0
	return maxi(_directions.size() - _index, 0)

func start(map_state, from_pos: Vector3i, destination: Vector3i, player_id: int = 0, flags: int = 0) -> bool:
	stop()
	_destination = destination
	var path: Dictionary = _PathfinderScript.find_path(
		map_state, from_pos, destination, _PathfinderScript.MAX_COMPLEXITY_DEFAULT, flags, player_id
	)
	var result: int = path.get("result", _PathfinderScript.Result.NO_WAY)
	if result == _PathfinderScript.Result.SAME_POSITION:
		finished.emit()
		return true
	if result != _PathfinderScript.Result.OK:
		failed.emit(result)
		return false
	_directions = path.get("directions", [])
	_index = 0
	_active = not _directions.is_empty()
	if not _active:
		failed.emit(_PathfinderScript.Result.NO_WAY)
		return false
	return true

func stop() -> void:
	if _active:
		stopped.emit()
	_active = false
	_directions.clear()
	_index = 0
	_destination = Vector3i.ZERO

## Chamar quando o jogador pode andar (can_walk == true e não está em animação).
func try_step() -> bool:
	if not _active or _index >= _directions.size():
		if _active:
			_active = false
			finished.emit()
		return false
	var direction: int = _directions[_index]
	_index += 1
	step_requested.emit(direction)
	return true

## Chamar após confirmação do servidor (creature_moved ou walk terminou).
func on_step_completed() -> void:
	if not _active:
		return
	if _index >= _directions.size():
		_active = false
		_destination = Vector3i.ZERO
		finished.emit()

func on_walk_cancelled() -> void:
	stop()
