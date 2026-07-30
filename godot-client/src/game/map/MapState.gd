class_name TibiaMapState
extends RefCounted

# Viewport do mapa em tiles — DEVE coincidir com servidor e OTCv8 (protocolo 8.60).
#
# Por que 25×20 (e não 18×14 do cliente Tibia clássico)?
# - Este TFS usa viewport ampliado OTCv8: server/src/map.h → clientMapWidth=25, Height=20.
# - O OTC habilita GameBiggerMapCache no protocolo 860 e chama resetAwareRange(12,9,12,10).
# - O opcode 0x64 (FullMap) e os scrolls 0x65–0x68 enviam exatamente width×height tiles
#   por andar; ler menos bytes desalinha o buffer (opcodes 0xFF/0x00 falsos, tiles ausentes).
# - Margens: LEFT+RIGHT+1=WIDTH e TOP+BOTTOM+1=HEIGHT (player no centro do retângulo).
const MAP_WIDTH := 25
const MAP_HEIGHT := 20
const MAP_LEFT := 12
const MAP_RIGHT := 12
const MAP_TOP := 9
const MAP_BOTTOM := 10
const _MapTileScript := preload("res://src/game/map/MapTile.gd")

var player_pos := Vector3i.ZERO
var tiles: Dictionary = {}

# Efeitos voláteis não ligados a um tile fixo
var active_missiles: Array[Dictionary] = []       # Opcode 0x85
var active_animated_texts: Array[Dictionary] = [] # Opcode 0x84

# Índice rápido creature_id → creature Dictionary (O(1) lookup)
var creature_index: Dictionary = {}  # { int: Dictionary }

# Inventário do jogador (slot CONST_SLOT_* → item Dictionary)
var inventory: Dictionary = {}  # { int: Dictionary }

# Containers abertos (container_id → Dictionary)
var containers: Dictionary = {}  # { int: Dictionary }

const SLOT_NAMES: Dictionary = {
	1: "Cabeça",
	2: "Colar",
	3: "Mochila",
	4: "Armadura",
	5: "Mão dir.",
	6: "Mão esq.",
	7: "Calças",
	8: "Pés",
	9: "Anel",
	10: "Munição",
}

func set_inventory_item(slot: int, item: Dictionary) -> void:
	if item.is_empty():
		inventory.erase(slot)
	else:
		inventory[slot] = item

func get_inventory_item(slot: int) -> Dictionary:
	return inventory.get(slot, {})

func open_container(container_id: int, data: Dictionary) -> void:
	containers[container_id] = data

func close_container(container_id: int) -> void:
	containers.erase(container_id)

func get_container(container_id: int) -> Dictionary:
	return containers.get(container_id, {})

func register_creature(creature: Dictionary) -> void:
	var cid: int = creature.get("id", 0)
	if cid > 0:
		creature_index[cid] = creature

func find_creature_by_id(creature_id: int) -> Dictionary:
	return creature_index.get(creature_id, {})

func set_tile(position: Vector3i, tile) -> void:
	tiles[_tile_key(position)] = tile

func remove_tile(position: Vector3i) -> void:
	tiles.erase(_tile_key(position))

func get_tile(position: Vector3i):
	return tiles.get(_tile_key(position))

func get_tile_at(x: int, y: int, z: int):
	return get_tile(Vector3i(x, y, z))

func get_or_create_tile(position: Vector3i):
	var tile = get_tile(position)
	if tile == null:
		tile = _MapTileScript.new()
		set_tile(position, tile)
	return tile

func tile_count() -> int:
	return tiles.size()

static func _tile_key(position: Vector3i) -> String:
	return "%d,%d,%d" % [position.x, position.y, position.z]
