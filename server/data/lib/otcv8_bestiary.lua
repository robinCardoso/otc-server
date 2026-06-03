-- OTCv8 game_bestiary sync — extended opcode 207 (JSON)
-- Kills por storage + looks oficiais (MonsterType:getOutfit) em cache no boot

Otcv8Bestiary = {
  OPCODE = 207,
  STORAGE_BASE = 150000,
  MAX_PACKET_SIZE = 6000,
  LOOKS_VERSION = 1,
  _looksBuilt = false,
  looksPayload = nil,
  _looksPending = {},
  _looksSent = {},
  _lastSyncRequest = {},
  SYNC_DEBOUNCE_SEC = 1.0,
}

function Otcv8Bestiary.getStorageKey(name)
  local hash = 5381
  local lowerName = name:lower()
  for i = 1, #lowerName do
    hash = ((hash * 33) + string.byte(lowerName, i)) % 50000
  end
  return Otcv8Bestiary.STORAGE_BASE + hash
end

function Otcv8Bestiary.getPlayerKills(player, name)
  local storage = Otcv8Bestiary.getStorageKey(name)
  local kills = player:getStorageValue(storage)
  return kills < 0 and 0 or kills
end

function Otcv8Bestiary.addKill(player, name)
  local storage = Otcv8Bestiary.getStorageKey(name)
  local currentKills = Otcv8Bestiary.getPlayerKills(player, name)
  local newKills = currentKills + 1
  player:setStorageValue(storage, newKills)
  return newKills
end

function Otcv8Bestiary.sendJSON(player, action, data)
  if not json or not json.encode then
    print("[Otcv8Bestiary] json library not loaded (see data/lib/lib.lua)")
    return false
  end

  if not player or not player:isUsingOtClient() then
    return false
  end

  local ok, buffer = pcall(json.encode, { action = action, data = data })
  if not ok or type(buffer) ~= "string" or buffer == "" then
    print(string.format("[Otcv8Bestiary] json.encode failed for action=%s: %s", tostring(action), tostring(buffer)))
    return false
  end

  local opcode = Otcv8Bestiary.OPCODE
  local chunks = {}
  for i = 1, #buffer, Otcv8Bestiary.MAX_PACKET_SIZE do
    chunks[#chunks + 1] = buffer:sub(i, i + Otcv8Bestiary.MAX_PACKET_SIZE - 1)
  end

  local function sendChunk(chunk)
    local p = Player(player:getId())
    if not p then
      return false
    end
    return p:sendExtendedOpcode(opcode, chunk)
  end

  if #chunks == 1 then
    return sendChunk(chunks[1])
  end

  if not sendChunk("S" .. chunks[1]) then
    return false
  end
  for i = 2, #chunks - 1 do
    if not sendChunk("P" .. chunks[i]) then
      return false
    end
  end
  return sendChunk("E" .. chunks[#chunks])
end

function Otcv8Bestiary.buildLooksCache()
  if Otcv8Bestiary._looksBuilt then
    return true
  end

  if not BestiaryMonsterNames then
    print("[Otcv8Bestiary] BestiaryMonsterNames nao carregado — cache de looks adiado")
    return false
  end

  local names, types, aux = {}, {}, {}
  local missing = 0

  for _, name in ipairs(BestiaryMonsterNames) do
    local lookType, lookTypeEx = 0, 0
    local mtOk, mt = pcall(MonsterType, name)
    if mtOk and mt then
      local outfitOk, outfit = pcall(function() return mt:getOutfit() end)
      if outfitOk and outfit then
        lookType = outfit.lookType or 0
        lookTypeEx = outfit.lookTypeEx or 0
      end
    else
      missing = missing + 1
    end

    names[#names + 1] = name
    types[#types + 1] = lookType
    aux[#aux + 1] = lookTypeEx
  end

  Otcv8Bestiary.looksPayload = {
    v = Otcv8Bestiary.LOOKS_VERSION,
    names = names,
    types = types,
    aux = aux,
  }
  Otcv8Bestiary._looksBuilt = true

  print(string.format(
    "[Otcv8Bestiary] Cache de looks: %d entradas (%d MonsterType ausente)",
    #names,
    missing
  ))
  return true
end

function Otcv8Bestiary.sendLooks(player)
  if not Otcv8Bestiary.buildLooksCache() then
    return false
  end
  return Otcv8Bestiary.sendJSON(player, "looks", Otcv8Bestiary.looksPayload)
end

function Otcv8Bestiary.sendKills(player)
  local killsTable = {}
  if not BestiaryMonsterNames then
    print("[Otcv8Bestiary] Erro: BestiaryMonsterNames nao carregado!")
    return false
  end

  local totalKills = 0
  local monstersWithKills = 0

  for _, name in ipairs(BestiaryMonsterNames) do
    local kills = Otcv8Bestiary.getPlayerKills(player, name)
    if kills > 0 then
      killsTable[name] = kills
      totalKills = totalKills + kills
      monstersWithKills = monstersWithKills + 1
    end
  end

  print(string.format(
    "[Otcv8Bestiary] sendKills %s: %d abates em %d especies",
    player:getName(),
    totalKills,
    monstersWithKills
  ))

  return Otcv8Bestiary.sendJSON(player, "sync", killsTable)
end

function Otcv8Bestiary.sendSingleKillUpdate(player, name, kills)
  local ok = Otcv8Bestiary.sendJSON(player, "update", { name = name, kills = kills })
  if ok then
    print(string.format("[Otcv8Bestiary] sendUpdate %s: %s = %d", player:getName(), name, kills))
  end
  return ok
end

-- Kills primeiro (pacote pequeno). Looks uma vez por sessao (chunked grande).
function Otcv8Bestiary.sendFullSync(player)
  if not player then
    return false
  end

  Otcv8Bestiary.sendKills(player)

  local pid = player:getId()
  if Otcv8Bestiary._looksSent[pid] or Otcv8Bestiary._looksPending[pid] then
    return true
  end

  Otcv8Bestiary._looksPending[pid] = true
  addEvent(function()
    Otcv8Bestiary._looksPending[pid] = nil
    local p = Player(pid)
    if p and not Otcv8Bestiary._looksSent[pid] then
      if Otcv8Bestiary.sendLooks(p) then
        Otcv8Bestiary._looksSent[pid] = true
      end
    end
  end, 1500)

  return true
end

-- Login: storages ja carregadas; reforca sync apos entrar no mundo
function Otcv8Bestiary.scheduleLoginSync(player)
  if not player then
    return
  end
  local pid = player:getId()
  addEvent(function()
    local p = Player(pid)
    if p then
      Otcv8Bestiary.sendKills(p)
    end
  end, 1500)
end

function Otcv8Bestiary.canRequestSync(player)
  if not player then
    return false
  end
  local pid = player:getId()
  local now = os.clock()
  local last = Otcv8Bestiary._lastSyncRequest[pid] or 0
  if now - last < Otcv8Bestiary.SYNC_DEBOUNCE_SEC then
    return false
  end
  Otcv8Bestiary._lastSyncRequest[pid] = now
  return true
end

function Otcv8Bestiary.scheduleStartupLooksCache()
  if Otcv8Bestiary._looksBuilt then
    return
  end
  addEvent(function()
    print("[Otcv8Bestiary] Pre-build cache de looks no startup...")
    Otcv8Bestiary.buildLooksCache()
  end, 5000)
end
