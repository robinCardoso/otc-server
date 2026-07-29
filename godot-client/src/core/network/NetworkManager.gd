# NetworkManager.gd
# Classe para gerenciar sockets TCP e decodificação do protocolo Tibia 8.60 na Godot 4.7+
class_name TibiaNetworkManager
extends Node

signal connection_established
signal connection_closed
signal connection_failed
signal packet_received(packet: StreamPeerBuffer)

var socket: StreamPeerTCP = StreamPeerTCP.new()
var is_connected_to_host: bool = false

func _ready():
	set_process(true)

func connect_to_server(ip: String, port: int) -> Error:
	socket.disconnect_from_host()
	is_connected_to_host = false
	
	var err = socket.connect_to_host(ip, port)
	if err != OK:
		push_error("Falha ao tentar iniciar conexão com o servidor: ", err)
		connection_failed.emit()
		return err
		
	print("Tentando conectar a %s:%d..." % [ip, port])
	return OK

func disconnect_server():
	socket.disconnect_from_host()
	is_connected_to_host = false
	connection_closed.emit()
	print("Desconectado do servidor.")

func _process(_delta):
	socket.poll()
	var status = socket.get_status()
	
	# Ler pacotes se o socket estiver ativo e houver dados no buffer, independentemente de estar conectado.
	# Evita chamar get_available_bytes() quando o socket está totalmente fechado (STATUS_NONE).
	if status != StreamPeerTCP.STATUS_NONE and socket.get_available_bytes() > 0:
		_read_incoming_packets()
	
	if status == StreamPeerTCP.STATUS_CONNECTED:
		if not is_connected_to_host:
			is_connected_to_host = true
			connection_established.emit()
			print("Conexão estabelecida com sucesso!")
	elif status == StreamPeerTCP.STATUS_CONNECTING:
		pass # Ainda tentando conectar
	else:
		# STATUS_ERROR ou STATUS_NONE
		if is_connected_to_host:
			is_connected_to_host = false
			connection_closed.emit()
			print("Conexão perdida com o servidor.")
		elif socket.get_status() != StreamPeerTCP.STATUS_NONE:
			# Se o status foi para erro durante a tentativa de conexão (servidor desligado)
			socket.disconnect_from_host()
			connection_failed.emit()
			print("Não foi possível conectar ao servidor (Servidor offline).")

func _read_incoming_packets():
	var available_bytes = socket.get_available_bytes()
	if available_bytes < 2:
		return # Precisamos de pelo menos 2 bytes para ler o tamanho do pacote
		
	# 1. Ler o tamanho do pacote (Tibia envia o tamanho do payload em 2 bytes / U16)
	# Nota: StreamPeerTCP não permite "espreitar" (peek), então lemos e processamos
	var packet_size = socket.get_u16()
	
	# Aguardar até que todos os bytes do payload estejam no buffer
	var timeout = 0
	while socket.get_available_bytes() < packet_size:
		OS.delay_msec(1)
		socket.poll()
		timeout += 1
		if timeout > 1000: # Timeout de 1 segundo para evitar travamentos
			push_error("Timeout aguardando o payload do pacote.")
			disconnect_server()
			return
			
	# 2. Ler os dados do pacote
	var data = socket.get_data(packet_size)
	if data[0] != OK:
		push_error("Erro ao ler bytes do pacote do socket.")
		return
		
	var payload: PackedByteArray = data[1]
	
	# Criar um StreamPeerBuffer para facilitar a leitura sequencial de bytes no cliente
	var packet_buffer = StreamPeerBuffer.new()
	packet_buffer.data_array = payload
	
	packet_received.emit(packet_buffer)

# Função auxiliar para enviar um pacote estruturado para o servidor
func send_packet(packet_data: PackedByteArray):
	if socket.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		push_error("Não é possível enviar pacote: Não conectado ao servidor.")
		return
	
	# Calcular Adler32 checksum do payload (exigido pelo TFS 860+)
	var checksum = _adler32(packet_data)
	
	# O pacote final = [2 bytes: tamanho total] [4 bytes: checksum Adler32] [payload]
	var total_size = 4 + packet_data.size()  # checksum(4) + payload
	var header = PackedByteArray()
	header.resize(2)
	header.encode_u16(0, total_size)
	
	var checksum_bytes = PackedByteArray()
	checksum_bytes.resize(4)
	checksum_bytes.encode_u32(0, checksum)
	
	socket.put_data(header)
	socket.put_data(checksum_bytes)
	socket.put_data(packet_data)

# Calcula o Adler32 checksum (RFC 1950) — mesmo algoritmo usado pelo TFS
static func _adler32(data: PackedByteArray) -> int:
	var a: int = 1
	var b: int = 0
	const MOD_ADLER = 65521
	for byte in data:
		a = (a + byte) % MOD_ADLER
		b = (b + a) % MOD_ADLER
	return (b << 16) | a
