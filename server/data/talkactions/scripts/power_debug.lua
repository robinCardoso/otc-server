-- Fase 0: !power — diagnostico de combate (opcode 203)
-- Doc: docs/COMBAT-POWER.md

local function fmtRange(minVal, maxVal)
	return string.format("%d - %d", minVal or 0, maxVal or 0)
end

local function fmtSpellStatus(spell)
	if spell.status == "soon" and (spell.levelDeficit or 0) > 0 then
		return string.format("falta level (%d)", spell.levelDeficit)
	end
	return spell.status or "?"
end

function onSay(player, words, param)
	local p = player:getCombatPreview()
	if not p then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "[Power] getCombatPreview falhou.")
		return false
	end

	local a = p.attack or {}
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		string.format("[Power] Voc %d | Lv %d | %s | factor %.2f | wield %d%%",
			p.vocation, p.level, p.fightMode or "?", p.attackFactor or 1, p.damageModifier or 0))

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		string.format("  Ataque (%s): %s | skill %d | atk %d | %s",
			a.kind or "?", a.weaponName or "?", a.skill or 0, a.attackValue or 0,
			fmtRange(a.min, a.max)))

	if a.kind == "distance" and (a.minVsPlayer or 0) > 0 then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			string.format("  Distancia: vs player %s | vs monstro %s",
				fmtRange(a.minVsPlayer, a.max), fmtRange(a.minVsMonster, a.max)))
	end

	if (a.elementMax or 0) > 0 then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
			string.format("  Elemento (%s): %s", a.elementType or "?", fmtRange(a.elementMin, a.elementMax)))
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		string.format("  Defesa: %d | Armadura: %d | Escudo: %s (+%d)",
			p.defense or 0, p.armor or 0, a.shieldName or "-", a.shieldDefense or 0))

	if p.equipment then
		for _, item in ipairs(p.equipment) do
			if item.armor and item.armor > 0 then
				player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
					string.format("  [%s] %s (arm %d)", item.slot or "?", item.name or "?", item.armor))
			end
		end
	end

	local payload = Otcv8CombatPower.buildPlayerCombatPower(player)
	if payload.spells then
		local shown = 0
		for _, spell in ipairs(payload.spells) do
			if spell.group == "attack" and shown < 4 then
				shown = shown + 1
				local dmg = "-"
				if (spell.damageMax or 0) > 0 then
					dmg = fmtRange(spell.damageMin, spell.damageMax)
				end
				player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
					string.format("  Magia: %s | %s | %s | dano %s",
						spell.words, spell.status, fmtSpellStatus(spell), dmg))
			end
		end
	end
	if payload.healingRunes and #payload.healingRunes > 0 then
		for _, rune in ipairs(payload.healingRunes) do
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
				string.format("  Runa: %s x%d | cura %s", rune.name, rune.count, fmtRange(rune.healMin, rune.healMax)))
		end
	end

	Otcv8CombatPower.send(player)
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Power] Opcode 203 enviado.")
	return false
end
