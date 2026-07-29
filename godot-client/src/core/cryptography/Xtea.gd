# Xtea.gd
# Classe estática para criptografia/descriptografia simétrica XTEA de pacotes do Tibia 8.60 na Godot 4.7+
class_name TibiaXtea
extends Node

const DELTA: int = 0x9e3779b9

# Descriptografa um bloco de bytes XTEA usando a chave de 4 inteiros de 32 bits (128 bits total)
static func decrypt(data: PackedByteArray, key: Array[int]) -> PackedByteArray:
	var decrypted = PackedByteArray(data)
	var size = decrypted.size()
	
	# XTEA funciona em blocos de 8 bytes (64 bits)
	# Garante que temos blocos inteiros de 8 bytes
	var blocks = size / 8
	
	for block in range(blocks):
		var offset = block * 8
		var v0 = decrypted.decode_u32(offset)
		var v1 = decrypted.decode_u32(offset + 4)
		
		var sum: int = 0xc6ef3720 # DELTA * 32
		
		for i in range(32):
			# v1 -= (((v0 << 4) ^ (v0 >> 5)) + v0) ^ (sum + key[(sum >> 11) & 3])
			var step1 = ((v0 << 4) ^ (v0 >> 5)) + v0
			var step2 = sum + key[(sum >> 11) & 3]
			v1 = (v1 - (step1 ^ step2)) & 0xFFFFFFFF
			
			sum = (sum - DELTA) & 0xFFFFFFFF
			
			# v0 -= (((v1 << 4) ^ (v1 >> 5)) + v1) ^ (sum + key[sum & 3])
			var step3 = ((v1 << 4) ^ (v1 >> 5)) + v1
			var step4 = sum + key[sum & 3]
			v0 = (v0 - (step3 ^ step4)) & 0xFFFFFFFF
			
		decrypted.encode_u32(offset, v0)
		decrypted.encode_u32(offset + 4, v1)
		
	return decrypted

# Encripta um bloco de bytes XTEA
static func encrypt(data: PackedByteArray, key: Array[int]) -> PackedByteArray:
	var encrypted = PackedByteArray(data)
	var size = encrypted.size()
	
	# Se não for múltiplo de 8, adiciona padding
	var padding = 8 - (size % 8)
	if padding < 8:
		encrypted.resize(size + padding)
		
	var blocks = encrypted.size() / 8
	
	for block in range(blocks):
		var offset = block * 8
		var v0 = encrypted.decode_u32(offset)
		var v1 = encrypted.decode_u32(offset + 4)
		
		var sum: int = 0
		
		for i in range(32):
			# v0 += (((v1 << 4) ^ (v1 >> 5)) + v1) ^ (sum + key[sum & 3])
			var step1 = ((v1 << 4) ^ (v1 >> 5)) + v1
			var step2 = sum + key[sum & 3]
			v0 = (v0 + (step1 ^ step2)) & 0xFFFFFFFF
			
			sum = (sum + DELTA) & 0xFFFFFFFF
			
			# v1 += (((v0 << 4) ^ (v0 >> 5)) + v0) ^ (sum + key[(sum >> 11) & 3])
			var step3 = ((v0 << 4) ^ (v0 >> 5)) + v0
			var step4 = sum + key[(sum >> 11) & 3]
			v1 = (v1 + (step3 ^ step4)) & 0xFFFFFFFF
			
		encrypted.encode_u32(offset, v0)
		encrypted.encode_u32(offset + 4, v1)
		
	return encrypted
