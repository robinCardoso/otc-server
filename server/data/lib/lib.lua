-- Tables library
dofile('data/lib/tables/table.lua')

-- Core API functions implemented in Lua
dofile('data/lib/core/core.lua')

-- Compatibility library for our old Lua API
dofile('data/lib/compat/compat.lua')

-- Miscellaneous library
dofile('data/lib/miscellaneous/miscellaneous.lua')

-- Quests library
dofile('data/lib/quests/quest.lua')

dofile('data/lib/custom/custom.lua')
dofile('data/lib/coin.lua')
dofile('data/lib/castxp.lua')

-- OTCv8 extended opcodes (201-207) — json global antes das libs otcv8_*
json = dofile('data/lib/core/json.lua')
dofile('data/lib/bestiary_monsters.lua')
dofile('data/lib/otcv8_spelllist.lua')
dofile('data/lib/otcv8_combatpower.lua')
dofile('data/lib/otcv8_combatpower_spells.lua')
dofile('data/lib/otcv8_party.lua')
dofile('data/lib/otcv8_stock.lua')
dofile('data/lib/otcv8_bestiary.lua')
dofile('data/lib/otcv8_bestiary_charms.lua')
dofile('data/lib/otcv8_viewport.lua')
