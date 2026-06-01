-- OTCv8 spell list (opcode 202) — lib compartilhada
-- Doc: docs/SPELL-LIST-MODULE.md

Otcv8SpellList = {
	OPCODE = 202,
	MAX_PACKET_SIZE = 60000,
}

local RUNE_CONJURE_PREFIXES = { "adevo ", "adana ", "adori ", "adura " }

function Otcv8SpellList.isRuneConjure(words)
	if not words or words == "" then
		return false
	end
	if words == "adori blank" then
		return true
	end
	for _, prefix in ipairs(RUNE_CONJURE_PREFIXES) do
		if words:sub(1, #prefix) == prefix then
			return true
		end
	end
	return false
end

function Otcv8SpellList.resolveCategory(spell)
	local words = spell.words or ""
	if Otcv8SpellList.isRuneConjure(words) then
		return "runes"
	end

	local group = spell.group or "support"
	if group == "attack" then
		return "attack"
	elseif group == "healing" then
		return "healing"
	end
	return "support"
end

function Otcv8SpellList.sendJSON(player, action, data)
	local buffer = json.encode({ action = action, data = data })
	local opcode = Otcv8SpellList.OPCODE
	local chunks = {}
	for i = 1, #buffer, Otcv8SpellList.MAX_PACKET_SIZE do
		chunks[#chunks + 1] = buffer:sub(i, i + Otcv8SpellList.MAX_PACKET_SIZE - 1)
	end

	if #chunks == 1 then
		return player:sendExtendedOpcode(opcode, chunks[1])
	end
	player:sendExtendedOpcode(opcode, "S" .. chunks[1])
	for i = 2, #chunks - 1 do
		player:sendExtendedOpcode(opcode, "P" .. chunks[i])
	end
	return player:sendExtendedOpcode(opcode, "E" .. chunks[#chunks])
end

function Otcv8SpellList.buildSpellEntry(spell)
	local mana = spell.mana or 0
	if spell.manapercent and spell.manapercent > 0 then
		mana = spell.manapercent .. "%"
	end

	local entry = {
		name = spell.name or "",
		words = spell.words or "",
		level = spell.level or 0,
		mlevel = spell.mlevel or 0,
		mana = mana,
		parameter = false,
		premium = false,
	}

	local ref = Spell(spell.name)
	if ref then
		entry.premium = ref:isPremium()
	end

	if spell.words and (spell.words:find('"', 1, true) or spell.words:find("'", 1, true)) then
		entry.parameter = true
	end

	if spell.group then
		entry.group = spell.group
	end
	entry.category = Otcv8SpellList.resolveCategory(spell)

	return entry
end

function Otcv8SpellList.buildPlayerSpellList(player)
	local raw = player:getInstantSpells()
	local spells = {}

	for _, spell in ipairs(raw) do
		if spell.name and spell.words and spell.name ~= "" then
			spells[#spells + 1] = Otcv8SpellList.buildSpellEntry(spell)
		end
	end

	table.sort(spells, function(a, b)
		if a.level == b.level then
			return a.name < b.name
		end
		return a.level < b.level
	end)

	local vocationId = player:getVocation():getId()
	return {
		vocation = vocationId,
		level = player:getLevel(),
		maglevel = player:getMagicLevel(),
		count = #spells,
		spells = spells,
	}
end

function Otcv8SpellList.send(player)
	return Otcv8SpellList.sendJSON(player, "spellList", Otcv8SpellList.buildPlayerSpellList(player))
end
