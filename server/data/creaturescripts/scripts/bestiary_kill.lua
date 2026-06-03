-- OTCv8 game_bestiary kill tracker
-- Incrementa o número de abates de um monstro e sincroniza com o cliente em tempo real

function onKill(creature, target)
  if not creature or not creature:isPlayer() then
    return true
  end

  if not target or target:isPlayer() or target:getMaster() then
    return true
  end

  local player = creature
  local name = target:getName()

  if not BestiaryMonsterNames or not Otcv8Bestiary then
    return true
  end

  if not BestiaryMonsterSet then
    BestiaryMonsterSet = {}
    for _, monsterName in ipairs(BestiaryMonsterNames) do
      BestiaryMonsterSet[monsterName:lower()] = monsterName
    end
  end

  local matchedName = BestiaryMonsterSet[name:lower()]
  if matchedName then
    local newKills = Otcv8Bestiary.addKill(player, matchedName)
    Otcv8Bestiary.sendSingleKillUpdate(player, matchedName, newKills)
  end

  return true
end
