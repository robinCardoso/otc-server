buttonsWindow = nil
contentsPanel = nil
buttonsToggleButton = nil

local BUTTONS_GRID_CELL = 32
local BUTTONS_GRID_SPACING = 4

local TOP_GAME_PANEL_IDS = {
  leftGameButtonsPanel = true,
  rightGameButtonsPanel = true,
}

local function isTopGamePanel(widget)
  return widget and TOP_GAME_PANEL_IDS[widget:getId()] == true
end

function isPanelOpen()
  return buttonsWindow
    and not buttonsWindow:isDestroyed()
    and buttonsWindow:isExplicitlyVisible()
end

local function releaseButton(button)
  local panel = button.topMenuPanel
  if not panel or panel:isDestroyed() then
    return
  end
  if button:getParent() == panel then
    return
  end
  button:setParent(panel)
  local siblings = panel:getChildren()
  table.sort(siblings, function(a, b)
    return (a.index or 1000) < (b.index or 1000)
  end)
  panel:reorderChildren(siblings)
end

function releaseAllButtons()
  if not contentsPanel or not contentsPanel.buttons then
    return
  end
  local children = contentsPanel.buttons:getChildren()
  for i = #children, 1, -1 do
    releaseButton(children[i])
  end
end

function collectFromTopMenu()
  if not isPanelOpen() or not modules.client_topmenu then
    return
  end
  local topMenu = modules.client_topmenu.getTopMenu()
  if not topMenu then
    return
  end
  takeButtons(topMenu.leftGameButtonsPanel:getChildren())
  takeButtons(topMenu.rightGameButtonsPanel:getChildren())
end

local function syncToggleButtonState()
  if not buttonsToggleButton then
    return
  end
  if isPanelOpen() then
    buttonsToggleButton:setOn(true)
  else
    buttonsToggleButton:setOn(false)
  end
end

function onGameStart()
  if not buttonsToggleButton then
    return
  end
  buttonsToggleButton:show()
  syncToggleButtonState()
end

function onGameEnd()
  if not buttonsToggleButton then
    return
  end
  if isPanelOpen() then
    releaseAllButtons()
    buttonsWindow:close(true)
  end
  buttonsToggleButton:setOn(false)
  buttonsToggleButton:hide()
end

function init()
  connect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })

  buttonsWindow = g_ui.loadUI('buttons', modules.game_interface.getRightPanel())
  buttonsWindow:disableResize()
  contentsPanel = buttonsWindow.contentsPanel

  if not contentsPanel.buttons then
    buttonsWindow:close()
    return
  end

  buttonsWindow.onOpen = onPanelOpen
  buttonsWindow:setup()

  buttonsToggleButton = modules.client_topmenu.addRightButton(
    'buttonsPanelButton',
    tr('Buttons'),
    '/images/topbuttons/buttons',
    toggle,
    false,
    1
  )
  buttonsToggleButton:hide()

  if g_game.isOnline() then
    onGameStart()
  end
end

function terminate()
  disconnect(g_game, { onGameStart = onGameStart, onGameEnd = onGameEnd })

  if buttonsToggleButton then
    buttonsToggleButton:destroy()
    buttonsToggleButton = nil
  end
  buttonsWindow:destroy()
end

function toggle()
  if not buttonsWindow or buttonsWindow:isDestroyed() then
    return
  end
  if isPanelOpen() then
    buttonsWindow:close()
  else
    buttonsWindow:open()
  end
end

function onMiniWindowClose()
  releaseAllButtons()
  if buttonsToggleButton then
    buttonsToggleButton:setOn(false)
  end
end

function onPanelOpen()
  collectFromTopMenu()
  if buttonsToggleButton then
    buttonsToggleButton:setOn(true)
  end
end

function takeButtons(buttons)
  if not isPanelOpen() or not contentsPanel.buttons then
    return
  end
  for i, button in ipairs(buttons) do
    takeButton(button, true)
  end
  updateOrder()
end

function takeButton(button, dontUpdateOrder)
  if not isPanelOpen() or not contentsPanel.buttons then
    return
  end
  if button:getParent() == contentsPanel.buttons then
    return
  end

  local parent = button:getParent()
  if isTopGamePanel(parent) then
    button.topMenuPanel = parent
  elseif not button.topMenuPanel then
    return
  end

  button:setParent(contentsPanel.buttons)
  if not dontUpdateOrder then
    updateOrder()
  end
end

function updateOrder()
   local children = contentsPanel.buttons:getChildren()
   table.sort(children, function(a, b)
    return (a.index or 1000) < (b.index or 1000)
   end)
   contentsPanel.buttons:reorderChildren(children)
   local visibleCount = 0
   for _, child in ipairs(children) do
    if child:isVisible() then
      visibleCount = visibleCount + 1
    end
   end
   if visibleCount == 0 then
    return
   end

   local function resizeForGrid()
     if not buttonsWindow or buttonsWindow:isDestroyed() then
       return
     end
     local panel = contentsPanel.buttons
     local panelWidth = panel:getWidth()
     if panelWidth <= 0 then
       return
     end

     local buttonSize = BUTTONS_GRID_CELL
     if children[1] and children[1]:getHeight() > 0 then
       buttonSize = children[1]:getHeight()
     end

     local cols = math.max(1, math.floor((panelWidth + BUTTONS_GRID_SPACING) / (buttonSize + BUTTONS_GRID_SPACING)))
     local rows = math.ceil(visibleCount / cols)
     local gridHeight = rows * buttonSize + math.max(0, rows - 1) * BUTTONS_GRID_SPACING
     local buttonsPadding = panel:getPaddingTop() + panel:getPaddingBottom()
     local extra = contentsPanel:getMarginTop() + contentsPanel:getMarginBottom()
       + contentsPanel:getPaddingTop() + contentsPanel:getPaddingBottom()
       + buttonsPadding + 6
     buttonsWindow:setHeight(gridHeight + extra)
   end

   resizeForGrid()
   scheduleEvent(resizeForGrid, 50)
end
