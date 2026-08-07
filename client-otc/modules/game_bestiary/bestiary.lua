bestiaryWindow = nil
bestiaryButton = nil
selectedCategory = nil
selectedCreature = nil

-- Dificuldades oficiais do Tibia
BestiaryDifficulty = {
  [1] = { name = "Inofensivo", kills = 25, points = 1 },
  [2] = { name = "Facil", kills = 500, points = 15 },
  [3] = { name = "Medio", kills = 1000, points = 25 },
  [4] = { name = "Dificil", kills = 2500, points = 50 }
}

BestiaryElementOrder = {
  "physical", "earth", "fire", "ice", "energy", "holy", "death"
}

BestiaryElementLabels = {
  physical = "Fis",
  earth = "Terra",
  fire = "Fogo",
  ice = "Gelo",
  energy = "Energy",
  holy = "Sagr",
  death = "Death"
}

BestiaryElementStyle = {
  physical = { index = 0 },
  earth = { index = 1 },
  fire = { index = 2 },
  ice = { index = 3 },
  energy = { index = 4 },
  holy = { index = 5 },
  death = { index = 6 }
}

local ELEMENT_ICON_SIZE = 20

local LOOT_GRID_COLS = 3
local LOOT_GRID_CELL_H = 84
local LOOT_GRID_SPACING = 6

local DETAIL_SUBTITLE_SEP = " - "

local function normalizeDisplayText(text)
  if not text or text == "" then
    return text
  end
  return text:utf8ToLatin1()
end

local function normalizeCreatureEntry(creature)
  creature.name = normalizeDisplayText(creature.name)
  if creature.loot then
    for _, drop in ipairs(creature.loot) do
      if drop.name then
        drop.name = normalizeDisplayText(drop.name)
      end
    end
  end
end

MonsterBestiaryDatabase = {}
BestiaryItemLookup = {}
local looksSynced = false
local itemsSynced = false

-- Performance: evita criar milhares de UICreature de uma vez
local BESTIARY_GRID_LIMIT = 96
local SEARCH_DEBOUNCE_MS = 200
local gridRefreshEvent = nil
local creatureByNameLower = {}
local creaturesByGroup = {}
local databaseIndexesBuilt = false

-- Kill toasts no mapa (opcode 207 update)
local KILL_TOAST_HOLD_MS = 2800
local KILL_TOAST_FADE_MS = 500
local KILL_TOAST_MAX_LINES_DEFAULT = 5
local KILL_TOAST_MAX_LINES_LIMIT = 10

local killToastPanel = nil
local killToastList = nil
local activeProgressToasts = {}
local killToastReady = false
local killToastStylesLoaded = false
local bestiaryTotalPoints = 0
local completionFilter = "all"
local mainTab = "catalog"
local selectedCharmCategory = "attack"
local charmTrackLevels = {}

local CHARM_MAX_LEVEL = 20
local CHARM_COST_TIERS = {
  { maxLevel = 5, cost = 25 },
  { maxLevel = 10, cost = 50 },
  { maxLevel = 15, cost = 100 },
  { maxLevel = 20, cost = 200 },
}

local CHARM_ATTACK_TRACKS = {
  { id = "melee", title = "Ataque Melee", tooltip = "+1%% de dano com sword, axe e club por nivel comprado.", otuiRow = "charmRowMelee" },
  { id = "distance", title = "Ataque Distance", tooltip = "+1%% de dano com bow, crossbow e throw por nivel comprado.", otuiRow = "charmRowDistance" },
  { id = "magic_physical", title = "Magia Fisico", tooltip = "+1%% de dano magico do elemento Fisico por nivel.", element = "physical", otuiRow = "charmRowMagicPhysical" },
  { id = "magic_earth", title = "Magia Terra", tooltip = "+1%% de dano magico do elemento Terra por nivel.", element = "earth", otuiRow = "charmRowMagicEarth" },
  { id = "magic_fire", title = "Magia Fogo", tooltip = "+1%% de dano magico do elemento Fogo por nivel.", element = "fire", otuiRow = "charmRowMagicFire" },
  { id = "magic_ice", title = "Magia Gelo", tooltip = "+1%% de dano magico do elemento Gelo por nivel.", element = "ice", otuiRow = "charmRowMagicIce" },
  { id = "magic_energy", title = "Magia Energy", tooltip = "+1%% de dano magico do elemento Energy por nivel.", element = "energy", otuiRow = "charmRowMagicEnergy" },
  { id = "magic_holy", title = "Magia Sagrado", tooltip = "+1%% de dano magico do elemento Sagrado por nivel.", element = "holy", otuiRow = "charmRowMagicHoly" },
  { id = "magic_death", title = "Magia Death", tooltip = "+1%% de dano magico do elemento Death por nivel.", element = "death", otuiRow = "charmRowMagicDeath" },
}

local CHARM_SIDEBAR_CATEGORIES = {
  { id = "attack", label = "Ataque" },
  { id = "resist", label = "Resistencia (Em breve)", disabled = true, tooltip = "Upgrades de resistencia — em desenvolvimento." },
  { id = "loot", label = "Loot (Em breve)", disabled = true, tooltip = "Upgrades de chance de loot — em desenvolvimento." },
  { id = "cap", label = "Cap (Em breve)", disabled = true, tooltip = "Upgrades de capacidade — em desenvolvimento." },
}

local function getCharmRowFooter(row)
  if not row then
    return nil
  end
  return row:recursiveGetChildById('trackFooter')
end

local function getCharmBuyButton(row)
  local footer = getCharmRowFooter(row)
  if not footer then
    return nil
  end
  local btn = footer:recursiveGetChildById('trackBuy')
  if btn then
    return btn
  end
  for _, child in ipairs(footer:getChildren()) do
    if child:getClassName() == 'UIButton' then
      return child
    end
  end
  return nil
end

-- FUTURO: tela "Carregando..." no login enquanto looks + kills sincronizam (opcode 207)

function init()
  bestiaryWindow = g_ui.loadUI('bestiary', modules.game_interface.getRootPanel())
  bestiaryWindow:hide()

  bestiaryButton = modules.client_topmenu.addRightGameToggleButton('bestiaryButton', tr('Bestiary') .. ' (Ctrl+Shift+B)', '/images/topbuttons/questlog', toggle)
  bestiaryButton:setOn(false)

  g_keyboard.bindKeyDown('Ctrl+Shift+B', toggle)

  local searchEdit = bestiaryWindow:recursiveGetChildById('searchEdit')
  searchEdit.onTextChange = onSearchChange
  setupCompletionFilters()
  setupMainTabs()
  setupCharmSidebar()
  initCharmsUI()

  local closeDetailsBtn = bestiaryWindow:recursiveGetChildById('closeDetailsBtn')
  closeDetailsBtn.onClick = hideDetails

  loadDatabase()
  buildCategories()
  selectedCategory = "All"
  refreshOverview()
  setMainTab("catalog", true)

  -- Igual shop/combatpower: registrar sempre no init (GameExtendedOpcode so liga apos setClientVersion no login).
  ProtocolGame.registerExtendedJSONOpcode(207, onExtendedJSONOpcode)

  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd
  })

  if g_game.isOnline() then
    onGameStart()
  end

  initKillToasts()
  setupDetailsBackdrop()
end

function setupDetailsBackdrop()
  if not bestiaryWindow then
    return
  end

  local backdrop = bestiaryWindow:recursiveGetChildById('detailsBackdrop')
  if not backdrop then
    return
  end

  backdrop.onMousePress = function()
    return true
  end
  backdrop.onMouseRelease = function()
    return true
  end
  backdrop.onMouseWheel = function()
    return true
  end
  backdrop.onDoubleClick = function()
    return true
  end
end

function setMainBestiaryInputEnabled(enabled)
  if not bestiaryWindow then
    return
  end

  local sidebar = bestiaryWindow:recursiveGetChildById('sidebar')
  local catalogPanel = bestiaryWindow:recursiveGetChildById('catalogPanel')
  local charmsPanel = bestiaryWindow:recursiveGetChildById('charmsPanel')
  if sidebar then
    sidebar:setEnabled(enabled)
  end
  if catalogPanel then
    catalogPanel:setEnabled(enabled)
  end
  if charmsPanel then
    charmsPanel:setEnabled(enabled)
  end
end

function ensureDetailsLayerOnTop()
  if not bestiaryWindow then
    return
  end

  local backdrop = bestiaryWindow:recursiveGetChildById('detailsBackdrop')
  local panel = bestiaryWindow:recursiveGetChildById('detailsPanel')
  if backdrop and backdrop:isVisible() then
    backdrop:raise()
  end
  if panel and panel:isVisible() then
    panel:raise()
    local closeBtn = panel:recursiveGetChildById('closeDetailsBtn')
    if closeBtn then
      closeBtn:raise()
    end
  end
end

function terminate()
  cancelGridRefresh()
  terminateKillToasts()
  g_keyboard.unbindKeyDown('Ctrl+Shift+B')
  bestiaryWindow:destroy()
  bestiaryButton:destroy()

  ProtocolGame.unregisterExtendedJSONOpcode(207)

  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd
  })
end

function isBestiaryVisible()
  return bestiaryWindow and bestiaryWindow:isVisible()
end

function cancelGridRefresh()
  if gridRefreshEvent then
    removeEvent(gridRefreshEvent)
    gridRefreshEvent = nil
  end
end

function scheduleMonsterGridRefresh(filterText)
  cancelGridRefresh()
  gridRefreshEvent = scheduleEvent(function()
    gridRefreshEvent = nil
    updateMonsterGrid(filterText)
  end, SEARCH_DEBOUNCE_MS)
end

function refreshMonsterGridIfVisible(filterText)
  if isBestiaryVisible() then
    updateMonsterGrid(filterText)
    if selectedCreature then
      ensureDetailsLayerOnTop()
    end
  end
end

local fullSyncPending = false

function requestServerSync()
  if not g_game.getFeature(GameExtendedOpcode) then
    return
  end
  if fullSyncPending then
    return
  end
  fullSyncPending = true
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedJSONOpcode(207, { action = "requestSync" })
  else
    fullSyncPending = false
  end
end

function requestServerKills()
  if not g_game.getFeature(GameExtendedOpcode) then
    return
  end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedJSONOpcode(207, { action = "requestKills" })
  end
end

function scheduleServerSync(delayMs)
  scheduleEvent(function()
    if g_game.isOnline() then
      requestServerSync()
    end
  end, delayMs or 0)
end

function scheduleServerKills(delayMs)
  scheduleEvent(function()
    if g_game.isOnline() then
      requestServerKills()
    end
  end, delayMs or 0)
end

function onGameStart()
  killToastReady = false
  ensureKillToastsPanel()
  scheduleServerKills(1800)
end

function onGameEnd()
  fullSyncPending = false
  looksSynced = false
  itemsSynced = false
  BestiaryItemLookup = {}
  killToastReady = false
  bestiaryTotalPoints = 0
  charmTrackLevels = {}
  cancelGridRefresh()
  clearAllKillToasts()
  for _, creature in ipairs(MonsterBestiaryDatabase) do
    creature.kills = 0
  end
  if isBestiaryVisible() then
    refreshOverview()
    updateMonsterGrid(getCurrentSearchText())
    hideDetails()
  end
end

function getCurrentSearchText()
  if not bestiaryWindow then
    return ""
  end
  local searchEdit = bestiaryWindow:recursiveGetChildById('searchEdit')
  local text = searchEdit and searchEdit:getText() or ""
  return normalizeDisplayText(text)
end

function buildDatabaseIndexes()
  if databaseIndexesBuilt then
    return
  end

  creatureByNameLower = {}
  creaturesByGroup = {}

  for _, creature in ipairs(MonsterBestiaryDatabase) do
    local key = creature.name:lower()
    creature._nameLower = key
    creatureByNameLower[key] = creature

    local group = creature.group or "Others"
    if not creaturesByGroup[group] then
      creaturesByGroup[group] = {}
    end
    table.insert(creaturesByGroup[group], creature)
  end

  databaseIndexesBuilt = true
end

function findCreatureByName(name)
  if not name then
    return nil
  end
  buildDatabaseIndexes()
  return creatureByNameLower[normalizeDisplayText(name):lower()]
end

local function parseSyncPayload(data)
  if type(data) ~= "table" then
    return {}, nil, nil
  end
  if data.kills then
    return data.kills, tonumber(data.totalPoints), data.charms
  end
  return data, nil, nil
end

function getCharmCostForLevel(currentLevel)
  local nextLevel = currentLevel + 1
  if nextLevel > CHARM_MAX_LEVEL then
    return nil
  end
  for _, tier in ipairs(CHARM_COST_TIERS) do
    if nextLevel <= tier.maxLevel then
      return tier.cost
    end
  end
  return 200
end

function getCharmTrackLevel(trackId)
  return charmTrackLevels[trackId] or 0
end

function applyCharmsState(data)
  if type(data) ~= "table" then
    return
  end
  if data.totalPoints then
    bestiaryTotalPoints = tonumber(data.totalPoints) or bestiaryTotalPoints
  end
  if type(data.tracks) == "table" then
    charmTrackLevels = data.tracks
  end
  refreshOverview()
  refreshCharmsUI()
end

function requestCharmsSync()
  if not g_game.getFeature(GameExtendedOpcode) then
    return
  end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedJSONOpcode(207, { action = "charms_sync" })
  end
end

function buyCharmTrack(trackId)
  if not g_game.isOnline() or not trackId then
    return
  end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedJSONOpcode(207, { action = "charms_buy", track = trackId })
  end
end

function handleCharmsBuyResult(data)
  if type(data) ~= "table" then
    return
  end
  if data.totalPoints then
    bestiaryTotalPoints = tonumber(data.totalPoints) or bestiaryTotalPoints
  end
  if type(data.tracks) == "table" then
    charmTrackLevels = data.tracks
  elseif data.track and data.level then
    charmTrackLevels[data.track] = tonumber(data.level) or 0
  end
  refreshOverview()
  refreshCharmsUI()
  if modules.game_combatpower and modules.game_combatpower.scheduleRequest then
    modules.game_combatpower.scheduleRequest()
  end
  local status = bestiaryWindow:recursiveGetChildById('charmsStatus')
  if status and data.message then
    if data.ok then
      status:setColor("#00ffccff")
    else
      status:setColor("#ff9999ff")
    end
    status:setText(data.message)
  end
end

function setupMainTabs()
  local tabs = {
    { id = "tabCatalog", mode = "catalog" },
    { id = "tabCharms", mode = "charms" },
  }
  for _, entry in ipairs(tabs) do
    local btn = bestiaryWindow:recursiveGetChildById(entry.id)
    if btn then
      btn.onClick = function()
        setMainTab(entry.mode)
      end
    end
  end
end

function setMainTab(mode, skipRefresh)
  mainTab = mode or "catalog"

  local tabCatalog = bestiaryWindow:recursiveGetChildById('tabCatalog')
  local tabCharms = bestiaryWindow:recursiveGetChildById('tabCharms')
  if tabCatalog then
    tabCatalog:setOn(mainTab == "catalog")
  end
  if tabCharms then
    tabCharms:setOn(mainTab == "charms")
  end

  local catalogPanel = bestiaryWindow:recursiveGetChildById('catalogPanel')
  local charmsPanel = bestiaryWindow:recursiveGetChildById('charmsPanel')
  local achievementsPanel = bestiaryWindow:recursiveGetChildById('achievementsPanel')
  if catalogPanel then
    catalogPanel:setVisible(mainTab == "catalog")
  end
  if charmsPanel then
    charmsPanel:setVisible(mainTab == "charms")
  end
  if achievementsPanel then
    achievementsPanel:setVisible(mainTab == "achievements")
  end

  updateSidebarForMainTab()

  if mainTab == "charms" then
    requestCharmsSync()
    refreshCharmsUI()
  elseif not skipRefresh and isBestiaryVisible() then
    updateMonsterGrid(getCurrentSearchText())
  end
end

function updateSidebarForMainTab()
  local sidebarTitle = bestiaryWindow:recursiveGetChildById('sidebarTitle')
  local categoryList = bestiaryWindow:recursiveGetChildById('categoryList')
  local categoryScrollBar = bestiaryWindow:recursiveGetChildById('categoryScrollBar')
  local charmsSidebarTitle = bestiaryWindow:recursiveGetChildById('charmsSidebarTitle')
  local charmCategoryList = bestiaryWindow:recursiveGetChildById('charmCategoryList')
  local charmCategoryScrollBar = bestiaryWindow:recursiveGetChildById('charmCategoryScrollBar')

  local isCatalog = mainTab == "catalog"
  if sidebarTitle then
    sidebarTitle:setVisible(isCatalog)
  end
  if categoryList then
    categoryList:setVisible(isCatalog)
  end
  if categoryScrollBar then
    categoryScrollBar:setVisible(isCatalog)
  end

  if charmsSidebarTitle then
    charmsSidebarTitle:setVisible(not isCatalog and mainTab == "charms")
  end
  if charmCategoryList then
    charmCategoryList:setVisible(not isCatalog and mainTab == "charms")
  end
  if charmCategoryScrollBar then
    charmCategoryScrollBar:setVisible(not isCatalog and mainTab == "charms")
  end
end

function setupCharmSidebar()
  local charmCategoryList = bestiaryWindow:recursiveGetChildById('charmCategoryList')
  if not charmCategoryList then
    return
  end
  charmCategoryList:destroyChildren()

  for _, category in ipairs(CHARM_SIDEBAR_CATEGORIES) do
    local btn = g_ui.createWidget('BestiaryCategoryButton', charmCategoryList)
    btn:setId(category.id)
    btn:setText(tr(category.label))
    if category.tooltip then
      btn:setTooltip(tr(category.tooltip))
    end
    if category.disabled then
      btn:setEnabled(false)
      btn:setOpacity(0.45)
    else
      btn.onClick = function()
        setCharmCategory(category.id)
      end
    end
  end
  setCharmCategory("attack", true)
end

function setCharmCategory(categoryId, skipRefresh)
  selectedCharmCategory = categoryId or "attack"
  local charmCategoryList = bestiaryWindow:recursiveGetChildById('charmCategoryList')
  if charmCategoryList then
    for _, child in ipairs(charmCategoryList:getChildren()) do
      child:setOn(child:getId() == selectedCharmCategory)
    end
  end
  if not skipRefresh then
    refreshCharmsUI()
  end
end

local function styleCharmBuyButton(buyBtn)
  if not buyBtn then
    return
  end
  buyBtn:setSize({ width = 96, height = 24 })
  buyBtn:setText(tr('Comprar +1%%'))
  buyBtn:setVisible(true)
end

local function bindCharmRowWidget(row, trackDef)
  if not row or not trackDef then
    return
  end
  row.trackId = trackDef.id
  local buyBtn = getCharmBuyButton(row)
  row.charmBuyBtn = buyBtn
  if buyBtn and trackDef.otuiRow then
    buyBtn:setId(trackDef.otuiRow .. '_buy')
  end
  styleCharmBuyButton(buyBtn)
  if buyBtn then
    buyBtn.onClick = function()
      buyCharmTrack(trackDef.id)
    end
  end
  if trackDef.tooltip then
    row:setTooltip(trackDef.tooltip)
  end
end

function initCharmsUI()
  for _, trackDef in ipairs(CHARM_ATTACK_TRACKS) do
    if trackDef.otuiRow then
      local row = bestiaryWindow:recursiveGetChildById(trackDef.otuiRow)
      bindCharmRowWidget(row, trackDef)
    end
  end
  refreshCharmsUI()
end

local function applyCharmElementIcon(widget, elementId)
  if not widget or not elementId then
    return
  end
  applyElementIcon(widget, elementId)
  widget:setVisible(true)
end

local function updateCharmRowWidget(row, trackDef)
  if not row or not trackDef then
    return
  end
  local level = getCharmTrackLevel(trackDef.id)
  local titleLabel = row:recursiveGetChildById('trackTitle')
  local levelLabel = row:recursiveGetChildById('trackLevel')
  local progress = row:recursiveGetChildById('trackProgress')
  local costLabel = row:recursiveGetChildById('trackCost')
  local buyBtn = row.charmBuyBtn or getCharmBuyButton(row)
  local iconWidget = row:recursiveGetChildById('trackIcon')

  if iconWidget then
    if trackDef.element then
      applyCharmElementIcon(iconWidget, trackDef.element)
      if titleLabel then
        titleLabel:setMarginLeft(22)
      end
    else
      iconWidget:setVisible(false)
      if titleLabel then
        titleLabel:setMarginLeft(0)
      end
    end
  end

  if titleLabel then
    titleLabel:setText(tr(trackDef.title))
  end
  if levelLabel then
    levelLabel:setText(string.format("%d%% / %d%%", level, CHARM_MAX_LEVEL))
  end
  if progress then
    progress:setMinimum(0)
    progress:setMaximum(CHARM_MAX_LEVEL)
    progress:setValue(level)
    progress:updateBackground()
  end

  local cost = getCharmCostForLevel(level)
  local canBuy = false
  local buyTooltip = tr("Comprar +1%% nesta trilha.")
  if costLabel then
    if cost then
      costLabel:setColor("#aaaaaaff")
      costLabel:setText(tr("Proximo: +1%%  |  %d pts", cost))
      if bestiaryTotalPoints >= cost and g_game.isOnline() then
        canBuy = true
      elseif not g_game.isOnline() then
        buyTooltip = tr("Conecte-se ao jogo para comprar.")
        costLabel:setColor("#ff9999ff")
      else
        buyTooltip = tr("Charm Points insuficientes (%d / %d).", bestiaryTotalPoints, cost)
        costLabel:setColor("#ff9999ff")
      end
    else
      costLabel:setColor("#aaaaaaff")
      costLabel:setText(tr("Nivel maximo atingido (%d%%).", CHARM_MAX_LEVEL))
      buyTooltip = tr("Esta trilha ja esta no limite.")
    end
  end
  if buyBtn then
    styleCharmBuyButton(buyBtn)
    buyBtn:raise()
    buyBtn:setEnabled(canBuy)
    buyBtn:setTooltip(buyTooltip)
  end
end

function refreshCharmsUI()
  if not bestiaryWindow or mainTab ~= "charms" or selectedCharmCategory ~= "attack" then
    return
  end

  for _, trackDef in ipairs(CHARM_ATTACK_TRACKS) do
    if trackDef.otuiRow then
      updateCharmRowWidget(bestiaryWindow:recursiveGetChildById(trackDef.otuiRow), trackDef)
    end
  end

  local status = bestiaryWindow:recursiveGetChildById('charmsStatus')
  if status then
    status:setColor("#ccccccff")
    status:setText(tr("Upgrades permanentes +1%% por nivel (max %d%%). Saldo: %d Charm Points.", CHARM_MAX_LEVEL, bestiaryTotalPoints))
  end
end

function applyKillsFromServer(killsTable)
  if not killsTable then
    return 0
  end
  buildDatabaseIndexes()
  local applied = 0
  for name, kills in pairs(killsTable) do
    local creature = creatureByNameLower[name:lower()]
    if creature then
      creature.kills = tonumber(kills) or 0
      applied = applied + 1
    end
  end
  return applied
end

function onExtendedJSONOpcode(protocol, code, jsonData)
  -- protocolgame.lua ja faz o chunk assembly (S/P/E) e json.decode antes de chamar aqui.
  -- jsonData chega como table Lua pronta.
  if type(jsonData) ~= "table" then
    g_logger.error("[Bestiary] onExtendedJSONOpcode: dado invalido (type=" .. type(jsonData) .. ")")
    return
  end

  local action = jsonData.action
  local data = jsonData.data

  if action == "sync" then
    local killsTable, totalPoints, charms = parseSyncPayload(data)
    detectSyncKillDeltas(killsTable)

    for _, creature in ipairs(MonsterBestiaryDatabase) do
      creature.kills = 0
    end
    local applied = applyKillsFromServer(killsTable or {})
    if totalPoints then
      bestiaryTotalPoints = totalPoints
    end
    if type(charms) == "table" then
      charmTrackLevels = charms
    end
    killToastReady = true
    g_logger.info(string.format("[Bestiary] sync: %d especies com kills, %d charm points", applied, bestiaryTotalPoints))

    refreshOverview()
    refreshMonsterGridIfVisible(getCurrentSearchText())
    refreshCharmsUI()

    if selectedCreature and isBestiaryVisible() then
      showCreatureDetails(selectedCreature)
    end

  elseif action == "update" and data then
    local creature = findCreatureByName(data.name)
    if creature then
      local previousKills = creature.kills or 0
      local newKills = tonumber(data.kills) or 0
      creature.kills = newKills
      handleKillToast(creature, previousKills, newKills)
    end
    if data.totalPoints then
      bestiaryTotalPoints = tonumber(data.totalPoints) or bestiaryTotalPoints
    end

    refreshOverview()
    refreshMonsterGridIfVisible(getCurrentSearchText())

    if selectedCreature and selectedCreature.name:lower() == data.name:lower() and isBestiaryVisible() then
      showCreatureDetails(selectedCreature)
    end

  elseif action == "charms_state" then
    applyCharmsState(data)

  elseif action == "charms_buy_result" then
    handleCharmsBuyResult(data)

  elseif action == "looks" then
    mergeLooksFromServer(data)
  elseif action == "items" then
    mergeItemsFromServer(data)
  elseif action == "itemsDone" then
    finalizeItemsFromServer(data)
  end
end

function mergeItemsFromServer(data)
  if type(data) ~= "table" then
    g_logger.warning("[Bestiary] Pacote 'items' invalido do servidor")
    return
  end

  for serverId, entry in pairs(data) do
    BestiaryItemLookup[serverId] = entry
  end
end

function finalizeItemsFromServer(data)
  fullSyncPending = false
  itemsSynced = true
  local count = 0
  for _ in pairs(BestiaryItemLookup) do
    count = count + 1
  end
  local expected = data and tonumber(data.total) or nil
  g_logger.info(string.format(
    "[Bestiary] Mapa de itens sincronizado: %d entradas%s",
    count,
    expected and string.format(" (esperado: %d)", expected) or ""
  ))

  refreshMonsterGridIfVisible(getCurrentSearchText())
  if selectedCreature and isBestiaryVisible() then
    showCreatureDetails(selectedCreature)
  end
end

function mergeLooksFromServer(data)
  if type(data) ~= "table" or type(data.names) ~= "table" or type(data.types) ~= "table" then
    g_logger.warning("[Bestiary] Pacote 'looks' invalido do servidor")
    return
  end

  buildDatabaseIndexes()

  local auxList = data.aux or {}
  local merged = 0

  for i, name in ipairs(data.names) do
    local creature = creatureByNameLower[name:lower()]
    if creature then
      creature.lookId = tonumber(data.types[i]) or 0
      creature.lookTypeEx = tonumber(auxList[i]) or 0
      merged = merged + 1
    end
  end

  looksSynced = true
  if itemsSynced then
    fullSyncPending = false
  end
  g_logger.info(string.format("[Bestiary] Looks oficiais sincronizados: %d monstros", merged))

  refreshMonsterGridIfVisible(getCurrentSearchText())
  if selectedCreature and isBestiaryVisible() then
    showCreatureDetails(selectedCreature)
  end
end

function applyCreatureOutfit(widget, creature, options)
  if not widget or not creature then
    return
  end

  options = options or {}
  if creature.lookTypeEx and creature.lookTypeEx > 0 then
    widget:setOutfit({ auxType = creature.lookTypeEx })
  elseif creature.lookId and creature.lookId > 0 then
    widget:setOutfit({ type = creature.lookId })
  end

  if options.detail then
    widget:setScale(0.72)
    widget:setAnimate(true)
    widget:setAutoRotating(true)
  elseif options.large then
    widget:setScale(1.35)
    widget:setAnimate(true)
    widget:setAutoRotating(true)
  elseif options.card then
    widget:setScale(0.85) -- Diminui mais os monstros para caberem bem no pedestal
    widget:setAnimate(true)
    widget:setAutoRotating(false)
  elseif options.toast then
    widget:setScale(0.72)
    widget:setAnimate(false)
    widget:setAutoRotating(false)
  else
    widget:setScale(1.0)
    widget:setAnimate(false)
    widget:setAutoRotating(false)
  end
end

function buildWeaknessMap(creature)
  local map = {}
  if creature.weakness then
    for _, weak in ipairs(creature.weakness) do
      map[weak.element] = weak.val
    end
  end
  return map
end

function getDifficultyColors(difficultyId)
  local color = "#33cc33ff"
  local bgColor = "#33cc3318"
  local borderColor = "#33cc3388"
  local cardBgColor = "#33cc3322"

  if difficultyId == 2 then
    color = "#99cc33ff"
    bgColor = "#99cc3318"
    borderColor = "#99cc3388"
    cardBgColor = "#99cc3322"
  elseif difficultyId == 3 then
    color = "#ffcc33ff"
    bgColor = "#ffcc3318"
    borderColor = "#ffcc3388"
    cardBgColor = "#ffcc3322"
  elseif difficultyId == 4 then
    color = "#ff3333ff"
    bgColor = "#ff333318"
    borderColor = "#ff333388"
    cardBgColor = "#ff333322"
  end

  return color, bgColor, borderColor, cardBgColor
end

function resolveDropItem(drop, creatureName)
  if not drop then
    return nil
  end

  local label = drop.name or "?"
  local serverId = drop.id and drop.id > 0 and drop.id or nil

  if drop.clientId and drop.clientId > 0 then
    return { clientId = drop.clientId, name = drop.name or label }
  end

  if serverId then
    local entry = BestiaryItemLookup[tostring(serverId)]
    if entry and entry.c and entry.c > 0 then
      return { clientId = entry.c, name = entry.n or drop.name or label }
    end
  end

  if drop.name then
    local lowerName = drop.name:lower()
    for _, entry in pairs(BestiaryItemLookup) do
      if entry.n and entry.n:lower() == lowerName and entry.c and entry.c > 0 then
        return { clientId = entry.c, name = entry.n }
      end
    end
  end

  g_logger.warning(string.format(
    "[Bestiary] loot item nao resolvido: %s (serverId=%s, %s) - aguardando sync 'items'",
    label,
    serverId or "-",
    creatureName or "?"
  ))
  return nil
end

function resizeLootGrid(grid, itemCount)
  if not grid then
    return
  end

  local rows = math.max(1, math.ceil(itemCount / LOOT_GRID_COLS))
  grid:setHeight(rows * LOOT_GRID_CELL_H + math.max(0, rows - 1) * LOOT_GRID_SPACING)
end

function applyLootSlot(slot, drop, locked, creatureName)
  local itemWidget = slot:getChildById('lootItem')
  local lockIcon = slot:getChildById('lockIcon')
  local lockHint = slot:getChildById('lockHint')
  local lockHintBg = slot:getChildById('lockHintBg')
  local nameLabel = slot:getChildById('lootItemName')

  local function showLockedState()
    itemWidget:setVisible(false)
    itemWidget:setItem(nil)
    lockIcon:setVisible(true)
    if lockHintBg then
      lockHintBg:setVisible(true)
    end
    if lockHint then
      lockHint:setVisible(true)
      lockHint:setText(tr('Bloqueado'))
    end
    if nameLabel then
      nameLabel:setVisible(false)
    end
    slot:setTooltip(tr("Mate 1 criatura para desbloquear o saque."))
  end

  if drop then
    if locked then
      showLockedState()
      return
    end

    itemWidget:setVisible(true)
    local resolved = resolveDropItem(drop, creatureName)
    if resolved and resolved.clientId then
      if not Spells.applyItemIcon(itemWidget, resolved.clientId, 1) then
        itemWidget:setItem(nil)
      end
    else
      itemWidget:setItem(nil)
    end
    itemWidget:setOpacity(1)

    lockIcon:setVisible(false)
    if lockHintBg then
      lockHintBg:setVisible(false)
    end
    if lockHint then
      lockHint:setVisible(false)
    end

    local displayName = resolved and resolved.name or drop.name or "Item"
    if nameLabel then
      nameLabel:setVisible(true)
      nameLabel:setText(displayName)
    end
    local chancePercent = drop.chance / 1000
    slot:setTooltip(string.format("%s (Chance: %.2f%%)", displayName, chancePercent))
  else
    showLockedState()
  end
end

function applyElementIcon(widget, elementId)
  if not widget then
    return
  end

  local style = BestiaryElementStyle[elementId] or BestiaryElementStyle.physical
  local index = style.index or 0
  widget:setImageSource('/images/ui/bestiary_elements')
  widget:setImageClip(torect(string.format('%d 0 %d %d', index * ELEMENT_ICON_SIZE, ELEMENT_ICON_SIZE, ELEMENT_ICON_SIZE)))
  widget:setBackgroundColor('#00000000')
end

function renderElementGrid(panel, creature)
  local resistGrid = panel:recursiveGetChildById('resistGrid')
  resistGrid:destroyChildren()

  local weaknessMap = buildWeaknessMap(creature)

  for _, elementId in ipairs(BestiaryElementOrder) do
    local val = weaknessMap[elementId] or 100
    local chip = g_ui.createWidget('BestiaryElementChip', resistGrid)

    applyElementIcon(chip:getChildById('elementIcon'), elementId)

    local valLabel = chip:getChildById('elementVal')
    valLabel:setText(string.format("%d%%", val))

    if val == 0 then
      valLabel:setColor("#00ffccff")
      chip:setBorderColor("#00ffcc88")
    elseif val > 100 then
      valLabel:setColor("#ff6666ff")
      chip:setBorderColor("#ff666688")
    elseif val < 100 then
      valLabel:setColor("#00ffccff")
      chip:setBorderColor("#00ffcc88")
    else
      valLabel:setColor("#888888ff")
      chip:setBorderColor("#333333ff")
    end

    local label = BestiaryElementLabels[elementId] or elementId:sub(1, 3)
    chip:setTooltip(string.format("%s: %d%%", label, val))
  end
end

function updateDetailScrollHeight(panel)
  local content = panel:recursiveGetChildById('detailScrollContent')
  local lootGrid = panel:recursiveGetChildById('lootGrid')
  local dropsLabel = panel:recursiveGetChildById('dropsLabel')
  local scrollArea = panel:recursiveGetChildById('detailScrollArea')

  if not content then
    return
  end

  local bottom = 200
  if dropsLabel and dropsLabel:isVisible() then
    bottom = dropsLabel:getY() + dropsLabel:getHeight()
  elseif lootGrid and lootGrid:isVisible() then
    bottom = lootGrid:getY() + lootGrid:getHeight()
  else
    local dropsTitle = panel:recursiveGetChildById('dropsTitle')
    if dropsTitle then
      bottom = dropsTitle:getY() + dropsTitle:getHeight() + 8
    end
  end

  content:setHeight(math.max(bottom + 12, 200))

  if scrollArea and scrollArea.updateScrollBars then
    scrollArea:updateScrollBars()
  end
end

function scheduleDetailScrollRefresh(panel)
  scheduleEvent(function()
    if not panel or panel:isDestroyed() then
      return
    end
    updateDetailScrollHeight(panel)
    resetDetailScroll(panel)
  end, 50)
end

function resetDetailScroll(panel)
  local scrollArea = panel:recursiveGetChildById('detailScrollArea')
  if not scrollArea then
    return
  end

  local scrollBar = scrollArea.verticalScrollBar
  if scrollBar then
    scrollBar:setValue(0)
  end
  scrollArea:setVirtualOffset({ x = 0, y = 0 })
end

function renderLootSection(panel, creature, diff)
  local lootGrid = panel:recursiveGetChildById('lootGrid')
  local dropsLabel = panel:recursiveGetChildById('dropsLabel')
  local loot = creature.loot or {}
  local lootCount = #loot
  local branch = "empty"
  local slotCount = 0

  lootGrid:destroyChildren()
  lootGrid:setVisible(false)
  dropsLabel:setVisible(false)

  if creature.kills > 0 and lootCount > 0 then
    branch = "unlocked"
    lootGrid:setVisible(true)

    for _, drop in ipairs(loot) do
      local slot = g_ui.createWidget('BestiaryLootSlot', lootGrid)
      applyLootSlot(slot, drop, false, creature.name)
      slotCount = slotCount + 1
    end

    resizeLootGrid(lootGrid, slotCount)
  elseif creature.kills > 0 then
    branch = "no_loot"
    dropsLabel:setVisible(true)
    dropsLabel:setText(tr("Sem loot registrado para esta criatura."))
  elseif lootCount > 0 then
    branch = "locked"
    lootGrid:setVisible(true)
    slotCount = math.max(lootCount, 3)

    for i = 1, slotCount do
      local slot = g_ui.createWidget('BestiaryLootSlot', lootGrid)
      applyLootSlot(slot, loot[i], true, creature.name)
    end

    resizeLootGrid(lootGrid, slotCount)
  else
    branch = "no_loot"
    dropsLabel:setVisible(true)
    dropsLabel:setText(tr("Sem loot registrado para esta criatura."))
  end

  g_logger.info(string.format(
    "[Bestiary] loot: %s branch=%s slots=%d kills=%d lootEntries=%d",
    creature.name,
    branch,
    slotCount,
    creature.kills or 0,
    lootCount
  ))
end

function updateDetailProgress(panel, creature, diff)
  local progressCount = panel:recursiveGetChildById('detailProgressCount')
  local progressBar = panel:recursiveGetChildById('detailProgress')

  progressCount:setText(string.format("%d/%d", creature.kills, diff.kills))
  progressBar:setMinimum(0)
  progressBar:setMaximum(diff.kills)
  progressBar:setValue(creature.kills)
  progressBar:setTooltip(tr("Kills: %d / %d", creature.kills, diff.kills))
  progressBar:updateBackground()
end

function loadDatabase()
  local databasePath = "/modules/game_bestiary/bestiary_database.json"
  if g_resources.fileExists(databasePath) then
    local fileContent = g_resources.readFileContents(databasePath)
    MonsterBestiaryDatabase = json.decode(fileContent)

    for _, creature in ipairs(MonsterBestiaryDatabase) do
      normalizeCreatureEntry(creature)
      creature.kills = 0
    end

    databaseIndexesBuilt = false
    buildDatabaseIndexes()

    g_logger.info(string.format("[Bestiary] Carregados %d monstros da base de dados com sucesso!", #MonsterBestiaryDatabase))
  else
    g_logger.error("[Bestiary] Arquivo bestiary_database.json nao encontrado!")
  end

  local assetsPath = "/modules/game_bestiary/bestiary_assets.json"
  if g_resources.fileExists(assetsPath) then
    local assetsContent = g_resources.readFileContents(assetsPath)
    local assets = json.decode(assetsContent)
    if assets then
      if assets.looks then
        mergeLooksFromServer(assets.looks)
      end
      if assets.items then
        BestiaryItemLookup = assets.items
        itemsSynced = true
      end
      g_logger.info("[Bestiary] Looks e itens locais carregados com sucesso de bestiary_assets.json!")
    end
  end
end

function hide()
  if not bestiaryWindow or not bestiaryWindow:isVisible() then
    return
  end
  bestiaryWindow:hide()
  bestiaryButton:setOn(false)
  cancelGridRefresh()
  hideDetails()
end

function toggle()
  if bestiaryWindow:isVisible() then
    hide()
  else
    bestiaryWindow:show()
    bestiaryWindow:raise()
    bestiaryWindow:focus()
    bestiaryButton:setOn(true)
    if not looksSynced or not itemsSynced then
      requestServerSync()
    end
    refreshOverview()
    setMainTab(mainTab, true)
    updateMonsterGrid(getCurrentSearchText())
  end
end

function refreshOverview()
  if not bestiaryWindow then
    return
  end
  local totalKills = 0
  for _, creature in ipairs(MonsterBestiaryDatabase) do
    totalKills = totalKills + (creature.kills or 0)
  end
  local totalPointsLabel = bestiaryWindow:recursiveGetChildById('totalPoints')
  if totalPointsLabel then
    totalPointsLabel:setText(tr("Charm Points: %d", bestiaryTotalPoints))
  end
  local totalProgressLabel = bestiaryWindow:recursiveGetChildById('totalProgress')
  if totalProgressLabel then
    totalProgressLabel:setText(tr("Total Kills: %d", totalKills))
  end
end

function buildCategories()
  buildDatabaseIndexes()

  local categoryList = bestiaryWindow:recursiveGetChildById('categoryList')
  categoryList:destroyChildren()

  local allBtn = g_ui.createWidget('BestiaryCategoryButton', categoryList)
  allBtn:setId("All")
  allBtn:setText(tr("All Classes"))
  allBtn.onClick = function() selectCategory("All") end

  local categories = {}
  for group in pairs(creaturesByGroup) do
    categories[#categories + 1] = group
  end
  table.sort(categories)

  for _, group in ipairs(categories) do
    local btn = g_ui.createWidget('BestiaryCategoryButton', categoryList)
    btn:setId(group)
    btn:setText(tr(group))
    btn.onClick = function() selectCategory(group) end
  end
end

function selectCategory(categoryName)
  local categoryList = bestiaryWindow:recursiveGetChildById('categoryList')
  for _, child in ipairs(categoryList:getChildren()) do
    child:setOn(child:getId() == categoryName)
  end

  selectedCategory = categoryName
  scheduleMonsterGridRefresh(getCurrentSearchText())
end

local function nameStartsWith(nameLower, search)
  return #search > 0 and nameLower:sub(1, #search) == search
end

local function wordStartsWith(word, search)
  return #search > 0 and word:sub(1, #search) == search
end

local function creatureMatchesSearch(nameLower, search)
  if nameLower == search then
    return true
  end
  if nameStartsWith(nameLower, search) then
    return true
  end
  for word in nameLower:gmatch("%S+") do
    if word == search or wordStartsWith(word, search) then
      return true
    end
  end
  return false
end

local function getCreatureSearchRank(nameLower, search)
  if nameLower == search then
    return 1000
  end
  if nameStartsWith(nameLower, search) then
    return 900
  end

  local best = -1
  for word in nameLower:gmatch("%S+") do
    if word == search then
      best = math.max(best, 800)
    elseif wordStartsWith(word, search) then
      best = math.max(best, 700)
    end
  end
  return best
end

function isCreatureCompleted(creature)
  local diff = BestiaryDifficulty[creature.difficulty] or BestiaryDifficulty[1]
  return (creature.kills or 0) >= diff.kills
end

local function matchesCompletionFilter(creature)
  local kills = creature.kills or 0
  if completionFilter == "completed" then
    return isCreatureCompleted(creature)
  end
  if completionFilter == "progress" then
    return kills > 0 and not isCreatureCompleted(creature)
  end
  return true
end

function setupCompletionFilters()
  local filters = {
    { id = "filterAll", mode = "all" },
    { id = "filterCompleted", mode = "completed" },
    { id = "filterProgress", mode = "progress" },
  }
  for _, entry in ipairs(filters) do
    local btn = bestiaryWindow:recursiveGetChildById(entry.id)
    if btn then
      btn.onClick = function()
        setCompletionFilter(entry.mode)
      end
    end
  end
  setCompletionFilter("all", true)
end

function setCompletionFilter(mode, skipRefresh)
  completionFilter = mode
  local modes = {
    { id = "filterAll", mode = "all" },
    { id = "filterCompleted", mode = "completed" },
    { id = "filterProgress", mode = "progress" },
  }
  for _, entry in ipairs(modes) do
    local btn = bestiaryWindow:recursiveGetChildById(entry.id)
    if btn then
      btn:setOn(entry.mode == mode)
    end
  end
  if not skipRefresh then
    scheduleMonsterGridRefresh(getCurrentSearchText())
  end
end

local function sortCreaturesForSearch(creatures, search)
  table.sort(creatures, function(a, b)
    local rankA = getCreatureSearchRank(a._nameLower or a.name:lower(), search)
    local rankB = getCreatureSearchRank(b._nameLower or b.name:lower(), search)
    if rankA ~= rankB then
      return rankA > rankB
    end
    return (a._nameLower or a.name:lower()) < (b._nameLower or b.name:lower())
  end)
end

function getFilteredCreatures(filterText)
  buildDatabaseIndexes()

  local search = ""
  if filterText and filterText:len() > 0 then
    search = filterText:lower()
  end

  local source
  if selectedCategory == "All" then
    source = MonsterBestiaryDatabase
  else
    source = creaturesByGroup[selectedCategory] or {}
  end

  local result = {}
  for _, creature in ipairs(source) do
    if matchesCompletionFilter(creature) then
      local include = true
      if search ~= "" then
        local nameLower = creature._nameLower or creature.name:lower()
        include = creatureMatchesSearch(nameLower, search)
      end
      if include then
        result[#result + 1] = creature
      end
    end
  end

  if search ~= "" then
    sortCreaturesForSearch(result, search)
  elseif completionFilter == "completed" then
    table.sort(result, function(a, b)
      return (a._nameLower or a.name:lower()) < (b._nameLower or b.name:lower())
    end)
  end
  return result
end

function setGridStatus(mode, shown, total)
  local gridStatus = bestiaryWindow:recursiveGetChildById('gridStatus')
  if not gridStatus then
    return
  end

  if mode == "pick_filter" then
    gridStatus:setColor("#ccccccff")
    gridStatus:setText(tr("Escolha uma classe, use Completados/Em progresso ou digite 2+ letras na busca. (%d criaturas)", total))
  elseif mode == "empty_completed" then
    gridStatus:setColor("#ff9999ff")
    gridStatus:setText(tr("Nenhum bestiary completo neste filtro."))
  elseif mode == "empty_progress" then
    gridStatus:setColor("#ff9999ff")
    gridStatus:setText(tr("Nenhum bestiary em progresso neste filtro."))
  elseif mode == "limited" then
    gridStatus:setColor("#ccccccff")
    gridStatus:setText(tr("Mostrando %d de %d. Digite mais para filtrar.", shown, total))
  elseif mode == "empty" then
    gridStatus:setColor("#ff9999ff")
    gridStatus:setText(tr("Nenhuma criatura encontrada."))
  elseif shown > 0 and shown < total then
    gridStatus:setColor("#aaaaaaff")
    gridStatus:setText(tr("Mostrando %d de %d.", shown, total))
  else
    gridStatus:setText("")
  end
end

function updateMonsterGrid(filterText)
  local monsterGrid = bestiaryWindow:recursiveGetChildById('monsterGrid')
  monsterGrid:destroyChildren()

  local filtered = getFilteredCreatures(filterText)
  local total = #filtered

  -- "All" sem busca: lista enorme — pedir filtro em vez de montar 1300+ cards
  local searchLen = filterText and filterText:len() or 0
  local hasCompletionFilter = completionFilter ~= "all"
  if selectedCategory == "All" and searchLen < 2 and not hasCompletionFilter then
    setGridStatus("pick_filter", 0, #MonsterBestiaryDatabase)
    return
  end

  if total == 0 then
    if completionFilter == "completed" then
      setGridStatus("empty_completed", 0, 0)
    elseif completionFilter == "progress" then
      setGridStatus("empty_progress", 0, 0)
    else
      setGridStatus("empty", 0, 0)
    end
    return
  end

  local toShow = filtered
  local limited = false
  if total > BESTIARY_GRID_LIMIT then
    toShow = {}
    for i = 1, BESTIARY_GRID_LIMIT do
      toShow[i] = filtered[i]
    end
    limited = true
  end

  if limited then
    setGridStatus("limited", #toShow, total)
  else
    setGridStatus(nil, #toShow, total)
  end

  for _, creature in ipairs(toShow) do
    local card = g_ui.createWidget('BestiaryMonsterCard', monsterGrid)
    card.onClick = function() showCreatureDetails(creature) end

    local sprite = card:getChildById('sprite')
    applyCreatureOutfit(sprite, creature, { card = true })

    local nameLabel = card:getChildById('name')
    nameLabel:setText(creature.name)
    nameLabel:setTooltip(creature.name)

    local diff = BestiaryDifficulty[creature.difficulty] or BestiaryDifficulty[1]
    
    local diffLabel = card:getChildById('difficulty')
    diffLabel:setText(diff.name)
    
    local diffColor, _, diffBorderColor, diffBgColor = getDifficultyColors(creature.difficulty)
    diffLabel:setColor(diffColor)
    diffLabel:setBorderColor(diffBorderColor)
    diffLabel:setBackgroundColor(diffBgColor)

    local progress = card:getChildById('progress')
    progress:setMinimum(0)
    progress:setMaximum(diff.kills)
    progress:setValue(creature.kills)
    progress:setTooltip(tr("Kills: %d / %d", creature.kills, diff.kills))

    local killsLabel = card:getChildById('kills')
    killsLabel:setText(string.format("%d/%d kills", creature.kills, diff.kills))
  end
end

function onSearchChange(searchEdit, text)
  scheduleMonsterGridRefresh(text)
end

function showCreatureDetails(creature)
  selectedCreature = creature
  local backdrop = bestiaryWindow:recursiveGetChildById('detailsBackdrop')
  local panel = bestiaryWindow:recursiveGetChildById('detailsPanel')

  if backdrop then
    backdrop:setVisible(true)
  end
  setMainBestiaryInputEnabled(false)
  panel:setVisible(true)
  ensureDetailsLayerOnTop()

  local diff = BestiaryDifficulty[creature.difficulty] or BestiaryDifficulty[1]

  local detailSprite = panel:recursiveGetChildById('detailSprite')
  if not detailSprite then
    g_logger.error("[Bestiary] detailSprite nao encontrado - verifique bestiary.otui")
  else
    applyCreatureOutfit(detailSprite, creature, { detail = true })
  end

  panel:recursiveGetChildById('detailName'):setText(creature.name)

  local diffLabel = panel:recursiveGetChildById('detailDifficulty')
  diffLabel:setText(string.format("%s%s%d kills para completar", diff.name, DETAIL_SUBTITLE_SEP, diff.kills))
  diffLabel:setColor("#00ffccff")
  diffLabel:setBorderColor("#00ffcc88")
  diffLabel:setBackgroundColor("#00ffcc18")

  panel:recursiveGetChildById('detailHp'):setText(string.format("%d HP", creature.hp or 0))
  panel:recursiveGetChildById('detailExp'):setText(string.format("%d EXP", creature.exp or 0))

  renderElementGrid(panel, creature)
  renderLootSection(panel, creature, diff)
  updateDetailProgress(panel, creature, diff)
  updateDetailScrollHeight(panel)
  scheduleDetailScrollRefresh(panel)
  resetDetailScroll(panel)

  scheduleEvent(function()
    if selectedCreature == creature and panel:isVisible() then
      updateDetailProgress(panel, creature, diff)
      ensureDetailsLayerOnTop()
    end
  end, 50)
end

function hideDetails()
  local backdrop = bestiaryWindow:recursiveGetChildById('detailsBackdrop')
  local panel = bestiaryWindow:recursiveGetChildById('detailsPanel')
  if backdrop then
    backdrop:setVisible(false)
  end
  panel:setVisible(false)
  setMainBestiaryInputEnabled(true)
  selectedCreature = nil
end

-- ---------------------------------------------------------------------------
-- Kill toasts (canto superior esquerdo do mapa)
-- ---------------------------------------------------------------------------

function areKillToastsEnabled()
  if modules.client_options and modules.client_options.getOption then
    return modules.client_options.getOption('showBestiaryKillToasts') ~= false
  end
  return true
end

function getKillToastMaxLines()
  if modules.client_options and modules.client_options.getOption then
    local value = tonumber(modules.client_options.getOption('bestiaryKillToastMaxLines'))
    if value then
      value = math.floor(value)
      if value >= 1 and value <= KILL_TOAST_MAX_LINES_LIMIT then
        return value
      end
    end
  end
  return KILL_TOAST_MAX_LINES_DEFAULT
end

local KILL_TOAST_MAP_INSET = 8

local function estimateMapDrawRect(mapPanel)
  local padL = mapPanel:getPaddingLeft()
  local padT = mapPanel:getPaddingTop()
  local clipW = mapPanel:getWidth() - padL - mapPanel:getPaddingRight()
  local clipH = mapPanel:getHeight() - padT - mapPanel:getPaddingBottom()
  if clipW <= 0 or clipH <= 0 then
    return { x = padL, y = padT, width = clipW, height = clipH }
  end

  local centerX = padL + clipW / 2
  local centerY = padT + clipH / 2
  local mapW, mapH

  if mapPanel:isKeepAspectRatioEnabled() then
    local zoom = mapPanel:getZoom()
    local dim = mapPanel:getVisibleDimension()
    mapH = zoom
    mapW = zoom * (dim.width / dim.height)
    local scale = math.min(clipW / mapW, clipH / mapH)
    mapW = mapW * scale
    mapH = mapH * scale
  else
    mapW = clipW - 2
    mapH = clipH - 2
  end

  return {
    x = math.floor(centerX - mapW / 2),
    y = math.floor(centerY - mapH / 2),
    width = math.floor(mapW),
    height = math.floor(mapH)
  }
end

local function getMapDrawRect(mapPanel)
  if mapPanel.getMapRect then
    return mapPanel:getMapRect()
  end
  return estimateMapDrawRect(mapPanel)
end

function initKillToasts()
  local mapPanel = modules.game_interface.getMapPanel()
  if mapPanel then
    connect(mapPanel, {
      onGeometryChange = adjustKillToastOverlayMargin,
      onVisibleDimensionChange = adjustKillToastOverlayMargin
    })
  end
  ensureKillToastsPanel()
end

function adjustKillToastOverlayMargin()
  if not killToastPanel or killToastPanel:isDestroyed() then
    return
  end

  local mapPanel = modules.game_interface.getMapPanel()
  if not mapPanel then
    return
  end

  local mapRect = getMapDrawRect(mapPanel)
  killToastPanel:setMarginLeft((mapRect.x or 0) + KILL_TOAST_MAP_INSET)
  killToastPanel:setMarginTop((mapRect.y or 0) + KILL_TOAST_MAP_INSET)
end

function ensureKillToastsPanel()
  if not killToastStylesLoaded then
    local mapPanel = modules.game_interface.getMapPanel()
    if not mapPanel then
      return false
    end
    killToastPanel = g_ui.loadUI('bestiary_killtoast', mapPanel)
    if not killToastPanel then
      g_logger.error("[Bestiary] Falha ao carregar bestiary_killtoast.otui")
      return false
    end
    killToastList = killToastPanel
    killToastStylesLoaded = true
  end

  if not killToastPanel or killToastPanel:isDestroyed() then
    return false
  end

  killToastPanel:setVisible(true)
  adjustKillToastOverlayMargin()
  killToastPanel:raise()
  return true
end

function detectSyncKillDeltas(killsTable)
  if not killToastReady or not areKillToastsEnabled() or not killsTable then
    return
  end

  for name, kills in pairs(killsTable) do
    local creature = findCreatureByName(name)
    if creature then
      local newKills = tonumber(kills) or 0
      local oldKills = creature.kills or 0
      if newKills > oldKills then
        handleKillToast(creature, oldKills, newKills)
      end
    end
  end
end

function terminateKillToasts()
  clearAllKillToasts()
  local mapPanel = modules.game_interface.getMapPanel()
  if mapPanel then
    disconnect(mapPanel, {
      onGeometryChange = adjustKillToastOverlayMargin,
      onVisibleDimensionChange = adjustKillToastOverlayMargin
    })
  end
  if killToastPanel and not killToastPanel:isDestroyed() then
    killToastPanel:destroy()
  end
  killToastPanel = nil
  killToastList = nil
  killToastStylesLoaded = false
end

function cancelToastTimers(widget)
  if not widget then
    return
  end
  if widget.expireEvent then
    removeEvent(widget.expireEvent)
    widget.expireEvent = nil
  end
  g_effects.cancelFade(widget)
end

function removeKillToast(widget, immediate)
  if not widget or widget:isDestroyed() then
    return
  end

  if widget.creatureNameKey and activeProgressToasts[widget.creatureNameKey] == widget then
    activeProgressToasts[widget.creatureNameKey] = nil
  end

  cancelToastTimers(widget)

  if immediate then
    widget:destroy()
    return
  end

  g_effects.fadeOut(widget, KILL_TOAST_FADE_MS)
  scheduleEvent(function()
    if widget and not widget:isDestroyed() then
      widget:destroy()
    end
  end, KILL_TOAST_FADE_MS + 50)
end

function clearAllKillToasts()
  for _, widget in pairs(activeProgressToasts) do
    if widget and not widget:isDestroyed() then
      cancelToastTimers(widget)
      widget:destroy()
    end
  end
  activeProgressToasts = {}

  if killToastList then
    killToastList:destroyChildren()
  end
end

function enforceMaxVisibleToasts()
  if not killToastList then
    return
  end

  local maxVisible = getKillToastMaxLines()
  local children = killToastList:getChildren()
  while #children > maxVisible do
    removeKillToast(children[1], false)
    children = killToastList:getChildren()
  end
end

function scheduleToastExpire(widget)
  cancelToastTimers(widget)
  widget:setOpacity(1)
  widget.expireEvent = scheduleEvent(function()
    widget.expireEvent = nil
    removeKillToast(widget, false)
  end, KILL_TOAST_HOLD_MS)
end

function styleProgressToast(widget)
  widget:setBorderColor('#00ffcc88')
  local label = widget:getChildById('toastLabel')
  if label then
    label:setColor('#00ffccff')
  end
  local spriteBg = widget:getChildById('toastSpriteBg')
  if spriteBg then
    spriteBg:setBackgroundColor('#8b8378cc')
    spriteBg:setBorderColor('#00ffcc66')
  end
end

function styleCompleteToast(widget)
  widget:setBorderColor('#ffd700aa')
  local label = widget:getChildById('toastLabel')
  if label then
    label:setColor('#ffd700ff')
  end
  local spriteBg = widget:getChildById('toastSpriteBg')
  if spriteBg then
    spriteBg:setBackgroundColor('#9a8a5ccc')
    spriteBg:setBorderColor('#ffd700aa')
  end
end

function applyToastSprite(widget, creature)
  local sprite = widget:recursiveGetChildById('toastSprite')
  if not sprite then
    return
  end
  applyCreatureOutfit(sprite, creature, { toast = true })
end

function showProgressToast(creature, kills, maxKills)
  if not areKillToastsEnabled() then
    return
  end
  if not ensureKillToastsPanel() then
    return
  end

  local nameKey = creature.name:lower()
  local existing = activeProgressToasts[nameKey]

  if existing and not existing:isDestroyed() then
    applyToastSprite(existing, creature)
    local label = existing:getChildById('toastLabel')
    if label then
      label:setText(string.format('%s  %d/%d', creature.name, kills, maxKills))
    end
    styleProgressToast(existing)
    existing:setVisible(true)
    existing:setOpacity(1)
    scheduleToastExpire(existing)
    existing:raise()
    killToastPanel:raise()
    g_logger.info(string.format("[Bestiary] toast: %s %d/%d", creature.name, kills, maxKills))
    return
  end

  local toast = g_ui.createWidget('BestiaryKillToast', killToastList)
  if not toast then
    g_logger.error("[Bestiary] Falha ao criar BestiaryKillToast")
    return
  end
  toast.creatureNameKey = nameKey
  activeProgressToasts[nameKey] = toast

  applyToastSprite(toast, creature)
  local label = toast:getChildById('toastLabel')
  if label then
    label:setText(string.format('%s  %d/%d', creature.name, kills, maxKills))
  end
  styleProgressToast(toast)
  toast:setVisible(true)
  toast:setOpacity(1)

  enforceMaxVisibleToasts()
  scheduleToastExpire(toast)
  killToastPanel:raise()
  toast:raise()
  g_logger.info(string.format("[Bestiary] toast: %s %d/%d", creature.name, kills, maxKills))
end

function showCompleteToast(creature)
  if not areKillToastsEnabled() then
    return
  end
  if not ensureKillToastsPanel() then
    return
  end

  local nameKey = creature.name:lower()
  local existing = activeProgressToasts[nameKey]
  if existing and not existing:isDestroyed() then
    removeKillToast(existing, true)
  end
  activeProgressToasts[nameKey] = nil

  local toast = g_ui.createWidget('BestiaryKillToast', killToastList)
  if not toast then
    g_logger.error("[Bestiary] Falha ao criar BestiaryKillToast (complete)")
    return
  end
  applyToastSprite(toast, creature)
  local label = toast:getChildById('toastLabel')
  if label then
    label:setText(tr('%s - Bestiary completo!', creature.name))
  end
  styleCompleteToast(toast)
  toast:setVisible(true)
  toast:setOpacity(1)

  enforceMaxVisibleToasts()
  scheduleToastExpire(toast)
  killToastPanel:raise()
  toast:raise()
end

function handleKillToast(creature, previousKills, newKills)
  if not creature or not areKillToastsEnabled() then
    return
  end

  local diff = BestiaryDifficulty[creature.difficulty] or BestiaryDifficulty[1]
  local maxKills = diff.kills
  newKills = newKills or creature.kills or 0
  previousKills = previousKills or 0

  if newKills >= maxKills then
    if previousKills < maxKills then
      showCompleteToast(creature)
    end
    return
  end

  showProgressToast(creature, newKills, maxKills)
end
