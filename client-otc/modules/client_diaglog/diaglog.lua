-- Diagnóstico: erros de rede, login e linhas ERROR/FATAL do logger em arquivo diário.
-- Pasta: <writeDir>/logs/client-diag/
-- Doc: otcv8-dev/docs/DIAG-LOG.md

local LOG_DIR = "/logs/client-diag"
local dailyPath = nil
local dailyDate = nil
local prevOnLog = nil

local function ensureLogDir()
  if not g_resources.directoryExists("/logs") then
    g_resources.makeDir("/logs")
  end
  if not g_resources.directoryExists(LOG_DIR) then
    g_resources.makeDir(LOG_DIR)
  end
end

local function dailyLogPath()
  local today = os.date("%Y-%m-%d")
  if dailyDate ~= today then
    dailyDate = today
    dailyPath = string.format("%s/client-diag_%s.log", LOG_DIR, today)
  end
  return dailyPath
end

local function appendDiag(tag, text)
  ensureLogDir()
  local line = string.format("[%s] [%s] %s", os.date("%Y-%m-%d %H:%M:%S"), tag, text)
  pcall(function()
    local path = dailyLogPath()
    local prev = ""
    if g_resources.fileExists(path) then
      prev = g_resources.readFileContents(path)
      if prev ~= "" and not prev:match("\n$") then
        prev = prev .. "\n"
      end
    end
    g_resources.writeFileContents(path, prev .. line .. "\n")
  end)
  g_logger.info("[DiagLog] " .. line)
  if modules.client_sessionlog and modules.client_sessionlog.appendLine then
    modules.client_sessionlog.appendLine(line, "diag")
  end
end

local function serverEndpoint()
  if G and G.host then
    local port = G.port or "?"
    return string.format("%s:%s", tostring(G.host), tostring(port))
  end
  return "?"
end

local function gameContext()
  local parts = {}
  parts[#parts + 1] = "online=" .. tostring(g_game.isOnline())
  parts[#parts + 1] = "server=" .. serverEndpoint()
  local proto = g_game.getProtocolGame()
  if proto then
    parts[#parts + 1] = "connecting=" .. tostring(proto:isConnecting())
  end
  if g_game.isOnline() then
    local player = g_game.getLocalPlayer()
    if player then
      local pos = player:getPosition()
      parts[#parts + 1] = string.format(
        "char=%s pos=%d,%d,%d",
        player:getName(), pos.x, pos.y, pos.z)
    end
  end
  return table.concat(parts, " | ")
end

local function logConnectionError(message, code)
  local hint = getNetworkErrorHint and getNetworkErrorHint(code) or ""
  local connecting = false
  local proto = g_game.getProtocolGame()
  if proto then
    connecting = proto:isConnecting()
  end
  appendDiag("CONN", string.format(
    "code=%s (%s) connecting=%s msg=%s hint=%s | %s",
    tostring(code),
    getNetworkErrorName and getNetworkErrorName(code) or "?",
    tostring(connecting),
    tostring(message or ""),
    hint,
    gameContext()))
  if modules.client_sessionlog and modules.client_sessionlog.flushSessionNow then
    modules.client_sessionlog.flushSessionNow("connection_error_" .. tostring(code))
  end
end

local function onLoginError(message)
  appendDiag("LOGIN_ERR", tostring(message) .. " | " .. gameContext())
end

local function onGameEnd()
  appendDiag("GAME_END", gameContext())
end

local function onLogger(level, message, time)
  if prevOnLog then
    prevOnLog(level, message, time)
  end
  local lvl = type(level) == "string" and level:lower() or tostring(level)
  if lvl == "error" or lvl == "fatal" then
    appendDiag(string.upper(lvl), tostring(message))
  end
end

function init()
  ensureLogDir()
  appendDiag("INIT", string.format(
    "cliente %s %s | writeDir=%s",
    g_app.getName(),
    g_app.getVersion(),
    g_resources.getWriteDir()))

  connect(g_game, {
    onConnectionError = logConnectionError,
    onLoginError = onLoginError,
    onGameEnd = onGameEnd,
  })

  prevOnLog = g_logger.setOnLog(onLogger)
end

function terminate()
  disconnect(g_game, {
    onConnectionError = logConnectionError,
    onLoginError = onLoginError,
    onGameEnd = onGameEnd,
  })
  appendDiag("TERMINATE", gameContext())
  g_logger.setOnLog(prevOnLog)
  prevOnLog = nil
end
