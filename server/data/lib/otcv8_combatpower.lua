-- OTCv8 combat power preview (opcode 203)
-- Doc: docs/COMBAT-POWER.md
-- Preview de magias/runas: C++ em src/combatpreview.cpp (filtro vocação + group attack/healing).
-- Crash 0xC0000005 corrigido: ValueCallback::getPreviewValues valida scriptId/pushFunction.

Otcv8CombatPower = {
	OPCODE = 203,
	MAX_PACKET_SIZE = 60000,
	_lastCombatPowerRequest = {},
	DEBOUNCE_SEC = 1.0,
}

function Otcv8CombatPower.sendJSON(player, action, data)
	local buffer = json.encode({ action = action, data = data })
	local opcode = Otcv8CombatPower.OPCODE
	local chunks = {}
	for i = 1, #buffer, Otcv8CombatPower.MAX_PACKET_SIZE do
		chunks[#chunks + 1] = buffer:sub(i, i + Otcv8CombatPower.MAX_PACKET_SIZE - 1)
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

function Otcv8CombatPower.buildPlayerCombatPower(player)
	local preview = player:getCombatPreview()
	if not preview then
		return { error = "no_preview" }
	end

	local attack = preview.attack or {}
	local equipment = {}
	if preview.equipment then
		for i = 1, #preview.equipment do
			equipment[i] = preview.equipment[i]
		end
	end

	local spellData = Otcv8CombatPowerSpells.buildSpellPreviews(player, preview)

	return {
		vocation = preview.vocation,
		level = preview.level,
		maglevel = preview.maglevel or spellData.maglevel,
		mana = preview.mana or spellData.mana,
		maxMana = preview.maxMana or spellData.maxMana,
		fightMode = preview.fightMode,
		attackFactor = preview.attackFactor,
		damageModifier = preview.damageModifier,
		defense = preview.defense,
		armor = preview.armor,
		spells = preview.spells or spellData.spells,
		healingRunes = preview.healingRunes or spellData.healingRunes,
		attackRunes = preview.attackRunes or {},
		attack = {
			kind = attack.kind,
			weaponName = attack.weaponName,
			weaponType = attack.weaponType,
			skill = attack.skill,
			attackValue = attack.attackValue,
			min = attack.min,
			max = attack.max,
			minVsPlayer = attack.minVsPlayer,
			minVsMonster = attack.minVsMonster,
			elementMin = attack.elementMin,
			elementMax = attack.elementMax,
			elementType = attack.elementType,
			charmBonusPercent = attack.charmBonusPercent or 0,
			charmLabel = attack.charmLabel or "",
			shieldName = attack.shieldName,
			shieldDefense = attack.shieldDefense,
		},
		equipment = equipment,
	}
end

function Otcv8CombatPower.canRequest(player)
	if not player then
		return false
	end
	local pid = player:getId()
	local now = os.clock()
	local last = Otcv8CombatPower._lastCombatPowerRequest[pid] or 0
	if now - last < Otcv8CombatPower.DEBOUNCE_SEC then
		return false
	end
	Otcv8CombatPower._lastCombatPowerRequest[pid] = now
	return true
end

function Otcv8CombatPower.send(player)
	return Otcv8CombatPower.sendJSON(player, "combatPower", Otcv8CombatPower.buildPlayerCombatPower(player))
end
