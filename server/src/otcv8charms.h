#ifndef FS_OTCV8CHARMS_H
#define FS_OTCV8CHARMS_H

#include "player.h"

class Otcv8Charms
{
	public:
		static int32_t getTrackLevel(const Player* player, uint32_t storageKey);
		static int32_t getMeleeBonusPercent(const Player* player);
		static int32_t getDistanceBonusPercent(const Player* player);
		static int32_t getMagicBonusPercent(const Player* player, CombatType_t combatType);
		static int32_t getBonusPercent(const Player* player, CombatType_t combatType, bool isDistanceWeapon);
		static const char* getCharmLabel(CombatType_t combatType, bool isDistanceWeapon);
		static int32_t applyOutgoingDamage(Player* player, int32_t damage, CombatType_t combatType, bool isDistanceWeapon);
};

#endif
