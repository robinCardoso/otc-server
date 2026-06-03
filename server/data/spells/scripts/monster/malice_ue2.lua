-- Goshnar's Malice: UE media
local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_FIREAREA)
combat:setArea(createCombatArea(AREA_CIRCLE3X3))

function onGetFormulaValues(creature, level, maglevel)
	return -2400, -3200
end

combat:setCallback(COMBAT_PARAM_LEVELMAGICVALUE, "onGetFormulaValues")

function onCastSpell(creature, var)
	return combat:execute(creature, var)
end
