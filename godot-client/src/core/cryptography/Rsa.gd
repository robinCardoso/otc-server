# Rsa.gd
# Criptografia Textbook RSA (1024-bit, e=65537) sem padding em GDScript.
# Utiliza algoritmo bit-a-bit (double-and-add) com 32 limbs de 32-bits.
# Mantém e trata corretamente os carries de overflow para modular reduction exata.
class_name TibiaRsa
extends Node

static var N_limbs: Array = []

# Inicializa o Modulus N lendo do key.pem do servidor
static func _init_modulus():
	if N_limbs.size() > 0:
		return
		
	var pem_path = "c:/8.6/otserv_860/otc-server/server/key.pem"
	var file = FileAccess.open(pem_path, FileAccess.READ)
	if not file:
		push_error("RSA: Não foi possível abrir key.pem em: " + pem_path)
		return
		
	var base64_str = ""
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.begins_with("-----"):
			continue
		base64_str += line
	file.close()
	
	var der = Marshalls.base64_to_raw(base64_str)
	if der.size() == 0:
		push_error("RSA: DER vazio!")
		return
		
	var raw_mod = _extract_modulus(der)
	if raw_mod.size() == 0:
		push_error("RSA: Falha ao extrair Modulus do PEM/DER!")
		return
		
	if raw_mod[0] == 0:
		raw_mod = raw_mod.slice(1)
		
	if raw_mod.size() != 128:
		push_error("RSA: Tamanho de modulus inválido: %d (esperado 128)" % raw_mod.size())
		return
		
	# Mapear 128 bytes (Big-Endian) para 32 limbs de 32 bits (Little-Endian array)
	N_limbs.resize(32)
	N_limbs.fill(0)
	for i in range(32):
		var idx = 124 - (i * 4)
		N_limbs[i] = (raw_mod[idx] << 24) | (raw_mod[idx + 1] << 16) | (raw_mod[idx + 2] << 8) | raw_mod[idx + 3]
	
	var hex_str = ""
	for b in raw_mod:
		hex_str += "%02x" % b
	print("RSA Modulus N carregado com sucesso (%d bytes): %s..." % [raw_mod.size(), hex_str.substr(0, 32)])

# Extrai o INTEGER de Modulus do ASN.1 DER (suporta PKCS#1 e PKCS#8)
static func _extract_modulus(der: PackedByteArray) -> PackedByteArray:
	var pos = 0
	if der.size() < 4 or der[pos] != 0x30:
		return PackedByteArray()
	pos += 1
	pos = _skip_len(der, pos)
	
	if pos >= der.size():
		return PackedByteArray()
		
	if der[pos] == 0x02: # PKCS#1
		pos += 1
		pos = _skip_len(der, pos) # Pular versão INTEGER
		pos = _skip_val(der, pos - 1)
		if pos < der.size() and der[pos] == 0x02:
			return _read_val(der, pos)
	elif der[pos] == 0x30: # PKCS#8
		pos = _skip_tlv(der, pos) # Pular AlgoID
		if pos < der.size() and (der[pos] == 0x03 or der[pos] == 0x04):
			pos += 1
			pos = _skip_len(der, pos)
			if der[pos - 1] == 0x03: pos += 1 # Pular unused bits
			if pos < der.size() and der[pos] == 0x30:
				pos += 1
				pos = _skip_len(der, pos)
				if der[pos] == 0x02: # Version
					pos = _skip_tlv(der, pos)
				if pos < der.size() and der[pos] == 0x02:
					return _read_val(der, pos)
	return PackedByteArray()

static func _skip_len(der: PackedByteArray, pos: int) -> int:
	var b = der[pos]
	pos += 1
	if b & 0x80:
		pos += (b & 0x7F)
	return pos

static func _skip_val(der: PackedByteArray, pos: int) -> int:
	pos += 1 # tag
	var lbyte = der[pos]
	pos += 1
	var len = lbyte
	if lbyte & 0x80:
		var n = lbyte & 0x7F
		len = 0
		for i in range(n):
			len = (len << 8) | der[pos]
			pos += 1
	return pos + len

static func _skip_tlv(der: PackedByteArray, pos: int) -> int:
	return _skip_val(der, pos)

static func _read_val(der: PackedByteArray, pos: int) -> PackedByteArray:
	pos += 1 # tag 0x02
	var lbyte = der[pos]
	pos += 1
	var len = lbyte
	if lbyte & 0x80:
		var n = lbyte & 0x7F
		len = 0
		for i in range(n):
			len = (len << 8) | der[pos]
			pos += 1
	return der.slice(pos, pos + len)

# Encripta o bloco de 128 bytes: C = M^65537 mod N
static func encrypt(msg: PackedByteArray) -> PackedByteArray:
	_init_modulus()
	
	if N_limbs.size() == 0:
		push_error("RSA: Modulus N não carregado!")
		return msg
		
	var m_bytes = PackedByteArray(msg)
	if m_bytes.size() < 128:
		var pad = PackedByteArray()
		pad.resize(128 - m_bytes.size())
		m_bytes = pad + m_bytes
	elif m_bytes.size() > 128:
		m_bytes = m_bytes.slice(0, 128)
		
	var start_t = Time.get_ticks_msec()
	
	# Mapear mensagem M para 32 limbs de 32 bits
	var M = []
	M.resize(32)
	M.fill(0)
	for i in range(32):
		var idx = 124 - (i * 4)
		M[i] = (m_bytes[idx] << 24) | (m_bytes[idx + 1] << 16) | (m_bytes[idx + 2] << 8) | m_bytes[idx + 3]
		
	# C = M^65537 mod N (16 squarings + 1 mul)
	var res = Array(M)
	for i in range(16):
		res = _bigint_mod_mul(res, res)
	res = _bigint_mod_mul(res, M)
	
	var elapsed = Time.get_ticks_msec() - start_t
	print("RSA: Criptografia finalizada com sucesso em %d ms!" % elapsed)
	
	# Converter 32 limbs de volta para 128 bytes Big-Endian
	var result = PackedByteArray()
	result.resize(128)
	for i in range(32):
		var val = res[i]
		var idx = 124 - (i * 4)
		result[idx] = (val >> 24) & 0xFF
		result[idx + 1] = (val >> 16) & 0xFF
		result[idx + 2] = (val >> 8) & 0xFF
		result[idx + 3] = val & 0xFF
	return result

# Compara dois BigInts: 1 se a > b, -1 se a < b, 0 se a == b
static func _bigint_cmp(a: Array, b: Array) -> int:
	for i in range(31, -1, -1):
		var val_a = a[i] & 0xFFFFFFFF
		var val_b = b[i] & 0xFFFFFFFF
		if val_a > val_b:
			return 1
		elif val_a < val_b:
			return -1
	return 0

# Soma a + b. Retorna dicionário {"res": Array, "carry": int}
static func _bigint_add(a: Array, b: Array) -> Dictionary:
	var res = []
	res.resize(32)
	var carry: int = 0
	for i in range(32):
		var val = (a[i] & 0xFFFFFFFF) + (b[i] & 0xFFFFFFFF) + carry
		res[i] = val & 0xFFFFFFFF
		carry = val >> 32
	return {"res": res, "carry": carry}

# Subtrai a - b (assumindo a >= b na aritmética modular)
static func _bigint_sub(a: Array, b: Array) -> Array:
	var res = []
	res.resize(32)
	var carry: int = 0
	for i in range(32):
		var diff = (a[i] & 0xFFFFFFFF) - (b[i] & 0xFFFFFFFF) - carry
		if diff < 0:
			diff += 0x100000000
			carry = 1
		else:
			carry = 0
		res[i] = diff & 0xFFFFFFFF
	return res

# Shift left de 1 bit (a << 1). Retorna dicionário {"res": Array, "carry": int}
static func _bigint_shl_1(a: Array) -> Dictionary:
	var res = []
	res.resize(32)
	var carry: int = 0
	for i in range(32):
		var val = ((a[i] & 0xFFFFFFFF) << 1) | carry
		res[i] = val & 0xFFFFFFFF
		carry = (val >> 32) & 1
	return {"res": res, "carry": carry}

# Multiplicação e Módulo bit-a-bit (C = (A * B) mod N)
# Garantido 100% determinístico e sem loops infinitos
static func _bigint_mod_mul(a: Array, b: Array) -> Array:
	var res = []
	res.resize(32)
	res.fill(0)
	
	for i in range(31, -1, -1):
		var bit_val = b[i] & 0xFFFFFFFF
		for bit in range(31, -1, -1):
			# res = (res << 1) % N
			var shl_out = _bigint_shl_1(res)
			res = shl_out.res
			var carry = shl_out.carry
			
			if carry == 1 or _bigint_cmp(res, N_limbs) >= 0:
				res = _bigint_sub(res, N_limbs)
				
			# se o bit atual de 'b' estiver setado
			if (bit_val & (1 << bit)) != 0:
				var add_out = _bigint_add(res, a)
				res = add_out.res
				carry = add_out.carry
				
				if carry == 1 or _bigint_cmp(res, N_limbs) >= 0:
					res = _bigint_sub(res, N_limbs)
					
	return res
