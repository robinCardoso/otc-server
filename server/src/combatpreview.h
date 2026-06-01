#ifndef FS_COMBATPREVIEW_H
#define FS_COMBATPREVIEW_H

#include "const.h"

struct lua_State;
class Player;

class Item;
class Weapon;

struct WeaponDamagePreview {
	int32_t minDamage = 0;
	int32_t maxDamage = 0;
	int32_t minVsPlayer = 0;
	int32_t minVsMonster = 0;
};

namespace CombatPreview {
	void pushSpellPreviews(lua_State* L, Player* player);
	void pushHealingRunePreviews(lua_State* L, Player* player);
	std::string resolveAttackDisplayKind(WeaponType_t weaponType, const Item* item);
	bool computeWeaponDamagePreview(Player* player, const Weapon* weaponTool, const Item* weaponItem,
		WeaponType_t weaponType, int32_t damageModifier, WeaponDamagePreview& out);
	bool isValidCombatWeaponItem(const Item* item);
	bool isValidEquipmentSlotItem(const Item* item, int32_t slot);
	// #region agent log
	void agentDebugLog1ecf01(const char* hypothesisId, const char* location, const char* message, uint32_t v1 = 0, uint32_t v2 = 0);
	// #endregion
}

#endif
