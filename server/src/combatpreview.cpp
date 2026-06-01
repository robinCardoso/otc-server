#include "otpch.h"



#include "combatpreview.h"



#include "combat.h"

#include "configmanager.h"

#include "container.h"

#include "items.h"

#include "luascript.h"

#include "spells.h"
#include "tools.h"
#include "weapons.h"
#include "player.h"
#include "vocation.h"

#include <cmath>



#include <algorithm>

#include <chrono>

#include <fstream>

#include <iostream>

#include <unordered_map>

#include <vector>



extern ConfigManager g_config;

extern Spells* g_spells;



// #region agent log

bool CombatPreview::isValidCombatWeaponItem(const Item* item)
{
	if (!item) {
		return false;
	}

	const WeaponType_t weaponType = item->getWeaponType();
	if (weaponType == WEAPON_NONE || weaponType == WEAPON_SHIELD || weaponType == WEAPON_AMMO) {
		return false;
	}

	const ItemType& it = Item::items[item->getID()];
	if (it.id == 0) {
		return false;
	}

	if (it.slotPosition == 0 && it.weaponType == WEAPON_NONE) {
		return false;
	}

	return true;
}

bool CombatPreview::isValidEquipmentSlotItem(const Item* item, int32_t slot)
{
	if (!item) {
		return false;
	}

	const ItemType& it = Item::items[item->getID()];
	if (it.id == 0) {
		return false;
	}

	if (it.slotPosition == 0 && item->getWeaponType() == WEAPON_NONE) {
		return slot == CONST_SLOT_BACKPACK && item->getContainer() != nullptr;
	}

	switch (slot) {
		case CONST_SLOT_HEAD:
			return (it.slotPosition & SLOTP_HEAD) != 0;
		case CONST_SLOT_NECKLACE:
			return (it.slotPosition & SLOTP_NECKLACE) != 0;
		case CONST_SLOT_BACKPACK:
			return (it.slotPosition & SLOTP_BACKPACK) != 0 && item->getContainer() != nullptr;
		case CONST_SLOT_ARMOR:
			return (it.slotPosition & SLOTP_ARMOR) != 0;
		case CONST_SLOT_RIGHT:
			return (it.slotPosition & SLOTP_RIGHT) != 0 || (it.slotPosition & SLOTP_TWO_HAND) != 0;
		case CONST_SLOT_LEFT:
			return (it.slotPosition & SLOTP_LEFT) != 0 || (it.slotPosition & SLOTP_TWO_HAND) != 0;
		case CONST_SLOT_LEGS:
			return (it.slotPosition & SLOTP_LEGS) != 0;
		case CONST_SLOT_FEET:
			return (it.slotPosition & SLOTP_FEET) != 0;
		case CONST_SLOT_RING:
			return (it.slotPosition & SLOTP_RING) != 0;
		case CONST_SLOT_AMMO:
			return (it.slotPosition & SLOTP_AMMO) != 0;
		default:
			return false;
	}
}

std::string CombatPreview::resolveAttackDisplayKind(WeaponType_t weaponType, const Item* item)
{
	if (!item) {
		return "fist";
	}

	const std::string name = asLowerCaseString(item->getName());
	const ItemType& it = Item::items[item->getID()];

	switch (weaponType) {
		case WEAPON_SWORD:
		case WEAPON_AXE:
		case WEAPON_CLUB:
			return "melee";
		case WEAPON_WAND:
			if (name.find("rod") != std::string::npos) {
				return "rod";
			}
			return "wand";
		case WEAPON_DISTANCE:
			if (it.shootType == CONST_ANI_SPEAR || name.find("spear") != std::string::npos) {
				return "spear";
			}
			if (name.find("crossbow") != std::string::npos) {
				return "crossbow";
			}
			if (it.ammoType != AMMO_NONE || name.find("bow") != std::string::npos) {
				return "bow";
			}
			return "distance";
		default:
			return "other";
	}
}

bool CombatPreview::computeWeaponDamagePreview(Player* player, const Weapon* weaponTool, const Item* weaponItem,
	WeaponType_t weaponType, int32_t damageModifier, WeaponDamagePreview& out)
{
	if (!player || !weaponTool || !weaponItem) {
		return false;
	}

	out = WeaponDamagePreview();

	if (weaponType == WEAPON_WAND) {
		out.maxDamage = weaponTool->getWeaponDamage(player, player, weaponItem, true);
		out.minDamage = weaponTool->getWeaponDamage(player, player, weaponItem, false);
	} else {
		const int32_t attackSkill = player->getWeaponSkill(weaponItem);
		const int32_t attackValue = std::max<int32_t>(0, weaponItem->getAttack());
		const float attackFactor = player->getAttackFactor();
		const uint32_t level = player->getLevel();

		float damageMultiplier = 1.0f;
		switch (weaponType) {
			case WEAPON_DISTANCE:
				damageMultiplier = player->getVocation()->distDamageMultiplier;
				break;
			case WEAPON_SWORD:
			case WEAPON_AXE:
			case WEAPON_CLUB:
				damageMultiplier = player->getVocation()->meleeDamageMultiplier;
				break;
			default:
				break;
		}

		const int32_t maxValue = static_cast<int32_t>(
			Weapons::getMaxWeaponDamage(level, attackSkill, attackValue, attackFactor) * damageMultiplier);
		out.maxDamage = -maxValue;

		if (weaponType == WEAPON_DISTANCE) {
			out.minVsPlayer = static_cast<int32_t>(std::ceil(level * 1.3));
			out.minVsMonster = static_cast<int32_t>(std::ceil(level * 1.6));
			out.minDamage = -out.minVsPlayer;
		} else {
			out.minDamage = 0;
		}
	}

	if (damageModifier != 100 && damageModifier > 0) {
		out.minDamage = (out.minDamage * damageModifier) / 100;
		out.maxDamage = (out.maxDamage * damageModifier) / 100;
		out.minVsPlayer = (out.minVsPlayer * damageModifier) / 100;
		out.minVsMonster = (out.minVsMonster * damageModifier) / 100;
	}

	return true;
}

void CombatPreview::agentDebugLog1ecf01(const char* hypothesisId, const char* location, const char* message, uint32_t v1, uint32_t v2)
{
	if (!g_config.getBoolean(ConfigManager::ENABLE_TFS_DIAGNOSTIC_LOG)) {
		return;
	}

	const auto timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(

		std::chrono::system_clock::now().time_since_epoch()).count();



	const char* paths[] = {

		"debug-1ecf01.log",

		"C:/Users/Robson-PC/.cursor/projects/c-8-6-otserv-860-otserv-860/debug-1ecf01.log",

	};



	for (const char* path : paths) {

		std::ofstream out(path, std::ios::app);

		if (!out) {

			continue;

		}

		out << "{\"sessionId\":\"1ecf01\",\"hypothesisId\":\"" << hypothesisId

		    << "\",\"location\":\"" << location << "\",\"message\":\"" << message

		    << "\",\"data\":{\"v1\":" << v1 << ",\"v2\":" << v2 << "},\"timestamp\":" << timestamp << "}\n";

	}

}

// #endregion



namespace {



constexpr uint8_t MAX_CONTAINER_SEARCH_DEPTH = 16;



bool isDiagnosticLogEnabled()

{

	return g_config.getBoolean(ConfigManager::ENABLE_TFS_DIAGNOSTIC_LOG);

}



void logCombatPreviewPhase(const Player* player, const char* phase)

{

	if (!isDiagnosticLogEnabled()) {

		return;

	}

	if (player) {

		std::cout << "> [combatpreview] " << player->getName() << ' ' << phase << std::endl;

	} else {

		std::cout << "> [combatpreview] " << phase << std::endl;

	}

}



bool isHouseSpell(const std::string& name)

{

	return name.size() >= 6 && strncasecmp(name.c_str(), "House ", 6) == 0;

}



bool isSpellForPlayerVocation(const Spell& spell, const Player* player)

{

	if (!player) {

		return false;

	}



	if (player->hasFlag(PlayerFlag_IgnoreSpellCheck)) {

		return true;

	}



	const VocSpellMap& vocMap = spell.getVocMap();

	if (vocMap.empty()) {

		// Magias sem vocação (ex.: scripts de monstro) não entram no Combat Power.

		return false;

	}



	return vocMap.find(player->getVocationId()) != vocMap.end();

}



bool isHealingRuneForPlayer(const Spell& spell, const Player* player)

{

	if (!player) {

		return false;

	}



	if (player->hasFlag(PlayerFlag_IgnoreSpellCheck)) {

		return true;

	}



	const VocSpellMap& vocMap = spell.getVocMap();

	// Runas de cura sem <vocation> no XML são usáveis por qualquer vocação.

	if (vocMap.empty()) {

		return true;

	}



	return vocMap.find(player->getVocationId()) != vocMap.end();

}



class ItemCountCache

{

	public:

		uint32_t count(const Player* player, uint16_t itemId)

		{

			const auto it = cache.find(itemId);

			if (it != cache.end()) {

				return it->second;

			}



			const uint32_t total = countPlayerItemsUncached(player, itemId);

			cache.emplace(itemId, total);

			return total;

		}



	private:

		uint32_t countPlayerItemsUncached(const Player* player, uint16_t itemId);



		std::unordered_map<uint16_t, uint32_t> cache;

};



uint32_t countItemsInContainer(const Container* container, uint16_t itemId, uint8_t depth)

{

	if (!container || depth > MAX_CONTAINER_SEARCH_DEPTH) {

		return 0;

	}



	uint32_t count = 0;

	for (Item* item : container->getItemList()) {

		if (!item || item->isRemoved()) {

			continue;

		}



		const uint16_t currentId = item->getID();

		if (currentId == 0 || currentId >= Item::items.size()) {

			continue;

		}



		if (currentId == itemId) {

			count += item->getItemCount();

		}



		if (!Item::items[currentId].isContainer()) {

			continue;

		}



		const Container* sub = item->getContainer();

		if (sub) {

			count += countItemsInContainer(sub, itemId, depth + 1);

		}

	}

	return count;

}



uint32_t ItemCountCache::countPlayerItemsUncached(const Player* player, uint16_t itemId)

{

	if (!player) {

		return 0;

	}



	uint32_t count = 0;

	for (int32_t slot = CONST_SLOT_FIRST; slot <= CONST_SLOT_LAST; ++slot) {

		Item* item = player->getInventoryItem(static_cast<slots_t>(slot));

		if (!item || item->isRemoved()) {

			continue;

		}



		const uint16_t currentId = item->getID();

		if (currentId == 0 || currentId >= Item::items.size()) {

			continue;

		}



		if (currentId == itemId) {

			count += item->getItemCount();

		}



		if (!Item::items[currentId].isContainer()) {

			continue;

		}



		Container* container = item->getContainer();

		if (container) {

			count += countItemsInContainer(container, itemId, 1);

		}

	}

	return count;

}



bool canPlayerUseSpellGroup(const Spell& spell, const Player* player)

{

	if (!player || !spell.isEnabled()) {

		return false;

	}



	if (player->hasFlag(PlayerFlag_IgnoreSpellCheck)) {

		return true;

	}



	if (spell.isLearnable() && spell.isInstant()) {

		if (!player->hasLearnedInstantSpell(spell.getName())) {

			return false;

		}

	} else {

		const VocSpellMap& vocMap = spell.getVocMap();

		if (!vocMap.empty() && vocMap.find(player->getVocationId()) == vocMap.end()) {

			return false;

		}

	}



	return true;

}



std::string getSpellPreviewStatus(const Spell& spell, const Player* player, int32_t& levelDeficit, std::string& reason)

{

	levelDeficit = 0;

	reason.clear();



	if (!canPlayerUseSpellGroup(spell, player)) {

		return "locked";

	}



	if (spell.isPremium() && !player->isPremium()) {

		return "locked";

	}



	if (player->getLevel() < spell.getLevel()) {

		levelDeficit = static_cast<int32_t>(spell.getLevel() - player->getLevel());

		return "soon";

	}



	if (player->getMagicLevel() < spell.getMagicLevel()) {

		reason = "maglevel";

		return "locked";

	}



	if (player->getMana() < spell.getManaCost(player) && !player->hasFlag(PlayerFlag_HasInfiniteMana)) {

		return "mana";

	}



	if (spell.getNeedWeapon()) {

		switch (player->getWeaponType()) {

			case WEAPON_SWORD:

			case WEAPON_CLUB:

			case WEAPON_AXE:

				break;

			default:

				return "weapon";

		}

	}



	return "ok";

}



bool safeApplyPreviewValues(lua_State* L, Player* player, Combat* combat)

{

	if (!L || !player || !combat) {

		return false;

	}



	int32_t rawMin = 0;

	int32_t rawMax = 0;

	if (!combat->getPreviewValues(player, rawMin, rawMax)) {

		LuaScriptInterface::setField(L, "damageMin", 0);

		LuaScriptInterface::setField(L, "damageMax", 0);

		LuaScriptInterface::setField(L, "healMin", 0);

		LuaScriptInterface::setField(L, "healMax", 0);

		return false;

	}



	const bool healing = combat->getCombatType() == COMBAT_HEALING;

	if (healing) {

		const int32_t healMin = std::min(rawMin, rawMax);

		const int32_t healMax = std::max(rawMin, rawMax);

		LuaScriptInterface::setField(L, "damageMin", 0);

		LuaScriptInterface::setField(L, "damageMax", 0);

		LuaScriptInterface::setField(L, "healMin", healMin);

		LuaScriptInterface::setField(L, "healMax", healMax);

	} else {

		const int32_t damageMin = std::min(std::abs(rawMin), std::abs(rawMax));

		const int32_t damageMax = std::max(std::abs(rawMin), std::abs(rawMax));

		LuaScriptInterface::setField(L, "damageMin", damageMin);

		LuaScriptInterface::setField(L, "damageMax", damageMax);

		LuaScriptInterface::setField(L, "healMin", 0);

		LuaScriptInterface::setField(L, "healMax", 0);

	}

	return true;

}



struct InstantPreviewEntry {

	InstantSpell* spell;

	uint32_t sortLevel;

};



} // namespace



void CombatPreview::pushSpellPreviews(lua_State* L, Player* player)

{

	lua_createtable(L, 0, 0);



	if (!player || !g_spells) {

		return;

	}



	logCombatPreviewPhase(player, "spells: begin");



	std::vector<InstantPreviewEntry> entries;

	entries.reserve(64);



	for (const auto& it : g_spells->getInstantSpells()) {

		InstantSpell* instant = it.second;

		if (!instant) {

			continue;

		}



		const Spell::SpellGroup group = instant->getGroup();

		if (group != Spell::SpellGroup::Attack && group != Spell::SpellGroup::Healing) {

			continue;

		}



		if (isHouseSpell(instant->getName())) {

			continue;

		}



		if (!isSpellForPlayerVocation(*instant, player)) {

			continue;

		}



		entries.push_back({ instant, instant->getLevel() });

	}



	std::sort(entries.begin(), entries.end(), [](const InstantPreviewEntry& a, const InstantPreviewEntry& b) {

		if (a.sortLevel != b.sortLevel) {

			return a.sortLevel < b.sortLevel;

		}

		return a.spell->getName() < b.spell->getName();

	});



	int index = 0;

	for (const InstantPreviewEntry& entry : entries) {

		InstantSpell* instant = entry.spell;



		lua_createtable(L, 0, 16);

		LuaScriptInterface::setField(L, "name", instant->getName());

		LuaScriptInterface::setField(L, "words", instant->getWords());

		LuaScriptInterface::setField(L, "group", instant->getGroupName());

		LuaScriptInterface::setField(L, "level", instant->getLevel());

		LuaScriptInterface::setField(L, "mlevel", instant->getMagicLevel());

		LuaScriptInterface::setField(L, "mana", instant->getMana());



		int32_t levelDeficit = 0;

		std::string reason;

		const std::string status = getSpellPreviewStatus(*instant, player, levelDeficit, reason);

		LuaScriptInterface::setField(L, "status", status);

		LuaScriptInterface::setField(L, "levelDeficit", levelDeficit);

		LuaScriptInterface::setField(L, "reason", reason);



		safeApplyPreviewValues(L, player, instant->getLinkedCombat());



		lua_rawseti(L, -2, ++index);

	}



	if (isDiagnosticLogEnabled()) {

		std::cout << "> [combatpreview] " << player->getName() << " spells: done count=" << index << std::endl;

	}

}



void CombatPreview::pushHealingRunePreviews(lua_State* L, Player* player)

{

	lua_createtable(L, 0, 0);



	if (!player || !g_spells) {

		return;

	}



	logCombatPreviewPhase(player, "healingRunes: begin");



	ItemCountCache itemCache;



	int index = 0;

	for (const auto& it : g_spells->getRunes()) {

		RuneSpell* rune = it.second;

		if (!rune || rune->getGroup() != Spell::SpellGroup::Healing) {

			continue;

		}



		if (!isHealingRuneForPlayer(*rune, player)) {

			continue;

		}



		const uint16_t runeItemId = rune->getRuneItemId();

		if (runeItemId == 0 || runeItemId >= Item::items.size()) {

			continue;

		}



		const ItemType& runeType = Item::items[runeItemId];

		if (runeType.id == 0) {

			continue;

		}



		const uint32_t count = itemCache.count(player, runeItemId);

		if (count == 0) {

			continue;

		}



		lua_createtable(L, 0, 14);

		LuaScriptInterface::setField(L, "name", rune->getName());

		LuaScriptInterface::setField(L, "serverItemId", runeItemId);

		LuaScriptInterface::setField(L, "itemId", runeItemId);

		LuaScriptInterface::setField(L, "clientId", runeType.clientId);

		LuaScriptInterface::setField(L, "count", count);

		LuaScriptInterface::setField(L, "level", rune->getLevel());

		LuaScriptInterface::setField(L, "maglevel", rune->getMagicLevel());



		int32_t levelDeficit = 0;

		std::string reason;

		std::string status = getSpellPreviewStatus(*rune, player, levelDeficit, reason);

		if (status != "ok" && status != "soon") {

			// keep locked/mana/weapon

		} else if (player->getMagicLevel() < rune->getMagicLevel()) {

			status = "locked";

			reason = "maglevel";

		} else if (player->getLevel() < rune->getLevel()) {

			status = "locked";

			reason = "level";

		} else {

			status = "ok";

		}



		LuaScriptInterface::setField(L, "status", status);

		LuaScriptInterface::setField(L, "reason", reason);



		safeApplyPreviewValues(L, player, rune->getLinkedCombat());



		lua_rawseti(L, -2, ++index);

	}



	if (isDiagnosticLogEnabled()) {

		std::cout << "> [combatpreview] " << player->getName() << " healingRunes: done count=" << index << std::endl;

	}

}


