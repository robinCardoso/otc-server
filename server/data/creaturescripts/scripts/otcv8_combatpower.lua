-- OTCv8 combat power — extended opcode 203
-- Doc: docs/COMBAT-POWER.md

function onExtendedOpcode(player, opcode, buffer)
	if opcode ~= Otcv8CombatPower.OPCODE then
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

	if action == "request" or action == "combatPower" then
		if not Otcv8CombatPower.canRequest(player) then
			return true
		end
		local ok, err = pcall(function()
			Otcv8CombatPower.send(player)
		end)
		if not ok then
			print("[ExtendedOpcodeCombatPower] send failed for " .. player:getName() .. ": " .. tostring(err))
		end
	end
	return true
end
