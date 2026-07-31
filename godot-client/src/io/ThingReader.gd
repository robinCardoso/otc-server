class_name TibiaThingReader
extends RefCounted

const _DatReaderScript := preload("res://src/io/DatReader.gd")
const _ProtocolReaderScript := preload("res://src/core/network/ProtocolReader.gd")
const _ThingSpriteFactoryScript := preload("res://src/game/map/ThingSpriteFactory.gd")

# Marcadores de criatura no fluxo de things (OTC Proto::Unknown/Outdated/Creature)
const CREATURE_UNKNOWN := 97   # 0x61
const CREATURE_KNOWN := 98     # 0x62
const CREATURE_TURN := 99      # 0x63
const STATIC_TEXT := 96        # 0x60

const PLAYER_START_ID := 0x10000000
const MONSTER_START_ID := 0x40000000

static func is_creature_marker(thing_id: int) -> bool:
	return thing_id in [CREATURE_UNKNOWN, CREATURE_KNOWN, CREATURE_TURN]

static func ensure_items_db() -> void:
	_ThingSpriteFactoryScript.ensure_loaded()

static func read_thing(buffer: StreamPeerBuffer, thing_id: int, strict: bool = false) -> Dictionary:
	if thing_id == STATIC_TEXT:
		return read_static_text(buffer)
	if is_creature_marker(thing_id):
		var creature := read_creature(buffer, thing_id, strict)
		creature["kind"] = "creature"
		return creature
	var item := read_item(buffer, thing_id, strict)
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

# OTC ProtocolGame::getItem() — protocolgameparse.cpp:3600
# Protocolo 8.60: sem GameThingMarks, GameCountU16, GameItemAnimationPhase.
static func read_item(buffer: StreamPeerBuffer, item_id: int, strict: bool = false) -> Dictionary:
	ensure_items_db()
	var thing = _ThingSpriteFactoryScript.get_thing(item_id, _DatReaderScript.ThingCategory.ITEM)
	if thing == null:
		var msg := "ThingReader: item id %d ausente no .dat (OTC lancaria excecao)." % item_id
		push_error(msg)
		if strict:
			return {"id": item_id, "count": 1, "parse_error": true}
		return {"id": item_id, "count": 1}

	# OTC getItem() — protocolgameparse.cpp:3613 (860: sem GameThingMarks/GameCountU16)
	var count := 1
	if thing.has_flag(_DatReaderScript.ATTR_STACKABLE) or thing.has_flag(_DatReaderScript.ATTR_CHARGEABLE):
		if buffer.get_available_bytes() < 1:
			push_error("ThingReader: buffer curto para count do item %d." % item_id)
			if strict:
				return {"id": item_id, "count": count, "parse_error": true}
			return {"id": item_id, "count": count}
		count = buffer.get_u8()
	elif thing.has_flag(_DatReaderScript.ATTR_FLUID_CONTAINER) or thing.has_flag(_DatReaderScript.ATTR_SPLASH):
		if buffer.get_available_bytes() < 1:
			push_error("ThingReader: buffer curto para count/subtype do item %d." % item_id)
			if strict:
				return {"id": item_id, "count": count, "parse_error": true}
			return {"id": item_id, "count": count}
		count = buffer.get_u8()
	return {"id": item_id, "count": count}

static func skip_item(buffer: StreamPeerBuffer, item_id: int) -> void:
	read_item(buffer, item_id)

# OTC ProtocolGame::getCreature() — protocolgameparse.cpp:3414
static func read_creature(buffer: StreamPeerBuffer, creature_type: int, strict: bool = false) -> Dictionary:
	var data := {"type": creature_type}
	# OTC: known = (type != Proto::UnknownCreature)
	var known := creature_type != CREATURE_UNKNOWN

	if creature_type == CREATURE_UNKNOWN:
		if buffer.get_available_bytes() < 8:
			return _creature_parse_error(data, strict, "buffer curto para unknown creature ids")
		data["remove_id"] = buffer.get_u32()
		data["id"] = buffer.get_u32()
		data["creature_kind"] = _creature_kind_from_id(data["id"])
		data["name"] = _ProtocolReaderScript.read_string(buffer)
	elif creature_type == CREATURE_KNOWN:
		if buffer.get_available_bytes() < 4:
			return _creature_parse_error(data, strict, "buffer curto para known creature id")
		data["id"] = buffer.get_u32()
	elif creature_type == CREATURE_TURN:
		if buffer.get_available_bytes() < 5:
			return _creature_parse_error(data, strict, "buffer curto para creature turn")
		data["id"] = buffer.get_u32()
		data["direction"] = buffer.get_u8()
		return data
	else:
		push_error("ThingReader: tipo de criatura desconhecido 0x%02X" % creature_type)
		if strict:
			data["parse_error"] = true
		return data

	data["health_percent"] = buffer.get_u8()
	data["direction"] = buffer.get_u8()
	read_outfit(buffer, data)
	data["light_level"] = buffer.get_u8()
	data["light_color"] = buffer.get_u8()
	data["speed"] = buffer.get_u16()
	data["skull"] = buffer.get_u8()
	data["shield"] = buffer.get_u8()

	# GameCreatureEmblems (>=854): emblem so em criatura desconhecida (!known)
	if not known:
		data["emblem"] = buffer.get_u8()

	# protocol >= 854: byte unpass (OTC getCreature)
	data["unpassable"] = buffer.get_u8() == 0
	return data

static func _creature_parse_error(data: Dictionary, strict: bool, reason: String) -> Dictionary:
	push_error("ThingReader: %s" % reason)
	if strict:
		data["parse_error"] = true
	return data

static func is_valid_item_id(thing_id: int) -> bool:
	if thing_id <= 99 or thing_id >= 0xFF00:
		return false
	if is_creature_marker(thing_id) or thing_id == STATIC_TEXT:
		return false
	ensure_items_db()
	return _ThingSpriteFactoryScript.get_thing(thing_id, _DatReaderScript.ThingCategory.ITEM) != null

static func skip_creature(buffer: StreamPeerBuffer, creature_type: int) -> void:
	read_creature(buffer, creature_type)

static func read_static_text(buffer: StreamPeerBuffer) -> Dictionary:
	buffer.get_u8()
	_ProtocolReaderScript.skip_string(buffer)
	_ProtocolReaderScript.skip_string(buffer)
	return {"kind": "static_text", "id": STATIC_TEXT}

static func skip_static_text(buffer: StreamPeerBuffer) -> void:
	read_static_text(buffer)

# OTC getOutfit() — 8.60
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

static func _creature_kind_from_id(creature_id: int) -> String:
	if creature_id >= PLAYER_START_ID and creature_id < MONSTER_START_ID:
		return "player"
	if creature_id >= MONSTER_START_ID:
		return "monster"
	return "npc"

# Verifica layout de bytes de getItem() sem servidor (synthetic buffers).
static func run_item_read_self_tests() -> bool:
	ensure_items_db()
	var stackable_id := _first_item_with_flag(_DatReaderScript.ATTR_STACKABLE)
	var fluid_id := _first_item_with_flag(_DatReaderScript.ATTR_FLUID_CONTAINER)
	var plain_id := _first_plain_item()
	if stackable_id < 0 or fluid_id < 0 or plain_id < 0:
		push_error("ThingReader self-test: nao encontrou itens de referencia no .dat.")
		return false

	var buf := StreamPeerBuffer.new()
	buf.big_endian = false
	buf.put_u16(stackable_id)
	buf.put_u8(42)
	buf.seek(2)
	var stacked := read_item(buf, stackable_id, true)
	if stacked.get("parse_error", false) or stacked.get("count", 0) != 42 or buf.get_position() != 3:
		push_error("ThingReader self-test: stackable count falhou (id=%d)." % stackable_id)
		return false

	buf = StreamPeerBuffer.new()
	buf.big_endian = false
	buf.put_u16(plain_id)
	buf.seek(2)
	var plain := read_item(buf, plain_id, true)
	if plain.get("parse_error", false) or plain.get("count", 1) != 1 or buf.get_position() != 2:
		push_error("ThingReader self-test: item simples consumiu bytes extras (id=%d)." % plain_id)
		return false

	buf = StreamPeerBuffer.new()
	buf.big_endian = false
	buf.put_u16(fluid_id)
	buf.put_u8(3)
	buf.seek(2)
	var fluid := read_item(buf, fluid_id, true)
	if fluid.get("parse_error", false) or fluid.get("count", 0) != 3 or buf.get_position() != 3:
		push_error("ThingReader self-test: fluid count falhou (id=%d)." % fluid_id)
		return false

	print("ThingReader: self-tests getItem OK (stackable=%d plain=%d fluid=%d)." % [
		stackable_id, plain_id, fluid_id
	])
	return true

static func _first_item_with_flag(flag: int) -> int:
	ensure_items_db()
	for item_id in range(100, 5000):
		var thing = _ThingSpriteFactoryScript.get_thing(item_id, _DatReaderScript.ThingCategory.ITEM)
		if thing != null and thing.has_flag(flag):
			return item_id
	return -1

static func _first_plain_item() -> int:
	ensure_items_db()
	for item_id in range(100, 5000):
		var thing = _ThingSpriteFactoryScript.get_thing(item_id, _DatReaderScript.ThingCategory.ITEM)
		if thing == null:
			continue
		if thing.has_flag(_DatReaderScript.ATTR_STACKABLE):
			continue
		if thing.has_flag(_DatReaderScript.ATTR_CHARGEABLE):
			continue
		if thing.has_flag(_DatReaderScript.ATTR_FLUID_CONTAINER):
			continue
		if thing.has_flag(_DatReaderScript.ATTR_SPLASH):
			continue
		return item_id
	return -1
