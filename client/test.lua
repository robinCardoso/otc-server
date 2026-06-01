-- Smoke test via things.lua (same path as login)
g_game.setClientVersion(860)
g_game.setProtocolVersion(g_game.getClientProtocolVersion(860))

g_settings.setNode('things', {})
local ok = modules.game_things.load()
local datOk = g_things.isDatLoaded()
local sprOk = g_sprites.isLoaded()
local u32 = g_game.getFeature(GameSpritesU32)
local aware = g_map.getAwareRange()

g_logger.info(string.format(
  '[test] things.load=%s dat=%s spr=%s U32=%s aware=%dx%d',
  tostring(ok), tostring(datOk), tostring(sprOk), tostring(u32),
  aware.width, aware.height))

if not ok or not datOk or not sprOk then
  g_logger.fatal('[test] FAILED assets load')
end

if aware.width ~= 18 or aware.height ~= 14 then
  g_logger.fatal(string.format('[test] FAILED aware %dx%d', aware.width, aware.height))
end

g_logger.info('[test] PASSED')
scheduleEvent(function() g_app.exit() end, 100)
