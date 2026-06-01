-- Must match TFS 8.60 GetMapDescription (18x14 tiles): left=8 top=6 right=9 bottom=7
-- Doc: otserv_860/docs/LOGIN-ASSETS-860.md

local PROTOCOL_RANGE = { left = 8, top = 6, right = 9, bottom = 7 }

local function applyProtocolRange()
  g_map.setAwareRange(PROTOCOL_RANGE.left, PROTOCOL_RANGE.top, PROTOCOL_RANGE.right, PROTOCOL_RANGE.bottom)
end

function sync(_mode)
  applyProtocolRange()
end

function init()
  applyProtocolRange()
  connect(g_game, { onGameEnd = onGameEnd })
end

function terminate()
  disconnect(g_game, { onGameEnd = onGameEnd })
end

function onGameEnd()
  applyProtocolRange()
end
