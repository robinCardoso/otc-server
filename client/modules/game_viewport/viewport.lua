-- Must match TFS GetMapDescription (25x20 tiles): left=12 top=9 right=12 bottom=10
-- Doc: server/docs/VIEWPORT-MODULE.md

local PROTOCOL_RANGE = { left = 12, top = 9, right = 12, bottom = 10 }

local function applyProtocolRange()
  g_map.setAwareRange(PROTOCOL_RANGE.left, PROTOCOL_RANGE.top, PROTOCOL_RANGE.right, PROTOCOL_RANGE.bottom)
end

function sync(_mode)
  -- No network sync: server always sends wide map on login.
  applyProtocolRange()
end

function init()
  applyProtocolRange()
  connect(g_game, {
    onLogin = applyProtocolRange,
    onGameStart = applyProtocolRange,
    onGameEnd = onGameEnd,
  })
end

function terminate()
  disconnect(g_game, {
    onLogin = applyProtocolRange,
    onGameStart = applyProtocolRange,
    onGameEnd = onGameEnd,
  })
end

function onGameEnd()
  -- resetGameStates() runs after onGameEnd and may reset C++ aware range (18x14 on old binaries).
  addEvent(applyProtocolRange)
end

function getMode()
  if HUD_OVERLAY_MODE then
    return "wide"
  end
  if g_settings.getBoolean("classicView") and not g_app.isMobile() then
    return "classic"
  end
  return "wide"
end

-- Kept for C++ hook compatibility (no-op)
function onViewportBeforeMapRefresh()
end
