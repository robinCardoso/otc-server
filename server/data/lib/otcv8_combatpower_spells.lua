-- Magias e runas: preview automatico em C++ (player:getCombatPreview).
-- Ver ValueCallback::getPreviewValues, Spell::linkedCombatId em src/combat.cpp, src/spells.cpp.
-- Nao e necessario configurar formulas aqui.

Otcv8CombatPowerSpells = {}

function Otcv8CombatPowerSpells.buildSpellPreviews(player, preview)
	if not preview then
		return { maglevel = player:getMagicLevel(), mana = player:getMana(), maxMana = player:getMaxMana(), spells = {}, healingRunes = {} }
	end

	return {
		maglevel = preview.maglevel or player:getMagicLevel(),
		mana = preview.mana or player:getMana(),
		maxMana = preview.maxMana or player:getMaxMana(),
		spells = preview.spells or {},
		healingRunes = preview.healingRunes or {},
	}
end
