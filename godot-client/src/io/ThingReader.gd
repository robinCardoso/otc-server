class_name TibiaThingReader
extends RefCounted

const _DatReaderScript := preload("res://src/io/DatReader.gd")
const _ProtocolReaderScript := preload("res://src/core/network/ProtocolReader.gd")
const _ThingSpriteFactoryScript := preload("res://src/game/map/ThingSpriteFactory.gd")

# Marcadores de criatura no fluxo de things (OTC Proto::Unknown/Outdated/Creature)
const CREATURE_UNKNOWN := 97   # 0x61 — criatura desconhecida (TFS)
const CREATURE_KNOWN := 98     # 0x62 — criatura conhecida, só id (TFS)
const CREATURE_TURN := 99      # 0x63 — criatura no mapa, id + direction (OTC)
const STATIC_TEXT := 96        # 0x60 — texto no mapa (OTC/TFS em alguns tiles)

const PLAYER_START_ID := 0x10000000
const MONSTER_START_ID := 0x40000000

static func is_creature_marker(thing_id: int) -> bool:
	return thing_id in [CREATURE_UNKNOWN, CREATURE_KNOWN, CREATURE_TURN]

static func ensure_items_db() -> void:
	_ThingSpriteFactoryScript.ensure_loaded()

static func read_thing(buffer: StreamPeerBuffer, thing_id: int) -> Dictionary:
	if thing_id == STATIC_TEXT:
		return read_static_text(buffer)
	if is_creature_marker(thing_id):
		var creature := read_creature(buffer, thing_id)
		creature["kind"] = "creature"
		return creature
	var item := read_item(buffer, thing_id)
	item["kind"] = "item"
	return item

static func skip_thing(buffer: StreamPeerBuffer) -> void:
	var thing_id := buffer.get_u16()
	if thing_id == STATIC_TEXT:
		skip_static_text(buffer)
	elif is_creature_marker(thing_id):
		skip_creature(buffer, thing_id)
	else:
		skip_item(buffer, thing_id)

static func read_item(buffer: StreamPeerBuffer, item_id: int) -> Dictionary:
	ensure_items_db()
	var count := 1
	if _needs_count_byte(item_id):
		if buffer.get_available_bytes() < 1:
			push_warning("ThingReader: buffer curto para count do item %d." % item_id)
			return {"id": item_id, "count": count}
		count = buffer.get_u8()
	return {"id": item_id, "count": count}

static func skip_item(buffer: StreamPeerBuffer, item_id: int) -> void:
	read_item(buffer, item_id)

static func read_creature(buffer: StreamPeerBuffer, creature_type: int) -> Dictionary:
	var data := {"type": creature_type}

	if creature_type == CREATURE_UNKNOWN:
		data["remove_id"] = buffer.get_u32()
		data["id"] = buffer.get_u32()
		data["creature_kind"] = _creature_kind_from_id(data["id"])
		data["name"] = _ProtocolReaderScript.read_string(buffer)
	elif creature_type == CREATURE_KNOWN:
		data["id"] = buffer.get_u32()
	elif creature_type == CREATURE_TURN:
		# TFS 8.60 (sendCreatureTurn / 0x6B): apenas id + direction.
		# OTC só lê byte unpass em protocolo >= 953; em 860 não há byte extra aqui.
		data["id"] = buffer.get_u32()
		data["direction"] = buffer.get_u8()
		return data
	else:
		push_warning("ThingReader: tipo de criatura desconhecido 0x%02X" % creature_type)
		return data

	data["health_percent"] = buffer.get_u8()
	data["direction"] = buffer.get_u8()
	read_outfit(buffer, data)
	data["light_level"] = buffer.get_u8()
	data["light_color"] = buffer.get_u8()
	data["speed"] = buffer.get_u16()
	data["skull"] = buffer.get_u8()
	data["shield"] = buffer.get_u8()

	if creature_type == CREATURE_UNKNOWN:
		data["emblem"] = buffer.get_u8()

	data["unpassable"] = buffer.get_u8() == 0
	return data

static func skip_creature(buffer: StreamPeerBuffer, creature_type: int) -> void:
	read_creature(buffer, creature_type)

# OTC getStaticText()
static func read_static_text(buffer: StreamPeerBuffer) -> Dictionary:
	buffer.get_u8()
	_ProtocolReaderScript.skip_string(buffer)
	_ProtocolReaderScript.skip_string(buffer)
	return {"kind": "static_text", "id": STATIC_TEXT}

static func skip_static_text(buffer: StreamPeerBuffer) -> void:
	read_static_text(buffer)

# OTC getOutfit() para protocolo 8.60 (sem mount/wings/shaders)
static func read_outfit(buffer: StreamPeerBuffer, data: Dictionary) -> void:
	var look_type := buffer.get_u16()
	data["look_type"] = look_type
	if look_type != 0:
		data["look_head"] = buffer.get_u8()
		data["look_body"] = buffer.get_u8()
		data["look_legs"] = buffer.get_u8()
		data["look_feet"] = buffer.get_u8()
		data["look_addons"] = buffer.get_u8()
	else:
		data["look_type_ex"] = buffer.get_u16()

static func skip_outfit(buffer: StreamPeerBuffer) -> void:
	var look_type := buffer.get_u16()
	if look_type != 0:
		buffer.get_u8()
		buffer.get_u8()
		buffer.get_u8()
		buffer.get_u8()
		buffer.get_u8()
	else:
		buffer.get_u16()

static func _needs_count_byte(item_id: int) -> bool:
	if item_id <= 0:
		return false
	ensure_items_db()
	var thing = _ThingSpriteFactoryScript.get_thing(item_id, _DatReaderScript.ThingCategory.ITEM)
	# TFS NetworkMessage::addItem() so envia byte extra para stackable ou fluid/splash.
	if thing != null:
		if thing.has_flag(_DatReaderScript.ATTR_STACKABLE):
			return true
		if thing.has_flag(_DatReaderScript.ATTR_FLUID_CONTAINER) or thing.has_flag(_DatReaderScript.ATTR_SPLASH):
			return true
		return false
	# Item ausente no .dat: nao ler byte extra (evita desync).
	return false

static func _creature_kind_from_id(creature_id: int) -> String:
	if creature_id >= PLAYER_START_ID and creature_id < MONSTER_START_ID:
		return "player"
	if creature_id >= MONSTER_START_ID:
		return "monster"
	return "npc"
