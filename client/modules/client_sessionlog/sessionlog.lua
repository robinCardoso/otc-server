-- Grava logs da sessao (terminal) em arquivos ao logar/deslogar do personagem.
-- Pasta: <writeDir>/logs/sessions/
-- Doc: otcv8-dev/docs/SESSION-LOG.md

local LOG_DIR = "/logs/sessions"
local MAX_BUFFER_LINES = 8000

local sessionActive = false
local sessionFile = nil
local sessionLines = {}
local sessionCharName = nil
local sessionStartedAt = nil

local function ensureLogDir()
  if not g_resources.directoryExists("/logs") then
    g_resources.makeDir("/logs")
  end
  if not g_resources.directoryExists(LOG_DIR) then
    g_resources.makeDir(LOG_DIR)
  end
end

local function safeFileName(name)
  name = name or "unknown"
  name = name:gsub("[^%w%-_]", "_")
  if name == "" then
    name = "unknown"
  end
  return name
end

local function buildSessionPath(charName)
  ensureLogDir()
  local stamp = os.date("%Y-%m-%d_%H-%M-%S")
  return string.format("%s/%s_%s.log", LOG_DIR, safeFileName(charName), stamp)
end

local function flushSession(reason)
  if not sessionActive or not sessionFile then
    return
  end

  local endedAt = os.date("%Y-%m-%d %H:%M:%S")
  local footer = string.format(
    "=== FIM %s | motivo: %s | linhas: %d ===",
    endedAt, reason or "?", #sessionLines)

  local parts = {}
  for i = 1, #sessionLines do
    parts[i] = sessionLines[i]
  end
  parts[#parts + 1] = ""
  parts[#parts + 1] = footer

  local ok, err = pcall(function()
    g_resources.writeFileContents(sessionFile, table.concat(parts, "\n"))
  end)

  if ok then
    local fullPath = g_resources.getWriteDir()
    if fullPath:sub(-1) ~= "/" and fullPath:sub(-1) ~= "\\" then
      fullPath = fullPath .. "/"
    end
    g_logger.info("[SessionLog] Salvo: " .. fullPath .. sessionFile:sub(2))
  else
    g_logger.error("[SessionLog] Falha ao salvar " .. tostring(sessionFile) .. ": " .. tostring(err))
  end

  sessionActive = false
  sessionFile = nil
  sessionLines = {}
  sessionCharName = nil
  sessionStartedAt = nil
end

function flushSessionNow(reason)
  flushSession(reason)
end

function appendLine(message, level)
  if not sessionActive or not message then
    return
  end

  sessionLines[#sessionLines + 1] = message
  if #sessionLines > MAX_BUFFER_LINES then
    table.remove(sessionLines, 2) -- mantem header na linha 1
  end
end

local function startSession()
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  if sessionActive then
    flushSession("troca_personagem")
  end

  sessionCharName = player:getName()
  sessionStartedAt = os.date("%Y-%m-%d %H:%M:%S")
  sessionFile = buildSessionPath(sessionCharName)
  sessionActive = true
  sessionLines = {}

  local header = string.format(
    "=== SESSAO %s | personagem: %s | cliente: %s %s ===",
    sessionStartedAt,
    sessionCharName,
    g_app.getName(),
    g_app.getVersion())
  sessionLines[1] = header

  g_logger.info("[SessionLog] Iniciado: " .. sessionFile)
end

local function onGameStart()
  scheduleEvent(startSession, 500)
end

local function onGameEnd()
  flushSession("logout")
end

function init()
  ensureLogDir()
  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd,
  })

  if g_game.isOnline() then
    onGameStart()
  end
end

function terminate()
  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd,
  })
  flushSession("client_exit")
end
