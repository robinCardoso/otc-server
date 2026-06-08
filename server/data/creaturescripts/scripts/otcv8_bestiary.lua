-- OTCv8 game_bestiary — extended opcode 207 (JSON)

function onExtendedOpcode(player, opcode, buffer)
  if opcode ~= Otcv8Bestiary.OPCODE then
    return false
  end

  local ok, jsonData = pcall(function() return json.decode(buffer) end)
  if not ok or type(jsonData) ~= "table" then
    return false
  end

  local action = jsonData.action
  if action == "requestSync" then
    if Otcv8Bestiary.canRequestSync(player) then
      Otcv8Bestiary.sendFullSync(player)
    end
  elseif action == "charms_sync" then
    Otcv8BestiaryCharms.sendState(player)
  elseif action == "charms_buy" and type(jsonData.track) == "string" then
    local success, message = Otcv8BestiaryCharms.buyTrackLevel(player, jsonData.track)
    Otcv8BestiaryCharms.sendBuyResult(player, success, jsonData.track, message)
    if message and message ~= "" then
      player:sendTextMessage(MESSAGE_INFO_DESCR, message)
    end
  end

  return true
end
