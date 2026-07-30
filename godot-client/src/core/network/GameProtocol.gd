# GameProtocol.gd
# Classe para gerenciar a lógica de pacotes do Game Server (Porta 7172) na Godot 4.7+
class_name TibiaGameProtocol
extends Node

const _RsaScript := preload("res://src/core/cryptography/Rsa.gd")
const _XteaScript := preload("res://src/core/cryptography/Xtea.gd")
const _OpcodeReaderScript := preload("res://src/core/network/GameOpcodeReader.gd")
const _ProtocolReaderScript := preload("res://src/core/network/ProtocolReader.gd")

const CLIENT_VERSION: int = 860
const OS_WINDOWS: int = 2

# Opcodes cliente -> servidor (TFS 8.60)
const CLIENT_WALK_OPCODES: Array[int] = [0x65, 0x66, 0x67, 0x68, 0x6A, 0x6B, 0x6C, 0x6D]

signal game_login_failed(reason: String)
signal game_login_success(login_data: Dictionary)
signal map_parsed(map_state)
signal creature_moved(creature: Dictionary, old_pos: Vector3i, new_pos: Vector3i)
signal map_updated(map_state)
signal walk_cancelled(creature: Dictionary, direction: int)
signal inventory_updated(map_state)
signal container_updated(map_state, container_id: int)

var network
var xtea_key: Array[int]
var account_name: String
var character_name: String
var password: String
var map_state = null
var login_data: Dictionary = {}

var challenge_timestamp: int = 0
var challenge_random: int = 0
var is_first_message: bool = true

func _init(network_manager, key: Array[int], acc: String, char_n: String, pass_w: String):
	network = network_manager
	xtea_key = key
	account_name = acc
	character_name = char_n
	password = pass_w
	network.packet_received.connect(_on_packet_received)

func detach_from_network() -> void:
	if network.packet_received.is_connected(_on_packet_received):
		network.packet_received.disconnect(_on_packet_received)

func _on_packet_received(packet: StreamPeerBuffer) -> void:
	if is_first_message:
		_handle_challenge(packet)
	else:
		_handle_game_message(packet)

func _handle_challenge(packet: StreamPeerBuffer) -> void:
	var raw := packet.data_array
	if raw.size() < 9:
		push_error("GameProtocol: Pacote de desafio muito curto!")
		return

	packet.get_u32()
	packet.get_u16()

	var opcode := packet.get_u8()
	if opcode != 0x1F:
		push_error("GameProtocol: Opcode de desafio inesperado: 0x%02X" % opcode)
		return

	challenge_timestamp = packet.get_u32()
	challenge_random = packet.get_u8()
	print(
		"GameProtocol: Desafio recebido! Timestamp: %d, Random: %d (0x%02X)" % [
			challenge_timestamp, challenge_random, challenge_random
		]
	)

	is_first_message = false
	_send_game_handshake()

func _send_game_handshake() -> void:
	var packet := StreamPeerBuffer.new()
	packet.put_8(0x0A)
	packet.put_16(OS_WINDOWS)
	packet.put_16(CLIENT_VERSION)

	var rsa_block := StreamPeerBuffer.new()
	rsa_block.put_8(0)
	for k in xtea_key:
		rsa_block.put_32(k)
	rsa_block.put_8(0)
	_put_tibia_string(rsa_block, account_name)
	_put_tibia_string(rsa_block, character_name)
	_put_tibia_string(rsa_block, password)
	rsa_block.put_u32(challenge_timestamp)
	rsa_block.put_u8(challenge_random)

	var current_size := rsa_block.data_array.size()
	if current_size < 128:
		var padding := PackedByteArray()
		padding.resize(128 - current_size)
		rsa_block.put_data(padding)

	var encrypted_rsa: PackedByteArray = _RsaScript.encrypt(rsa_block.data_array)
	packet.put_data(encrypted_rsa)
	print("GameProtocol: Enviando pacote de Handshake de jogo...")
	network.send_packet(packet.data_array)

func _handle_game_message(packet: StreamPeerBuffer) -> void:
	var raw := packet.data_array
	if raw.size() < 4:
		return

	var xtea_payload := raw.slice(4)
	var decrypted_bytes: PackedByteArray = _XteaScript.decrypt(xtea_payload, xtea_key)
	var dec_packet := StreamPeerBuffer.new()
	dec_packet.data_array = decrypted_bytes

	var inner_size := dec_packet.get_u16()
	if inner_size <= 0:
		return

	var end_pos := inner_size + 2
	while dec_packet.get_position() < end_pos:
		var opcode := dec_packet.get_u8()
		if not _parse_game_opcode(opcode, dec_packet, end_pos):
			push_warning(
				"GameProtocol: Interrompendo pacote no opcode 0x%02X (pos %d/%d)." % [
					opcode & 0xFF, dec_packet.get_position(), end_pos
				]
			)
			break

func _parse_game_opcode(opcode: int, packet: StreamPeerBuffer, end_pos: int = -1) -> bool:
	match opcode:
		0x0A:
			login_data = _OpcodeReaderScript.parse_login(packet)
			print(
				"GameProtocol: Login OK | Player ID: %d | Beat: %d | Report bugs: %s" % [
					login_data.player_id,
					login_data.beat_duration,
					login_data.can_report_bugs
				]
			)
			game_login_success.emit(login_data)
		0x14:
			var error_msg := _ProtocolReaderScript.read_string(packet)
			print("GameProtocol: Erro retornado pelo Game Server: ", error_msg)
			game_login_failed.emit(error_msg)
		0x64:
			map_state = _OpcodeReaderScript.parse_full_map(packet)
			map_parsed.emit(map_state)
		0x1E:
			_send_ping_response()
		_:
			var move_context := {
				"player_id": login_data.get("player_id", 0),
				"server_beat": max(login_data.get("beat_duration", 50), 1),
			}
			if _OpcodeReaderScript.consume_opcode(opcode, packet, map_state, move_context):
				if move_context.has("last_move"):
					var move: Dictionary = move_context.last_move
					creature_moved.emit(move.creature, move.old_pos, move.new_pos)
				if move_context.get("map_updated", false):
					map_updated.emit(map_state)
				if move_context.has("walk_cancel"):
					var cancel: Dictionary = move_context.walk_cancel
					walk_cancelled.emit(cancel.creature, cancel.get("direction", 0))
				if move_context.get("inventory_updated", false):
					inventory_updated.emit(map_state)
				if move_context.has("container_updated"):
					container_updated.emit(map_state, move_context.container_updated)
				print("GameProtocol: Opcode 0x%02X consumido." % (opcode & 0xFF))
			else:
				return false
	return true

func _put_tibia_string(buffer: StreamPeerBuffer, s: String) -> void:
	var utf8 := s.to_utf8_buffer()
	buffer.put_16(utf8.size())
	buffer.put_data(utf8)

func _send_ping_response() -> void:
	_send_xtea_packet(PackedByteArray([0x1E]))

func send_walk(direction: int) -> void:
	if direction < 0 or direction >= CLIENT_WALK_OPCODES.size():
		return
	_send_xtea_packet(PackedByteArray([CLIENT_WALK_OPCODES[direction]]))

func send_stop_auto_walk() -> void:
	_send_xtea_packet(PackedByteArray([0x69]))

func _send_xtea_packet(opcode_payload: PackedByteArray) -> void:
	var inner := StreamPeerBuffer.new()
	inner.put_u16(opcode_payload.size())
	inner.put_data(opcode_payload)
	var encrypted: PackedByteArray = _XteaScript.encrypt(inner.data_array, xtea_key)
	network.send_packet(encrypted)
