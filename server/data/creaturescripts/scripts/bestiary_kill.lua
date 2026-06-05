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
    -- Obtem o limite do monstro (se nao existir, fallback para 2500 que e o maximo possivel)
    local maxKills = BestiaryMonsterLimits and BestiaryMonsterLimits[matchedName] or 2500
    local currentKills = Otcv8Bestiary.getPlayerKills(player, matchedName)

    -- So processa se o jogador ainda nao atingiu o limite do bestiario para esse mob
    if currentKills < maxKills then
      local newKills = Otcv8Bestiary.addKill(player, matchedName)
      Otcv8Bestiary.sendSingleKillUpdate(player, matchedName, newKills)

      if newKills == maxKills then
        local pointsToGive = BestiaryMonsterPoints and BestiaryMonsterPoints[matchedName] or 15
        Otcv8Bestiary.addPoints(player, pointsToGive)
        
        local totalPoints = Otcv8Bestiary.getPoints(player)
        
        -- Experiencia Acumulada
        local baseExp = BestiaryMonsterExp and BestiaryMonsterExp[matchedName] or 0
        local totalBaseExp = baseExp * maxKills
        local expReward = 0
        
        if totalBaseExp > 0 then
            -- Pega o multiplicador oficial do servidor (seja do stages.xml ou config.lua rateExp)
            local expMultiplier = Game.getExperienceStage(player:getLevel())
            expReward = totalBaseExp * expMultiplier
            
            -- Da a exp para o player (true faz aparecer a exp branca subindo no char)
            player:addExperience(expReward, true)
        end
        
        local expMsg = expReward > 0 and string.format(" Alem disso, recebeu %d de experiencia acumulada!", expReward) or ""
        player:sendTextMessage(MESSAGE_INFO_DESCR, string.format("Parabens! Voce concluiu o bestiario do %s e recebeu %d Charm Points! (Total: %d).%s", matchedName, pointsToGive, totalPoints, expMsg))
      end
    end
  end

  return true
end
