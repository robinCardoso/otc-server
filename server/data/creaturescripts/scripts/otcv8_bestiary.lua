-- OTCv8 game_bestiary — extended opcode 207 (JSON)
-- Recebe requisições manuais do cliente

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
  end

  return true
end
