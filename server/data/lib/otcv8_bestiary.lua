-- OTCv8 game_bestiary sync — extended opcode 207 (JSON)
-- Kills por storage + looks oficiais (MonsterType:getOutfit) em cache no boot

Otcv8Bestiary = {
  OPCODE = 207,
  OPCODE_LOOKS = 208,
  STORAGE_BASE = 150000,
  POINTS_STORAGE = 149999,
  MAX_PACKET_SIZE = 6000,
  LOOKS_VERSION = 1,
  ITEMS_BATCH_SIZE = 70,
  ITEMS_BATCH_DELAY_MS = 30,
  LOOKS_AFTER_ITEMS_DELAY_MS = 200,
  _looksBuilt = false,
  looksPayload = nil,
  _itemsBuilt = false,
  itemsPayload = nil,
  _looksSent = {},
  _itemsSent = {},
  _syncPipelinePending = {},
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

function Otcv8Bestiary.getPoints(player)
  local points = player:getStorageValue(Otcv8Bestiary.POINTS_STORAGE)
  return points < 0 and 0 or points
end

function Otcv8Bestiary.addPoints(player, amount)
  local current = Otcv8Bestiary.getPoints(player)
  local newTotal = current + amount
  player:setStorageValue(Otcv8Bestiary.POINTS_STORAGE, newTotal)
  return newTotal
end

function Otcv8Bestiary.sendJSON(player, action, data, customOpcode)
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

  local opcode = customOpcode or Otcv8Bestiary.OPCODE
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
  return Otcv8Bestiary.sendJSON(player, "looks", Otcv8Bestiary.looksPayload, Otcv8Bestiary.OPCODE_LOOKS)
end

function Otcv8Bestiary.collectLootItemIds(lootList, seen)
  if type(lootList) ~= "table" then
    return
  end

  for _, block in ipairs(lootList) do
    local itemId = block.itemId
    if itemId and itemId > 0 then
      seen[itemId] = true
    end
    if block.childLoot then
      Otcv8Bestiary.collectLootItemIds(block.childLoot, seen)
    end
  end
end

function Otcv8Bestiary.buildItemLookup()
  if Otcv8Bestiary._itemsBuilt then
    return true
  end

  if not BestiaryMonsterNames then
    print("[Otcv8Bestiary] BestiaryMonsterNames nao carregado — cache de itens adiado")
    return false
  end

  local seen = {}
  local monstersScanned = 0

  for _, name in ipairs(BestiaryMonsterNames) do
    local mtOk, mt = pcall(MonsterType, name)
    if mtOk and mt then
      local lootOk, loot = pcall(function() return mt:getLoot() end)
      if lootOk and loot then
        Otcv8Bestiary.collectLootItemIds(loot, seen)
        monstersScanned = monstersScanned + 1
      end
    end
  end

  local payload = {}
  local mapped = 0

  for serverId, _ in pairs(seen) do
    local itOk, itemType = pcall(ItemType, serverId)
    if itOk and itemType then
      local clientId = itemType:getClientId() or 0
      local itemName = itemType:getName() or ""
      if clientId > 0 then
        payload[tostring(serverId)] = { c = clientId, n = itemName }
        mapped = mapped + 1
      end
    end
  end

  Otcv8Bestiary.itemsPayload = payload
  Otcv8Bestiary._itemsBuilt = true

  print(string.format(
    "[Otcv8Bestiary] Cache de itens: %d serverIds (%d monstros com loot)",
    mapped,
    monstersScanned
  ))
  return true
end

function Otcv8Bestiary.buildItemBatches()
  if not Otcv8Bestiary.buildItemLookup() then
    return nil, 0
  end

  local batches = {}
  local current = {}
  local currentSize = 0
  local totalEntries = 0

  for serverId, entry in pairs(Otcv8Bestiary.itemsPayload) do
    current[serverId] = entry
    currentSize = currentSize + 1
    totalEntries = totalEntries + 1
    if currentSize >= Otcv8Bestiary.ITEMS_BATCH_SIZE then
      batches[#batches + 1] = current
      current = {}
      currentSize = 0
    end
  end

  if currentSize > 0 or #batches == 0 then
    batches[#batches + 1] = current
  end

  return batches, totalEntries
end

function Otcv8Bestiary.sendItemsBatched(player, onComplete)
  local batches, totalEntries = Otcv8Bestiary.buildItemBatches()
  if not batches then
    if onComplete then
      onComplete(false)
    end
    return false
  end

  local pid = player:getId()
  local batchIndex = 1

  print(string.format(
    "[Otcv8Bestiary] sendItems %s: %d lotes, %d entradas",
    player:getName(),
    #batches,
    totalEntries
  ))

  local function sendNextBatch()
    local p = Player(pid)
    if not p then
      if onComplete then
        onComplete(false)
      end
      return
    end

    if batchIndex <= #batches then
      if not Otcv8Bestiary.sendJSON(p, "items", batches[batchIndex]) then
        if onComplete then
          onComplete(false)
        end
        return
      end
      batchIndex = batchIndex + 1
      addEvent(sendNextBatch, Otcv8Bestiary.ITEMS_BATCH_DELAY_MS)
      return
    end

    if Otcv8Bestiary.sendJSON(p, "itemsDone", { total = totalEntries }) then
      Otcv8Bestiary._itemsSent[pid] = true
      if onComplete then
        onComplete(true)
      end
    elseif onComplete then
      onComplete(false)
    end
  end

  sendNextBatch()
  return true
end

function Otcv8Bestiary.sendLooksIfNeeded(player)
  if not player then
    return false
  end

  local pid = player:getId()
  if Otcv8Bestiary._looksSent[pid] then
    return true
  end

  if Otcv8Bestiary.sendLooks(player) then
    Otcv8Bestiary._looksSent[pid] = true
    return true
  end
  return false
end

function Otcv8Bestiary.finishSyncPipeline(pid)
  Otcv8Bestiary._syncPipelinePending[pid] = nil
end

function Otcv8Bestiary.scheduleLooksAfterItems(pid)
  addEvent(function()
    local p = Player(pid)
    if p then
      Otcv8Bestiary.sendLooksIfNeeded(p)
    end
    Otcv8Bestiary.finishSyncPipeline(pid)
  end, Otcv8Bestiary.LOOKS_AFTER_ITEMS_DELAY_MS)
end

function Otcv8Bestiary.startSyncPipeline(player)
  if not player then
    return false
  end

  local pid = player:getId()
  if Otcv8Bestiary._syncPipelinePending[pid] then
    return false
  end

  Otcv8Bestiary._syncPipelinePending[pid] = true
  Otcv8Bestiary.sendKills(player)

  if not Otcv8Bestiary._itemsSent[pid] then
    Otcv8Bestiary.sendItemsBatched(player, function(ok)
      if not ok then
        Otcv8Bestiary.finishSyncPipeline(pid)
        return
      end
      Otcv8Bestiary.scheduleLooksAfterItems(pid)
    end)
    return true
  end

  if Otcv8Bestiary._looksSent[pid] then
    Otcv8Bestiary.finishSyncPipeline(pid)
    return true
  end

  if Otcv8Bestiary.sendLooksIfNeeded(player) then
    Otcv8Bestiary.finishSyncPipeline(pid)
  else
    Otcv8Bestiary.finishSyncPipeline(pid)
  end
  return true
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

-- Pipeline serial: kills -> items (lotes sem chunk) -> looks (chunked).
function Otcv8Bestiary.sendFullSync(player)
  if not player then
    return false
  end
  return Otcv8Bestiary.startSyncPipeline(player)
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
  if Otcv8Bestiary._syncPipelinePending[pid] then
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

function Otcv8Bestiary.scheduleStartupItemLookup()
  if Otcv8Bestiary._itemsBuilt then
    return
  end
  addEvent(function()
    print("[Otcv8Bestiary] Pre-build cache de itens no startup...")
    Otcv8Bestiary.buildItemLookup()
  end, 5000)
end
