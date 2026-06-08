-- Bestiary Charm upgrades — permanent bonuses bought with Charm Points (storage 149999)
-- Tracks stored in 151001+ ; config here (no C++ rebuild to rebalance costs)

Otcv8BestiaryCharms = {
  MAX_LEVEL = 20,
  BONUS_PER_LEVEL = 1, -- +1% per level

  STORAGE_MELEE = 151001,
  STORAGE_DISTANCE = 151002,
  STORAGE_MAGIC_BASE = 151010, -- physical=0 .. death=6

  COST_TIERS = {
    { maxLevel = 5, cost = 25 },
    { maxLevel = 10, cost = 50 },
    { maxLevel = 15, cost = 100 },
    { maxLevel = 20, cost = 200 },
  },

  TRACKS = {
    { id = "melee", storage = 151001, category = "attack" },
    { id = "distance", storage = 151002, category = "attack" },
    { id = "magic_physical", storage = 151010, category = "attack", element = "physical" },
    { id = "magic_earth", storage = 151011, category = "attack", element = "earth" },
    { id = "magic_fire", storage = 151012, category = "attack", element = "fire" },
    { id = "magic_ice", storage = 151013, category = "attack", element = "ice" },
    { id = "magic_energy", storage = 151014, category = "attack", element = "energy" },
    { id = "magic_holy", storage = 151015, category = "attack", element = "holy" },
    { id = "magic_death", storage = 151016, category = "attack", element = "death" },
  },
}

local CombatTypeToElement = {
  [COMBAT_PHYSICALDAMAGE] = "physical",
  [COMBAT_EARTHDAMAGE] = "earth",
  [COMBAT_FIREDAMAGE] = "fire",
  [COMBAT_ICEDAMAGE] = "ice",
  [COMBAT_ENERGYDAMAGE] = "energy",
  [COMBAT_HOLYDAMAGE] = "holy",
  [COMBAT_DEATHDAMAGE] = "death",
}

function Otcv8BestiaryCharms.getTrackById(trackId)
  for _, track in ipairs(Otcv8BestiaryCharms.TRACKS) do
    if track.id == trackId then
      return track
    end
  end
  return nil
end

function Otcv8BestiaryCharms.getCostForLevel(currentLevel)
  local nextLevel = currentLevel + 1
  if nextLevel > Otcv8BestiaryCharms.MAX_LEVEL then
    return nil
  end
  for _, tier in ipairs(Otcv8BestiaryCharms.COST_TIERS) do
    if nextLevel <= tier.maxLevel then
      return tier.cost
    end
  end
  return 200
end

function Otcv8BestiaryCharms.getTrackLevel(player, trackId)
  local track = Otcv8BestiaryCharms.getTrackById(trackId)
  if not track or not player then
    return 0
  end
  local value = player:getStorageValue(track.storage)
  if value < 0 then
    return 0
  end
  return math.min(value, Otcv8BestiaryCharms.MAX_LEVEL)
end

function Otcv8BestiaryCharms.setTrackLevel(player, trackId, level)
  local track = Otcv8BestiaryCharms.getTrackById(trackId)
  if not track or not player then
    return false
  end
  player:setStorageValue(track.storage, math.max(0, math.min(level, Otcv8BestiaryCharms.MAX_LEVEL)))
  return true
end

function Otcv8BestiaryCharms.buildTracksState(player)
  local tracks = {}
  for _, track in ipairs(Otcv8BestiaryCharms.TRACKS) do
    tracks[track.id] = Otcv8BestiaryCharms.getTrackLevel(player, track.id)
  end
  return tracks
end

function Otcv8BestiaryCharms.buyTrackLevel(player, trackId)
  if not player or not trackId then
    return false, "Dados invalidos."
  end

  local track = Otcv8BestiaryCharms.getTrackById(trackId)
  if not track then
    return false, "Trilha desconhecida."
  end

  local current = Otcv8BestiaryCharms.getTrackLevel(player, trackId)
  if current >= Otcv8BestiaryCharms.MAX_LEVEL then
    return false, "Nivel maximo atingido."
  end

  local cost = Otcv8BestiaryCharms.getCostForLevel(current)
  if not cost then
    return false, "Nivel maximo atingido."
  end

  local points = Otcv8Bestiary.getPoints(player)
  if points < cost then
    return false, string.format("Charm Points insuficientes (%d/%d).", points, cost)
  end

  player:setStorageValue(Otcv8Bestiary.POINTS_STORAGE, points - cost)
  Otcv8BestiaryCharms.setTrackLevel(player, trackId, current + 1)

  return true, string.format("Upgrade +1%% (%s): %d%% / %d%%.", trackId, current + 1, Otcv8BestiaryCharms.MAX_LEVEL)
end

function Otcv8BestiaryCharms.getMeleeBonusPercent(player)
  return Otcv8BestiaryCharms.getTrackLevel(player, "melee") * Otcv8BestiaryCharms.BONUS_PER_LEVEL
end

function Otcv8BestiaryCharms.getDistanceBonusPercent(player)
  return Otcv8BestiaryCharms.getTrackLevel(player, "distance") * Otcv8BestiaryCharms.BONUS_PER_LEVEL
end

function Otcv8BestiaryCharms.getMagicBonusPercent(player, combatType)
  if not combatType then
    return 0
  end
  local element = CombatTypeToElement[combatType]
  if not element then
    return 0
  end
  return Otcv8BestiaryCharms.getTrackLevel(player, "magic_" .. element) * Otcv8BestiaryCharms.BONUS_PER_LEVEL
end

function Otcv8BestiaryCharms.applyDamageBonus(player, damage, combatType, isDistanceWeapon)
  if not player or not damage or damage >= 0 then
    return damage
  end

  local bonus = 0
  if isDistanceWeapon then
    bonus = Otcv8BestiaryCharms.getDistanceBonusPercent(player)
  elseif combatType and combatType ~= COMBAT_PHYSICALDAMAGE and combatType ~= COMBAT_NONE then
    bonus = Otcv8BestiaryCharms.getMagicBonusPercent(player, combatType)
  else
    bonus = Otcv8BestiaryCharms.getMeleeBonusPercent(player)
  end

  if bonus <= 0 then
    return damage
  end

  return math.floor(damage * (100 + bonus) / 100)
end

function Otcv8BestiaryCharms.sendState(player)
  if not player then
    return false
  end
  return Otcv8Bestiary.sendJSON(player, "charms_state", {
    totalPoints = Otcv8Bestiary.getPoints(player),
    tracks = Otcv8BestiaryCharms.buildTracksState(player),
  })
end

function Otcv8BestiaryCharms.sendBuyResult(player, ok, trackId, message)
  if not player then
    return false
  end
  return Otcv8Bestiary.sendJSON(player, "charms_buy_result", {
    ok = ok,
    track = trackId,
    level = Otcv8BestiaryCharms.getTrackLevel(player, trackId or ""),
    totalPoints = Otcv8Bestiary.getPoints(player),
    tracks = Otcv8BestiaryCharms.buildTracksState(player),
    message = message,
  })
end
