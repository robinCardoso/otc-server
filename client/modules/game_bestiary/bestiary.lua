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

-- FUTURO: tela "Carregando..." no login enquanto looks + kills sincronizam (opcode 207)

function init()
  bestiaryWindow = g_ui.loadUI('bestiary', modules.game_interface.getRootPanel())
  bestiaryWindow:hide()

  bestiaryButton = modules.client_topmenu.addRightGameToggleButton('bestiaryButton', tr('Bestiary') .. ' (Ctrl+Shift+B)', '/images/topbuttons/questlog', toggle)
  bestiaryButton:setOn(false)

  g_keyboard.bindKeyDown('Ctrl+Shift+B', toggle)

  local searchEdit = bestiaryWindow:recursiveGetChildById('searchEdit')
  searchEdit.onTextChange = onSearchChange

  local closeDetailsBtn = bestiaryWindow:recursiveGetChildById('closeDetailsBtn')
  closeDetailsBtn.onClick = hideDetails

  loadDatabase()
  buildCategories()
  selectedCategory = "All"

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
  local mainContent = bestiaryWindow:recursiveGetChildById('mainContent')
  if sidebar then
    sidebar:setEnabled(enabled)
  end
  if mainContent then
    mainContent:setEnabled(enabled)
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

function requestServerSync()
  if not g_game.getFeature(GameExtendedOpcode) then
    return
  end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedJSONOpcode(207, { action = "requestSync" })
  end
end

function scheduleServerSync(delayMs)
  scheduleEvent(function()
    if g_game.isOnline() then
      requestServerSync()
    end
  end, delayMs or 0)
end

function onGameStart()
  killToastReady = false
  ensureKillToastsPanel()
  scheduleServerSync(800)
end

function onGameEnd()
  looksSynced = false
  itemsSynced = false
  BestiaryItemLookup = {}
  killToastReady = false
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
  return searchEdit and searchEdit:getText() or ""
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
  return creatureByNameLower[name:lower()]
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
  -- protocolgame.lua já faz o chunk assembly (S/P/E) e json.decode antes de chamar aqui.
  -- jsonData chega como table Lua pronta.
  if type(jsonData) ~= "table" then
    g_logger.error("[Bestiary] onExtendedJSONOpcode: dado invalido (type=" .. type(jsonData) .. ")")
    return
  end

  local action = jsonData.action
  local data = jsonData.data

  if action == "sync" then
    detectSyncKillDeltas(data)

    for _, creature in ipairs(MonsterBestiaryDatabase) do
      creature.kills = 0
    end
    local applied = applyKillsFromServer(data or {})
    killToastReady = true
    g_logger.info(string.format("[Bestiary] sync: %d especies com kills", applied))

    refreshOverview()
    refreshMonsterGridIfVisible(getCurrentSearchText())

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

    refreshOverview()
    refreshMonsterGridIfVisible(getCurrentSearchText())

    if selectedCreature and selectedCreature.name:lower() == data.name:lower() and isBestiaryVisible() then
      showCreatureDetails(selectedCreature)
    end

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
    "[Bestiary] loot item nao resolvido: %s (serverId=%s, %s) — aguardando sync 'items'",
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
      creature.kills = 0
    end

    databaseIndexesBuilt = false
    buildDatabaseIndexes()

    g_logger.info(string.format("[Bestiary] Carregados %d monstros da base de dados com sucesso!", #MonsterBestiaryDatabase))
  else
    g_logger.error("[Bestiary] Arquivo bestiary_database.json nao encontrado!")
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
    requestServerSync()
    refreshOverview()
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

  if search == "" then
    return source
  end

  local result = {}
  for _, creature in ipairs(source) do
    local nameLower = creature._nameLower or creature.name:lower()
    if nameLower:find(search, 1, true) then
      result[#result + 1] = creature
    end
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
    gridStatus:setText(tr("Escolha uma classe à esquerda ou digite pelo menos 2 letras na busca. (%d criaturas)", total))
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
  if selectedCategory == "All" and searchLen < 2 then
    setGridStatus("pick_filter", 0, total)
    return
  end

  if total == 0 then
    setGridStatus("empty", 0, 0)
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
    g_logger.error("[Bestiary] detailSprite nao encontrado — verifique bestiary.otui")
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

function initKillToasts()
  local mapPanel = modules.game_interface.getMapPanel()
  if mapPanel then
    connect(mapPanel, { onGeometryChange = adjustKillToastOverlayMargin })
  end
  ensureKillToastsPanel()
end

function adjustKillToastOverlayMargin()
  if not killToastPanel or killToastPanel:isDestroyed() then
    return
  end

  local baseMargin = 8
  if g_settings.getBoolean("classicView") or g_app.isMobile() then
    killToastPanel:setMarginTop(baseMargin)
    return
  end

  local gameRootPanel = modules.game_interface.getRootPanel()
  local mapPanel = modules.game_interface.getMapPanel()
  if not gameRootPanel or not mapPanel then
    return
  end

  local dim = mapPanel:getVisibleDimension()
  if not dim or dim.height <= 0 then
    killToastPanel:setMarginTop(baseMargin)
    return
  end

  local tileSize = gameRootPanel:getHeight() / dim.height
  killToastPanel:setMarginTop(math.floor(tileSize) + baseMargin)
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
    disconnect(mapPanel, { onGeometryChange = adjustKillToastOverlayMargin })
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
    label:setText(tr('%s — Bestiary completo!', creature.name))
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
