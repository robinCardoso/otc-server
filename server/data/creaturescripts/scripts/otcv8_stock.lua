-- OTCv8 depot stock — extended opcode 205
-- Doc: docs/STOCK-MODULE.md

function onExtendedOpcode(player, opcode, buffer)
	if opcode ~= Otcv8Stock.OPCODE then
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

	local data = jsonData.data
	if data ~= nil and type(data) ~= "table" then
		data = {}
	end

	local handled, err = pcall(function()
		Otcv8Stock.handleAction(player, action, data)
	end)
	if not handled then
		print("[Otcv8Stock] " .. tostring(err))
		Otcv8Stock.sendResult(player, false, "Erro interno no estoque.")
	end
	return true
end
