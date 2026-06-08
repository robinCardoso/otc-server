-- CONFIG
APP_NAME = "otclientv8"  -- important, change it, it's name for config dir and files in appdata
APP_VERSION = 860       -- protocolo 8.60 (TFS); nao usar 1341 com things/860
DEFAULT_LAYOUT = "modern" -- chrome OTUI base; tom in-game via uiTheme (sem reiniciar)

-- If you don't use updater or other service, set it to updater = ""
Services = {
  website = "",
  updater = "",
  stats = "",
  crash = "",
  feedback = "",
  status = ""
}

-- API JSON MyAAC: criar conta/personagem pelo cliente (XAMPP)
RegisterApi = "http://localhost/login.php"

-- Servers accept http login url, websocket login url or ip:port:version
Servers = {
  FazendoTibia = "127.0.0.1:7171:860",
}

--Server = "ws://otclient.ovh:3000/"
--Server = "ws://127.0.0.1:88/"
--USE_NEW_ENERGAME = true -- uses entergamev2 based on websockets instead of entergame
ALLOW_CUSTOM_SERVERS = true -- if true it shows option ANOTHER on server list

g_app.setName("OTCv8")

-- Estoque (depot) — modulo game_stock, opcode 205, Ctrl+Shift+E
STOCK_ENABLED = true
STOCK_WINDOW_WIDTH = 720
STOCK_WINDOW_HEIGHT = 520

-- Classic view: zoom do mapa (nao altera layout da tela)
-- Classic ON  = barras laterais cinza (proporcao 15x11)
-- Classic OFF = mapa preenche largura (viewport 25x20 do servidor)
CLASSIC_MAP_TARGET_TILE_PX = 40
CLASSIC_MAP_ZOOM_FALLBACK = 11
CLASSIC_MAP_ZOOM_MAX = 21

-- CONFIG END

-- print first terminal message
g_logger.info(os.date("== application started at %b %d %Y %X"))
g_logger.info(g_app.getName() .. ' ' .. g_app.getVersion() .. ' rev ' .. g_app.getBuildRevision() .. ' (' .. g_app.getBuildCommit() .. ') made by ' .. g_app.getAuthor() .. ' built on ' .. g_app.getBuildDate() .. ' for arch ' .. g_app.getBuildArch())

if not g_resources.directoryExists("/data") then
  g_logger.fatal("Data dir doesn't exist.")
end

if not g_resources.directoryExists("/modules") then
  g_logger.fatal("Modules dir doesn't exist.")
end

-- settings
g_configs.loadSettings("/config.otml")

-- layout fixo (estrutura OTUI + login); tom escuro/cinza/claro = uiTheme em runtime
local settings = g_configs.getSettings()
local layout = DEFAULT_LAYOUT
if g_app.isMobile() then
  layout = "mobile"
end
settings:setValue('layout', layout)
g_resources.setLayout(layout)
g_logger.info("UI layout ativo: " .. (layout:len() > 0 and layout or "default"))

-- load mods
g_modules.discoverModules()
g_modules.ensureModuleLoaded("corelib")
  
local function loadModules()
  -- libraries modules 0-99
  g_modules.autoLoadModules(99)
  g_modules.ensureModuleLoaded("gamelib")

  -- client modules 100-499
  g_modules.autoLoadModules(499)
  g_modules.ensureModuleLoaded("client")

  -- game modules 500-999
  g_modules.autoLoadModules(999)
  g_modules.ensureModuleLoaded("game_interface")

  -- mods 1000-9999
  g_modules.autoLoadModules(9999)
end

-- report crash
if type(Services.crash) == 'string' and Services.crash:len() > 4 and g_modules.getModule("crash_reporter") then
  g_modules.ensureModuleLoaded("crash_reporter")
end

-- run updater, must use data.zip
if type(Services.updater) == 'string' and Services.updater:len() > 4 
  and g_resources.isLoadedFromArchive() and g_modules.getModule("updater") then
  g_modules.ensureModuleLoaded("updater")
  return Updater.init(loadModules)
end
loadModules()
