-- !spelllist — diagnostico + envia opcode 202 ao cliente
-- Doc: docs/SPELL-LIST-MODULE.md

local function findSpellByName(spells, name)
	local lower = name:lower()
	for _, spell in ipairs(spells) do
		if spell.name and spell.name:lower() == lower then
			return spell
		end
	end
	return nil
end

function onSay(player, words, param)
	local spells = player:getInstantSpells()
	local count = #spells

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		string.format("[SpellList] Vocacao %d | Level %d | ML %d | Magias canCast: %d",
			player:getVocation():getId(), player:getLevel(), player:getMagicLevel(), count))

	local samples = { "Energy Strike", "Animate Dead", "Ultimate Healing", "Haste" }
	for _, key in ipairs(samples) do
		local found = findSpellByName(spells, key)
		if found then
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				string.format("  OK: %s (%s) lvl %d", found.name, found.words, found.level))
		else
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "  --: " .. key)
		end
	end

	if player:getLevel() >= 27 and not findSpellByName(spells, "Animate Dead") then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE,
			"Animate Dead (lvl 27) nao esta em canCast — verifique needlearn / vocacao.")
	end

	local payload = Otcv8SpellList.buildPlayerSpellList(player)
	local byCategory = { attack = 0, support = 0, healing = 0, runes = 0 }
	for _, spell in ipairs(payload.spells) do
		local cat = spell.category or "support"
		if byCategory[cat] then
			byCategory[cat] = byCategory[cat] + 1
		end
	end
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		string.format("[SpellList] Categorias: attack=%d support=%d healing=%d runes=%d",
			byCategory.attack, byCategory.support, byCategory.healing, byCategory.runes))

	Otcv8SpellList.send(player)
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		"[SpellList] Opcode 202 enviado (" .. count .. " magias).")

	return false
end
