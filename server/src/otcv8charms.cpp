#include "otcv8charms.h"

namespace {
constexpr uint32_t STORAGE_MELEE = 151001;
constexpr uint32_t STORAGE_DISTANCE = 151002;
constexpr uint32_t STORAGE_MAGIC_PHYSICAL = 151010;
constexpr uint32_t STORAGE_MAGIC_EARTH = 151011;
constexpr uint32_t STORAGE_MAGIC_FIRE = 151012;
constexpr uint32_t STORAGE_MAGIC_ICE = 151013;
constexpr uint32_t STORAGE_MAGIC_ENERGY = 151014;
constexpr uint32_t STORAGE_MAGIC_HOLY = 151015;
constexpr uint32_t STORAGE_MAGIC_DEATH = 151016;
constexpr int32_t MAX_CHARM_LEVEL = 20;
constexpr int32_t BONUS_PER_LEVEL = 1;

int32_t readLevel(const Player* player, uint32_t storageKey)
{
	if (!player) {
		return 0;
	}
	int32_t value = 0;
	if (!player->getStorageValue(storageKey, value) || value <= 0) {
		return 0;
	}
	return std::min(value, MAX_CHARM_LEVEL);
}

uint32_t storageForCombatType(CombatType_t combatType)
{
	switch (combatType) {
		case COMBAT_PHYSICALDAMAGE:
			return STORAGE_MAGIC_PHYSICAL;
		case COMBAT_EARTHDAMAGE:
			return STORAGE_MAGIC_EARTH;
		case COMBAT_FIREDAMAGE:
			return STORAGE_MAGIC_FIRE;
		case COMBAT_ICEDAMAGE:
			return STORAGE_MAGIC_ICE;
		case COMBAT_ENERGYDAMAGE:
			return STORAGE_MAGIC_ENERGY;
		case COMBAT_HOLYDAMAGE:
			return STORAGE_MAGIC_HOLY;
		case COMBAT_DEATHDAMAGE:
			return STORAGE_MAGIC_DEATH;
		default:
			return 0;
	}
}
} // namespace

int32_t Otcv8Charms::getTrackLevel(const Player* player, uint32_t storageKey)
{
	return readLevel(player, storageKey);
}

int32_t Otcv8Charms::getMeleeBonusPercent(const Player* player)
{
	return readLevel(player, STORAGE_MELEE) * BONUS_PER_LEVEL;
}

int32_t Otcv8Charms::getDistanceBonusPercent(const Player* player)
{
	return readLevel(player, STORAGE_DISTANCE) * BONUS_PER_LEVEL;
}

int32_t Otcv8Charms::getMagicBonusPercent(const Player* player, CombatType_t combatType)
{
	const uint32_t storageKey = storageForCombatType(combatType);
	if (storageKey == 0) {
		return 0;
	}
	return readLevel(player, storageKey) * BONUS_PER_LEVEL;
}

int32_t Otcv8Charms::applyOutgoingDamage(Player* player, int32_t damage, CombatType_t combatType, bool isDistanceWeapon)
{
	if (!player || damage >= 0) {
		return damage;
	}

	int32_t bonus = 0;
	if (isDistanceWeapon) {
		bonus = getDistanceBonusPercent(player);
	} else if (combatType != COMBAT_NONE && combatType != COMBAT_PHYSICALDAMAGE) {
		bonus = getMagicBonusPercent(player, combatType);
	} else {
		bonus = getMeleeBonusPercent(player);
	}

	if (bonus <= 0) {
		return damage;
	}

	return static_cast<int32_t>(std::floor(static_cast<double>(damage) * (100 + bonus) / 100.0));
}
