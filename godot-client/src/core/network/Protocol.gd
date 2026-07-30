# Protocol.gd
# Classe para gerenciar a lógica de pacotes do Tibia 8.60 (Login e Handshake) na Godot 4.7+
class_name TibiaProtocol
extends Node

const CLIENT_VERSION: int = 860
const OS_WINDOWS: int = 2

# Chave RSA pública clássica do OTServer/Tibia 8.60 para criptografia de login.
const RSA_KEY_MODULUS: String = "142994073385517173873428945674062402123517436605273763784013145452814674751410461877969894318728515093158022204566378952402636531980838153097103289608639634937748432367507119053911666687071649938634861111669225732152643596706917637207604677761019055452601831411516084807436329416554508922849591244837568852331"
const RSA_KEY_EXPONENT: String = "65537"

signal login_failed(reason: String)
signal character_list_received(characters: Array, premium_days: int)

var network
var xtea_key: Array[int] = [0, 0, 0, 0]

func _init(network_manager):
	network = network_manager
	network.packet_received.connect(_on_packet_received)
	_generate_xtea_key()

func detach_from_network() -> void:
	if network.packet_received.is_connected(_on_packet_received):
		network.packet_received.disconnect(_on_packet_received)

# Gera 4 chaves aleatórias de 32 bits para a cifragem simétrica XTEA desta sessão
func _generate_xtea_key():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(4):
		xtea_key[i] = rng.randi()

# Envia o pacote de solicitação de Login para o servidor
func send_login_request(account_name: String, password: String):
	var packet = StreamPeerBuffer.new()
	
	# 1. Enviar informações preliminares (Total de 17 bytes antes do bloco RSA)
	packet.put_8(0x01)                     # 1 byte: Protocolo de Login (0x01)
	packet.put_16(OS_WINDOWS)              # 2 bytes: SO do Cliente (Windows)
	packet.put_16(CLIENT_VERSION)          # 2 bytes: Versão do Tibia (8.60 = 860)
	packet.put_32(1277736737)              # 4 bytes: Assinatura do Tibia.dat (0x4C27DC01)
	packet.put_32(1277298068)              # 4 bytes: Assinatura do Tibia.spr (0x4C212D94)
	packet.put_32(1455799783)              # 4 bytes: Assinatura do Tibia.pic (0x56C5DDE7)
	
	# 2. Construir o bloco RSA
	var rsa_block = StreamPeerBuffer.new()
	rsa_block.put_8(0)                     # 1 byte: RSA block padding/status (primeiro byte DEVE ser 0)
	
	# Adicionar a chave XTEA de 128 bits gerada
	for k in xtea_key:
		rsa_block.put_32(k)
	
	# Debug: mostrar chave XTEA
	print("XTEA Key: [%08X, %08X, %08X, %08X]" % [xtea_key[0] & 0xFFFFFFFF, xtea_key[1] & 0xFFFFFFFF, xtea_key[2] & 0xFFFFFFFF, xtea_key[3] & 0xFFFFFFFF])
		
	# Adicionar conta e senha usando formato de string do Tibia (prefixo de 16 bits para tamanho)
	_put_tibia_string(rsa_block, account_name)
	_put_tibia_string(rsa_block, password)
	
	# Debug: mostrar tamanho do bloco RSA antes do padding
	print("RSA block antes do padding: %d bytes" % rsa_block.data_array.size())
	
	# Fazer o preenchimento (padding) do bloco RSA para ter exatamente 128 bytes (1024 bits)
	var current_size = rsa_block.data_array.size()
	if current_size < 128:
		var padding = PackedByteArray()
		padding.resize(128 - current_size)
		# Preencher com zeros (como o OTClient faz por padrão com addPaddingBytes)
		rsa_block.put_data(padding)
		
	# Debug: mostrar TODOS os 128 bytes do bloco RSA antes da criptografia
	var rsa_plain = rsa_block.data_array
	var hex_plain = ""
	for i in range(rsa_plain.size()):
		hex_plain += "%02X" % rsa_plain[i]
	print("RSA_PLAIN_HEX=%s" % hex_plain)
	
	# 3. Criptografar o bloco RSA usando Textbook RSA (1024-bit, e=65537)
	var rsa_script = load("res://src/core/cryptography/Rsa.gd")
	var encrypted_rsa = rsa_script.encrypt(rsa_block.data_array)
	
	# Debug: mostrar TODOS os 128 bytes do resultado encriptado
	var enc_hex_full = ""
	for i in range(encrypted_rsa.size()):
		enc_hex_full += "%02X" % encrypted_rsa[i]
	print("RSA_CIPHER_HEX=%s" % enc_hex_full)
	
	packet.put_data(encrypted_rsa)
	
	# Debug: tamanho total do pacote
	print("Tamanho total do payload: %d bytes (17 header + 128 RSA)" % packet.data_array.size())
	
	# Enviar o pacote final estruturado
	network.send_packet(packet.data_array)
	print("Pacote de solicitação de login enviado!")

# Helper para escrever strings com prefixo de tamanho de 16 bits (U16) padrão do Tibia
func _put_tibia_string(buffer: StreamPeerBuffer, s: String):
	var utf8 = s.to_utf8_buffer()
	buffer.put_16(utf8.size())
	buffer.put_data(utf8)

# Callback disparado quando a rede recebe um pacote bruto
func _on_packet_received(packet: StreamPeerBuffer):
	# Debug: mostrar bytes brutos recebidos
	var raw = packet.data_array
	print("=== Pacote recebido do servidor: %d bytes ===" % raw.size())
	
	if raw.size() < 4:
		print("Pacote muito curto!")
		return
		
	# Separar o Adler32 checksum (primeiros 4 bytes) do payload encriptado XTEA
	var checksum = raw.decode_u32(0)
	var xtea_payload = raw.slice(4)
	
	print("Adler32 Checksum do pacote recebido: 0x%08X" % checksum)
	var hex_dump = ""
	for i in range(mini(64, xtea_payload.size())):
		hex_dump += "%02X " % xtea_payload[i]
	print("Payload XTEA Encrypted Hex: %s" % hex_dump)
	
	# Descriptografar APENAS o payload encriptado usando a chave XTEA
	var xtea_script = load("res://src/core/cryptography/Xtea.gd")
	var decrypted_bytes = xtea_script.decrypt(xtea_payload, xtea_key)
	
	# Debug: mostrar bytes descriptografados
	var dec_hex = ""
	for i in range(mini(32, decrypted_bytes.size())):
		dec_hex += "%02X " % decrypted_bytes[i]
	print("XTEA Decrypted (primeiros 32 bytes): %s" % dec_hex)
	
	var decrypted_packet = StreamPeerBuffer.new()
	decrypted_packet.data_array = decrypted_bytes
	
	# Em pacotes encriptados XTEA, o payload descriptografado começa com 2 bytes
	# que indicam o tamanho real do conteúdo decodificado.
	var inner_size = decrypted_packet.get_16()
	print("Inner payload size: %d" % inner_size)
	print("Inner payload size: %d" % inner_size)
	
	# O primeiro byte identifica o tipo de resposta real do servidor
	var response_type = decrypted_packet.get_8()
	print("Response opcode: 0x%02X (%d)" % [response_type & 0xFF, response_type])
	
	if response_type == 0x0A: # Erro retornado pelo servidor (ex: conta incorreta)
		var error_msg = _get_tibia_string(decrypted_packet)
		print("Erro de Login recebido do servidor: ", error_msg)
		login_failed.emit(error_msg)
	elif response_type == 0x14: # MOTD (Message of the Day)
		print("MOTD recebido!")
		var motd = _get_tibia_string(decrypted_packet)
		print("MOTD: ", motd)
		# Continuar processando — pode ter mais opcodes no mesmo pacote
		if decrypted_packet.get_position() < decrypted_bytes.size():
			var next_opcode = decrypted_packet.get_8()
			print("Próximo opcode após MOTD: 0x%02X" % (next_opcode & 0xFF))
			if next_opcode == 0x64:  # Character list
				_parse_character_list(decrypted_packet)
	elif response_type == 0x64: # Lista de personagens (Character List) sem MOTD
		print("Lista de personagens recebida (0x64)!")
		_parse_character_list(decrypted_packet)
	else:
		var unknown_msg = "Pacote desconhecido recebido: 0x%02X (Decriptado)" % (response_type & 0xFF)
		print(unknown_msg)
		login_failed.emit(unknown_msg)

func _parse_character_list(packet: StreamPeerBuffer):
	# Estrutura do pacote de Character List
	var characters_count = packet.get_8()
	print("Quantidade de personagens na conta: ", characters_count)
	
	var char_list = []
	
	for i in range(characters_count):
		var char_name = _get_tibia_string(packet)
		var world_name = _get_tibia_string(packet)
		var world_ip = packet.get_32() # IP do mundo convertido em 4 bytes (U32)
		var world_port = packet.get_16()
		
		# Converter IP U32 para formato String legível (ex: 127.0.0.1)
		var ip_str = "%d.%d.%d.%d" % [
			(world_ip >> 0) & 0xFF,
			(world_ip >> 8) & 0xFF,
			(world_ip >> 16) & 0xFF,
			(world_ip >> 24) & 0xFF
		]
		
		var char_data = {
			"name": char_name,
			"world": world_name,
			"ip": ip_str,
			"port": world_port
		}
		char_list.append(char_data)
		print("Personagem: %s | Mundo: %s | IP: %s:%d" % [char_name, world_name, ip_str, world_port])
	
	var premium_days = packet.get_16()
	print("Dias de Premium Account: ", premium_days)
	character_list_received.emit(char_list, premium_days)

# Helper para ler strings com prefixo de tamanho de 16 bits (U16) padrão do Tibia
func _get_tibia_string(buffer: StreamPeerBuffer) -> String:
	var size = buffer.get_16()
	if size <= 0:
		return ""
	var data = buffer.get_data(size)
	if data[0] != OK:
		return ""
	var bytes: PackedByteArray = data[1]
	return bytes.get_string_from_utf8()
