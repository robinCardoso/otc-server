-- OTCv8 Assign Spell — extended opcode 202
-- Doc: docs/SPELL-LIST-MODULE.md

local SPELL_LIST_ENABLED = false -- disabled for testing

function onExtendedOpcode(player, opcode, buffer)
	if not SPELL_LIST_ENABLED then
		return false
	end
	if opcode ~= Otcv8SpellList.OPCODE then
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

	if action == "request" or action == "spellList" then
		Otcv8SpellList.send(player)
	end
	return true
end
