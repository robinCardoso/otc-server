-- God: /bestiarytest — pontos + mob completo + trilha Charms max (teste UI)
-- Uso:
--   /bestiarytest
--   /bestiarytest 5000, Rotworm, melee
--   /bestiarytest NomeChar, 5000, Rotworm, magic_fire

local DEFAULT_POINTS = 5000
local DEFAULT_MOB = "Rotworm"
local DEFAULT_TRACK = "melee"

local function trim(value)
  if type(value) ~= "string" then
    return ""
  end
  return value:match("^%s*(.-)%s*$") or value
end

local function resolveMonsterName(name)
  if not name or name == "" then
    return nil
  end

  if not BestiaryMonsterSet then
    BestiaryMonsterSet = {}
    for _, monsterName in ipairs(BestiaryMonsterNames or {}) do
      BestiaryMonsterSet[monsterName:lower()] = monsterName
    end
  end

  return BestiaryMonsterSet[name:lower()]
end

local function listTrackIds()
  local ids = {}
  for _, track in ipairs(Otcv8BestiaryCharms.TRACKS or {}) do
    ids[#ids + 1] = track.id
  end
  return table.concat(ids, ", ")
end

function onSay(player, words, param)
  if not player:getGroup():getAccess() then
    return true
  end

  if player:getAccountType() < ACCOUNT_TYPE_GOD then
    return false
  end

  if not Otcv8Bestiary or not Otcv8BestiaryCharms then
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "[BestiaryTest] Libs Otcv8Bestiary nao carregadas.")
    return false
  end

  local split = {}
  if param and param ~= "" then
    for part in param:gmatch("[^,]+") do
      split[#split + 1] = trim(part)
    end
  end

  local target = player
  local idx = 1

  if split[1] and Player(split[1]) then
    target = Player(split[1])
    idx = 2
  end

  local points = tonumber(split[idx]) or DEFAULT_POINTS
  local mobInput = split[idx + 1] or DEFAULT_MOB
  local trackId = split[idx + 2] or DEFAULT_TRACK

  local matchedName = resolveMonsterName(mobInput)
  if not matchedName then
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
      string.format("[BestiaryTest] Mob desconhecido: %s", mobInput))
    return false
  end

  if not Otcv8BestiaryCharms.getTrackById(trackId) then
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED,
      string.format("[BestiaryTest] Trilha invalida: %s. Validas: %s", trackId, listTrackIds()))
    return false
  end

  local maxKills = BestiaryMonsterLimits and BestiaryMonsterLimits[matchedName] or 25

  target:setStorageValue(Otcv8Bestiary.POINTS_STORAGE, math.max(0, points))
  target:setStorageValue(Otcv8Bestiary.getStorageKey(matchedName), maxKills)
  Otcv8BestiaryCharms.setTrackLevel(target, trackId, Otcv8BestiaryCharms.MAX_LEVEL)

  Otcv8Bestiary.sendKills(target)
  Otcv8BestiaryCharms.sendState(target)

  local msg = string.format(
    "[BestiaryTest] %s: %d Charm Points | %s %d/%d kills | trilha %s %d%%",
    target:getName(),
    Otcv8Bestiary.getPoints(target),
    matchedName,
    maxKills,
    maxKills,
    trackId,
    Otcv8BestiaryCharms.getTrackLevel(target, trackId) * Otcv8BestiaryCharms.BONUS_PER_LEVEL
  )

  player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
  if target ~= player then
    target:sendTextMessage(MESSAGE_INFO_DESCR, "Bestiary test aplicado por GM.")
  end

  return false
end
