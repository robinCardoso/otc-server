-- OTCv8 map viewport — extended opcode 206
-- Doc: docs/VIEWPORT-MODULE.md

function onExtendedOpcode(player, opcode, buffer)
	if opcode ~= Otcv8Viewport.OPCODE then
		return false
	end

	local ok, jsonData = pcall(function() return json.decode(buffer) end)
	if not ok or type(jsonData) ~= "table" then
		return false
	end

	local mode = jsonData.mode
	if type(mode) ~= "string" then
		return false
	end

	local handled, err = pcall(function()
		Otcv8Viewport.handleMode(player, mode)
	end)
	if not handled then
		print("[Otcv8Viewport] " .. tostring(err))
	end
	return true
end
