-- OTCv8 party — extended opcode 204 (status + minimap)

function onExtendedOpcode(player, opcode, buffer)
	if opcode ~= Otcv8Party.OPCODE then
		return false
	end

	local ok, jsonData = pcall(function() return json.decode(buffer) end)
	if not ok or type(jsonData) ~= "table" then
		return false
	end

	local action = jsonData.action
	if type(action) ~= "string" then
		return false
	end

	if action == "request" or action == "partyStatus" or action == "partyMinimap" then
		Otcv8Party.send(player)
	end
	return true
end
