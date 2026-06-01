-- Depot stock UI — extended opcode 205
-- Doc: otserv_860-orig/docs/STOCK-MODULE.md

local STOCK_OPCODE = 205

local window = nil
local stockButton = nil
local ui = {}

local catalogData = nil
local selectedRef = nil
local selectedCell = nil
local selectedClientId = nil
local selectedSource = "depot" -- depot | player
local withdrawQty = 1
local currentCategory = "all"
local currentSort = "name"
local searchText = ""
local stockReadOnly = false

local PK_BLOCK_MESSAGE_DEFAULT = tr("Voce nao pode usar o estoque com skull de PK.")

local MODIFY_ACTIONS = {
  withdraw = true,
  deposit = true,
  depositAll = true,
}

local CATEGORY_LABELS = {
  all = "Todos",
  equipment = "Equip",
  containers = "Bags",
  runes = "Runas",
  food = "Food",
  valuables = "Valor",
  other = "Outros",
}

local CATEGORY_BUTTON_IDS = {
  all = "catAll",
  equipment = "catEquipment",
  containers = "catContainers",
  runes = "catRunes",
  food = "catFood",
  valuables = "catValuables",
  other = "catOther",
}

local function updateCategorySelection()
  if not window then
    return
  end
  for category, buttonId in pairs(CATEGORY_BUTTON_IDS) do
    local button = window:recursiveGetChildById(buttonId)
    if button then
      button:setOn(category == currentCategory)
    end
  end
end

local function isLocalPkLocked()
  local player = g_game.getLocalPlayer()
  if not player then
    return false
  end
  return player:getSkull() >= SkullWhite
end

local function getPkBlockMessage()
  if catalogData and catalogData.blockReason and catalogData.blockReason ~= "" then
    return catalogData.blockReason
  end
  return PK_BLOCK_MESSAGE_DEFAULT
end

function setStockReadOnly(readOnly, blockReason)
  stockReadOnly = readOnly == true
  if not window then
    return
  end

  local buttonIds = { "withdrawButton", "depositButton", "depositAllButton", "qtyMinus", "qtyPlus" }
  for _, id in ipairs(buttonIds) do
    local button = window:recursiveGetChildById(id)
    if button then
      button:setEnabled(not stockReadOnly)
    end
  end

  local panel = window:recursiveGetChildById("pkBlockPanel")
  local label = window:recursiveGetChildById("pkBlockLabel")
  if panel and label then
    if stockReadOnly then
      label:setText(blockReason and blockReason ~= "" and blockReason or PK_BLOCK_MESSAGE_DEFAULT)
      panel:setVisible(true)
      panel:setHeight(22)
    else
      label:setText("")
      panel:setVisible(false)
      panel:setHeight(0)
    end
  end
end

local function isModifyBlocked()
  if stockReadOnly then
    displayInfoBox(tr("Estoque"), getPkBlockMessage())
    return true
  end
  return false
end

local function isEnabled()
  if STOCK_ENABLED == false then
    return false
  end
  return true
end

local function sendAction(action, data)
  if not g_game.getFeature(GameExtendedOpcode) then
    return
  end
  if MODIFY_ACTIONS[action] and stockReadOnly then
    displayInfoBox(tr("Estoque"), getPkBlockMessage())
    return
  end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedJSONOpcode(STOCK_OPCODE, { action = action, data = data or {} })
  end
end

local function requestCatalog()
  sendAction("request", {
    filter = currentCategory,
    search = searchText,
    sort = currentSort,
  })
end

local selectEntry

local function bindUi()
  if not window then
    return
  end
  ui.summaryLabel = window:recursiveGetChildById("summaryLabel")
  ui.searchEdit = window:recursiveGetChildById("searchEdit")
  ui.sortCombo = window:recursiveGetChildById("sortCombo")
  ui.itemsScroll = window:recursiveGetChildById("itemsScroll")
  ui.playerScroll = window:recursiveGetChildById("playerScroll")
  ui.detailName = window:recursiveGetChildById("detailName")
  ui.detailTotal = window:recursiveGetChildById("detailTotal")
  ui.detailBox = window:recursiveGetChildById("detailBox")
  ui.qtyLabel = window:recursiveGetChildById("qtyLabel")

  local function getDragCell(widget)
    if not widget then return nil end
    if widget:getId() == "itemWidget" then
      return widget:getParent()
    end
    if widget.isPlayerCell ~= nil then
      return widget
    end
    return nil
  end

  if ui.itemsScroll then
    ui.itemsScroll.canAcceptDrop = function(self, widget, mousePos)
      return not stockReadOnly
    end
    ui.itemsScroll.onDrop = function(self, widget, mousePos)
      if stockReadOnly then
        displayInfoBox(tr("Estoque"), getPkBlockMessage())
        return false
      end
      local dragCell = getDragCell(widget)
      if dragCell and dragCell.isPlayerCell == true and dragCell.entryRef then
        selectEntry(dragCell.entryRef, "player", dragCell)
        onDepositClick()
        return true
      end
      return false
    end
  end

  if ui.playerScroll then
    ui.playerScroll.canAcceptDrop = function(self, widget, mousePos)
      return not stockReadOnly
    end
    ui.playerScroll.onDrop = function(self, widget, mousePos)
      if stockReadOnly then
        displayInfoBox(tr("Estoque"), getPkBlockMessage())
        return false
      end
      local dragCell = getDragCell(widget)
      if dragCell and dragCell.isPlayerCell == false and dragCell.entryRef then
        selectEntry(dragCell.entryRef, "depot", dragCell)
        onWithdrawClick()
        return true
      end
      return false
    end
  end
end

local function getAggregatedDepotItems()
  if not catalogData or not catalogData.items then
    return {}
  end
  local map = {}
  for _, entry in ipairs(catalogData.items) do
    local key = entry.clientId
    if not map[key] then
      map[key] = {
        clientId = entry.clientId,
        itemId = entry.itemId,
        name = entry.name,
        category = entry.category,
        totalCount = 0,
        stacks = {},
      }
    end
    map[key].totalCount = map[key].totalCount + (entry.count or 1)
    table.insert(map[key].stacks, entry)
  end
  local list = {}
  for _, group in pairs(map) do
    list[#list + 1] = group
  end
  table.sort(list, function(a, b)
    return (a.name or ""):lower() < (b.name or ""):lower()
  end)
  return list
end

local function pathsEqual(a, b)
  if not a or #a == 0 then
    return not b or #b == 0
  end
  if not b or #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

local function copyItemRef(entry)
  if not entry then
    return nil
  end
  local ref = {
    itemId = entry.itemId,
    clientId = entry.clientId,
    invSlot = entry.invSlot or entry.slot,
    depotBox = entry.depotBox,
    index = entry.index,
    name = entry.name,
    count = entry.count,
    totalCount = entry.totalCount,
    stackCount = entry.stackCount,
  }
  if entry.path then
    ref.path = {}
    for i, v in ipairs(entry.path) do
      ref.path[i] = v
    end
  end
  return ref
end

local function refsEqual(a, b)
  if not a or not b then
    return false
  end
  if tonumber(a.itemId) ~= tonumber(b.itemId) then
    return false
  end
  if tonumber(a.invSlot) ~= tonumber(b.invSlot) then
    return false
  end
  if tonumber(a.depotBox) ~= tonumber(b.depotBox) then
    return false
  end
  if tonumber(a.index) ~= tonumber(b.index) then
    return false
  end
  return pathsEqual(a.path, b.path)
end

local function buildActionPayload(ref, count)
  if not ref then
    return nil
  end
  return {
    itemId = ref.itemId,
    invSlot = ref.invSlot,
    depotBox = ref.depotBox,
    path = ref.path,
    index = ref.index,
    count = count,
  }
end

local function clearSelectionVisual()
  if selectedCell then
    selectedCell:setBorderColor("#555555")
    selectedCell = nil
  end
end

local function highlightDropTarget(isPlayerCell)
  if not window then return end
  local gridPanel = window:recursiveGetChildById("gridPanel")
  local playerStrip = window:recursiveGetChildById("playerStrip")
  
  if isPlayerCell then
    if gridPanel then
      gridPanel:setBorderWidth(2)
      gridPanel:setBorderColor("#00ff0088")
    end
  else
    if playerStrip then
      playerStrip:setBorderWidth(2)
      playerStrip:setBorderColor("#00ff0088")
    end
  end
end

local function clearDropTargetHighlight()
  if not window then return end
  local gridPanel = window:recursiveGetChildById("gridPanel")
  local playerStrip = window:recursiveGetChildById("playerStrip")
  if gridPanel then
    gridPanel:setBorderWidth(0)
  end
  if playerStrip then
    playerStrip:setBorderWidth(0)
  end
end

local function findPlayerEntry(ref)
  if not ref or not catalogData or not catalogData.playerSlots then
    return nil
  end
  for _, entry in ipairs(catalogData.playerSlots) do
    if tonumber(entry.itemId) == tonumber(ref.itemId)
        and tonumber(entry.invSlot or entry.slot) == tonumber(ref.invSlot)
        and tonumber(entry.index) == tonumber(ref.index)
        and pathsEqual(entry.path, ref.path) then
      return entry
    end
  end
  return nil
end

local function findDepotStack(ref, minCount)
  if not ref or not catalogData or not catalogData.items then
    return nil
  end
  minCount = minCount or 1
  for _, entry in ipairs(catalogData.items) do
    if tonumber(entry.itemId) == tonumber(ref.itemId)
        and tonumber(entry.depotBox) == tonumber(ref.depotBox)
        and tonumber(entry.index) == tonumber(ref.index)
        and pathsEqual(entry.path, ref.path)
        and (entry.count or 1) >= minCount then
      return entry
    end
  end
  for _, entry in ipairs(catalogData.items) do
    if tonumber(entry.clientId) == tonumber(ref.clientId)
        and (entry.count or 1) >= minCount then
      return entry
    end
  end
  return nil
end

local function findDepotGroup(ref)
  if not ref or not catalogData or not catalogData.items then
    return nil
  end
  for _, group in ipairs(getAggregatedDepotItems()) do
    if tonumber(group.clientId) == tonumber(ref.clientId) then
      return group
    end
  end
  return nil
end

local function updateDetailPanel()
  if not ui.detailName then
    return
  end
  if not selectedClientId then
    ui.detailName:setText(tr("Selecione um item"))
    ui.detailTotal:setText("")
    ui.detailBox:setText("")
    if ui.qtyLabel then
      ui.qtyLabel:setText("1")
    end
    return
  end

  if selectedSource == "depot" then
    local groups = getAggregatedDepotItems()
    for _, group in ipairs(groups) do
      if tonumber(group.clientId) == tonumber(selectedClientId) then
        ui.detailName:setText(group.name or "?")
        ui.detailTotal:setText(string.format("Total: %d", group.totalCount))
        local boxHint = ""
        if group.stacks[1] and group.stacks[1].depotBox then
          boxHint = string.format("Caixa #%d (+)", group.stacks[1].depotBox, #group.stacks - 1)
        end
        ui.detailBox:setText(boxHint)
        local first = group.stacks[1]
        withdrawQty = (first and first.count) or 1
        if ui.qtyLabel then
          ui.qtyLabel:setText(tostring(withdrawQty))
        end
        return
      end
    end
  else
    local entry = findPlayerEntry(selectedRef)
    if entry then
      ui.detailName:setText(entry.name or "?")
      ui.detailTotal:setText(string.format("Qtd: %d", entry.count or 1))
      ui.detailBox:setText(tr("No inventario"))
      withdrawQty = math.min(withdrawQty, entry.count or 1)
    elseif selectedRef then
      ui.detailName:setText(selectedRef.name or "?")
      ui.detailTotal:setText(string.format("Qtd: %d", selectedRef.count or 1))
      ui.detailBox:setText(tr("No inventario"))
      withdrawQty = math.min(withdrawQty, selectedRef.count or 1)
    end
    if ui.qtyLabel then
      ui.qtyLabel:setText(tostring(withdrawQty))
    end
  end
end

selectEntry = function(entry, source, cell)
  clearSelectionVisual()
  selectedRef = copyItemRef(entry)
  selectedClientId = entry and entry.clientId or nil
  selectedSource = source
  selectedCell = cell
  if cell then
    cell:setBorderColor("#c8a028")
  end
  if source == "player" then
    withdrawQty = entry.count or 1
  else
    withdrawQty = entry.stackCount or entry.count or 1
  end
  if ui.qtyLabel then
    ui.qtyLabel:setText(tostring(withdrawQty))
  end
  updateDetailPanel()
end

local function tryReselectCell(scroll, ref, source)
  if not scroll or not ref then
    return
  end
  for _, child in ipairs(scroll:getChildren()) do
    local matches = false
    if source == "depot" then
      matches = child.entryRef and tonumber(child.entryRef.clientId) == tonumber(ref.clientId)
    elseif child.entryRef then
      matches = refsEqual(child.entryRef, ref)
    end
    if matches then
      selectEntry(child.entryRef, source, child)
      if source == "player" then
        local entry = findPlayerEntry(ref)
        if entry then
          selectedRef = copyItemRef(entry)
          updateDetailPanel()
        end
      elseif source == "depot" then
        local group = findDepotGroup(ref)
        if group then
          selectedClientId = group.clientId
          updateDetailPanel()
        end
      end
      return
    end
  end
end

local function getSelectedStack()
  if not selectedRef or not catalogData then
    return nil
  end
  if selectedSource == "player" then
    return findPlayerEntry(selectedRef)
  end
  for _, entry in ipairs(catalogData.items or {}) do
    if tonumber(entry.clientId) == tonumber(selectedRef.clientId)
        and tonumber(entry.depotBox) == tonumber(selectedRef.depotBox)
        and tonumber(entry.index) == tonumber(selectedRef.index)
        and pathsEqual(entry.path, selectedRef.path) then
      return entry
    end
  end
  return nil
end

local function updateSummary()
  if not ui.summaryLabel or not catalogData or not catalogData.summary then
    return
  end
  local s = catalogData.summary
  ui.summaryLabel:setText(string.format(
    "Itens: %d | Tipos: %d | Total: %d | Limite depot: %d",
    s.slots or 0, s.distinct or 0, s.totalCount or 0, s.depotLimit or 0))
end

local function clearGrid(panel)
  if not panel then
    return
  end
  panel:destroyChildren()
end

local function createItemCell(parent, entry, isPlayer)
  local cell = g_ui.createWidget(isPlayer and "StockPlayerCell" or "StockItemCell", parent)
  cell.entryRef = copyItemRef(entry)
  cell.isPlayerCell = isPlayer

  local itemWidget = cell:getChildById("itemWidget")
  local count = entry.count or 1
  if not isPlayer and entry.totalCount then
    count = entry.totalCount
  end
  if itemWidget then
    itemWidget:setItemId(entry.clientId)
    itemWidget:setItemCount(count > 1 and count or 1)
    
    -- Drag entre celulas (depot <-> inventario); servidor confirma via opcode 205
    itemWidget:setVirtual(false)
    itemWidget:setPhantom(false)

    -- Forward mouse events to the cell for selection
    itemWidget.onMousePress = function(widget, mousePos, mouseButton)
      return cell.onMousePress(cell, mousePos, mouseButton)
    end
    itemWidget.onDoubleClick = function()
      return cell.onDoubleClick()
    end
    
    -- Highlight drag targets
    itemWidget.onDragEnter = function(self, mousePos)
      local result = UIItem.onDragEnter(self, mousePos)
      if result then
        highlightDropTarget(isPlayer)
      end
      return result
    end

    itemWidget.onDragLeave = function(self, droppedWidget, mousePos)
      clearDropTargetHighlight()
      return UIItem.onDragLeave(self, droppedWidget, mousePos)
    end
    
    -- Forward drop events to the cell
    itemWidget.canAcceptDrop = function(self, dragWidget, mousePos)
      return not stockReadOnly
    end
    itemWidget.onDrop = function(self, dragWidget, mousePos)
      if stockReadOnly then
        displayInfoBox(tr("Estoque"), getPkBlockMessage())
        return false
      end
      return cell.onDrop(cell, dragWidget, mousePos)
    end
  end

  local countLabel = cell:getChildById("countLabel")
  if countLabel then
    countLabel:setText("")
  end

  local function onCellClick()
    selectEntry(entry, isPlayer and "player" or "depot", cell)
  end

  cell.onClick = onCellClick

  cell.onMousePress = function(widget, mousePos, mouseButton)
    if mouseButton == MouseLeftButton then
      onCellClick()
      return true
    end
  end

  cell.onDoubleClick = function()
    selectEntry(entry, isPlayer and "player" or "depot", cell)
    if isModifyBlocked() then
      return true
    end
    if isPlayer then
      onDepositClick()
    else
      onWithdrawClick()
    end
    return true
  end

  cell.canAcceptDrop = function(self, widget, mousePos)
    return not stockReadOnly
  end
  cell.onDrop = function(self, widget, mousePos)
    if stockReadOnly then
      displayInfoBox(tr("Estoque"), getPkBlockMessage())
      return false
    end
    -- widget pode ser o itemWidget (UIItem) ou o proprio cell
    local dragCell = widget
    if widget:getId() == "itemWidget" then
      dragCell = widget:getParent()
    end
    
    if dragCell and dragCell.isPlayerCell ~= nil and dragCell.isPlayerCell ~= self.isPlayerCell and dragCell.entryRef then
      selectEntry(dragCell.entryRef, dragCell.isPlayerCell and "player" or "depot", dragCell)
      if dragCell.isPlayerCell then
        onDepositClick()
      else
        onWithdrawClick()
      end
      return true
    end
    return false
  end
end

local function rebuildDepotGrid()
  if not ui.itemsScroll then
    return
  end
  clearGrid(ui.itemsScroll)

  local groups = getAggregatedDepotItems()
  for _, group in ipairs(groups) do
    if currentCategory == "all" or group.category == currentCategory then
      if searchText == "" or (group.name or ""):lower():find(searchText:lower(), 1, true) then
        local firstStack = group.stacks[1]
        createItemCell(ui.itemsScroll, {
          clientId = group.clientId,
          itemId = group.itemId,
          name = group.name,
          count = group.totalCount,
          totalCount = group.totalCount,
          stackCount = firstStack and firstStack.count,
          category = group.category,
          depotBox = firstStack and firstStack.depotBox,
          path = firstStack and firstStack.path,
          index = firstStack and firstStack.index,
        }, false)
      end
    end
  end
end

local function rebuildPlayerStrip()
  if not ui.playerScroll then
    return
  end
  clearGrid(ui.playerScroll)
  if not catalogData or not catalogData.playerSlots then
    return
  end
  for _, entry in ipairs(catalogData.playerSlots) do
    createItemCell(ui.playerScroll, entry, true)
  end
end

local function applyCatalog(data)
  local prevRef = selectedRef
  local prevSource = selectedSource

  catalogData = data
  setStockReadOnly(data.readOnly, data.blockReason)
  selectedRef = nil
  selectedClientId = nil
  selectedSource = "depot"
  clearSelectionVisual()
  withdrawQty = 1
  updateSummary()
  rebuildDepotGrid()
  rebuildPlayerStrip()

  if prevRef then
    if prevSource == "player" then
      if findPlayerEntry(prevRef) then
        tryReselectCell(ui.playerScroll, prevRef, "player")
      end
    elseif prevSource == "depot" then
      if findDepotGroup(prevRef) then
        tryReselectCell(ui.itemsScroll, prevRef, "depot")
      end
    end
  end

  updateDetailPanel()
end

local function onExtendedJSONOpcode(protocol, code, jsonData)
  if type(jsonData) ~= "table" then
    return
  end

  local action = jsonData.action
  local data = jsonData.data

  if action == "catalog" and data then
    applyCatalog(data)
    return
  end

  if action == "result" and data then
    if not data.ok and data.message and data.message ~= "" then
      displayInfoBox(tr("Estoque"), data.message)
    elseif data.message and data.message ~= "" then
      modules.game_textmessage.displayStatusMessage(data.message)
    end
    if data.catalog then
      applyCatalog(data.catalog)
    elseif data.ok then
      requestCatalog()
    end
  end
end

function onRefreshClick()
  requestCatalog()
end

function onSearchChange()
  if not ui.searchEdit then
    return
  end
  searchText = ui.searchEdit:getText() or ""
  rebuildDepotGrid()
end

function onSortChange()
  if not ui.sortCombo then
    return
  end
  local option = ui.sortCombo:getCurrentOption()
  if option and option.data then
    currentSort = option.data
    requestCatalog()
  end
end

function onCategoryClick(category)
  if not CATEGORY_BUTTON_IDS[category] then
    return
  end
  currentCategory = category
  updateCategorySelection()
  rebuildDepotGrid()
end

function onQtyChange(delta)
  local maxQty = 1
  local stack = getSelectedStack()
  if selectedSource == "depot" then
    for _, group in ipairs(getAggregatedDepotItems()) do
      if tonumber(group.clientId) == tonumber(selectedClientId) then
        maxQty = group.totalCount or 1
        break
      end
    end
  elseif stack then
    maxQty = stack.count or 1
  end
  withdrawQty = math.max(1, math.min(maxQty, withdrawQty + delta))
  if ui.qtyLabel then
    ui.qtyLabel:setText(tostring(withdrawQty))
  end
end

function onWithdrawClick()
  if isModifyBlocked() then
    return
  end
  if selectedSource ~= "depot" or not selectedRef then
    displayInfoBox(tr("Estoque"), tr("Selecione um item do depot."))
    return
  end
  local entry = findDepotStack(selectedRef, withdrawQty)
  local sendCount = withdrawQty
  if entry then
    sendCount = math.min(withdrawQty, entry.count or withdrawQty)
  elseif selectedRef and selectedRef.stackCount then
    sendCount = math.min(withdrawQty, selectedRef.stackCount)
  end
  local payload = buildActionPayload(entry and copyItemRef(entry) or selectedRef, sendCount)
  if not payload or not payload.depotBox or payload.index == nil then
    displayInfoBox(tr("Estoque"), tr("Item do depot nao encontrado."))
    return
  end
  sendAction("withdraw", payload)
  scheduleEvent(requestCatalog, 150)
end

function onDepositClick()
  if isModifyBlocked() then
    return
  end
  if selectedSource ~= "player" or not selectedRef then
    displayInfoBox(tr("Estoque"), tr("Selecione um item do inventario."))
    return
  end
  local payload = buildActionPayload(selectedRef, withdrawQty)
  if not payload or not payload.invSlot then
    displayInfoBox(tr("Estoque"), tr("Item do inventario nao encontrado."))
    return
  end
  sendAction("deposit", payload)
  scheduleEvent(requestCatalog, 150)
end

function onDepositAllClick()
  if isModifyBlocked() then
    return
  end
  sendAction("depositAll", {})
end

local function createWindow()
  if window then
    return
  end
  local w = STOCK_WINDOW_WIDTH or 720
  local h = STOCK_WINDOW_HEIGHT or 520
  window = g_ui.displayUI("stock")
  if window then
    window:setSize({ width = w, height = h })
    window:hide()
    bindUi()
    if ui.sortCombo then
      ui.sortCombo:addOption("Nome", "name")
      ui.sortCombo:addOption("ID", "id")
      ui.sortCombo:addOption("Qtd", "count")
      ui.sortCombo:setCurrentOption(1)
    end
    updateCategorySelection()
  end
end

local function onSkullChange(localPlayer, skull)
  if not window or not window:isVisible() then
    return
  end
  if skull >= SkullWhite then
    setStockReadOnly(true, getPkBlockMessage())
  else
    setStockReadOnly(false)
    requestCatalog()
  end
end

local refreshEvent = nil
local function scheduleRefresh()
  if not window or not window:isVisible() then return end
  if refreshEvent then
    removeEvent(refreshEvent)
  end
  refreshEvent = scheduleEvent(function()
    refreshEvent = nil
    requestCatalog()
  end, 300)
end

function init()
  if not isEnabled() then
    return
  end

  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd,
  })

  connect(LocalPlayer, {
    onInventoryChange = scheduleRefresh,
    onSkullChange = onSkullChange,
  })

  connect(Container, {
    onOpen = scheduleRefresh,
    onClose = scheduleRefresh,
    onSizeChange = scheduleRefresh,
    onUpdateItem = scheduleRefresh
  })

  ProtocolGame.registerExtendedJSONOpcode(STOCK_OPCODE, onExtendedJSONOpcode)

  createWindow()

  stockButton = modules.client_topmenu.addRightGameToggleButton(
    "stockButton",
    tr("Estoque") .. " (Ctrl+Shift+E)",
    "/images/topbuttons/inventory",
    toggle,
    false,
    7
  )

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyDown("Ctrl+Shift+E", toggle, gameRootPanel)

  if g_game.isOnline() then
    onGameStart()
  end
end

function terminate()
  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd,
  })

  disconnect(LocalPlayer, {
    onInventoryChange = scheduleRefresh,
    onSkullChange = onSkullChange,
  })

  disconnect(Container, {
    onOpen = scheduleRefresh,
    onClose = scheduleRefresh,
    onSizeChange = scheduleRefresh,
    onUpdateItem = scheduleRefresh
  })

  ProtocolGame.unregisterExtendedJSONOpcode(STOCK_OPCODE, onExtendedJSONOpcode)

  local gameRootPanel = modules.game_interface.getRootPanel()
  if gameRootPanel then
    g_keyboard.unbindKeyDown("Ctrl+Shift+E", gameRootPanel)
  end

  if stockButton then
    stockButton:destroy()
    stockButton = nil
  end

  if window then
    window:destroy()
    window = nil
  end
  ui = {}
  catalogData = nil
end

function onGameStart()
  catalogData = nil
  stockReadOnly = false
end

function onGameEnd()
  hide()
  catalogData = nil
  stockReadOnly = false
end

function show()
  if not isEnabled() then
    return
  end
  if not g_game.getFeature(GameExtendedOpcode) then
    displayInfoBox(tr("Estoque"),
      tr("Requer GameExtendedOpcode e otcv8_stock.lua no servidor.\nVer docs/STOCK-MODULE.md"))
    return
  end
  createWindow()
  if not window then
    return
  end
  if isLocalPkLocked() then
    setStockReadOnly(true, PK_BLOCK_MESSAGE_DEFAULT)
  else
    setStockReadOnly(false)
  end
  window:show()
  window:raise()
  window:focus()
  if stockButton then
    stockButton:setOn(true)
  end
  requestCatalog()
end

function hide()
  if stockButton then
    stockButton:setOn(false)
  end
  if window then
    window:hide()
  end
end

function toggle()
  if not window or not window:isVisible() then
    show()
  else
    hide()
  end
end

-- exports for OTUI
onRefreshClick = onRefreshClick
onSearchChange = onSearchChange
onSortChange = onSortChange
onCategoryClick = onCategoryClick
onQtyChange = onQtyChange
onWithdrawClick = onWithdrawClick
onDepositClick = onDepositClick
onDepositAllClick = onDepositAllClick
