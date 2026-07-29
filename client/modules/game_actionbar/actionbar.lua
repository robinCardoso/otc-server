local actionBars = {}
local settings = {}
local settingsFile = ""
local cachedSettings = nil
local window = nil
local mouseGrabberWidget = nil

local TYPE = {
  BLANK = 0,
  TEXT = 1,
  SPELL = 2,
  ITEM = 3
}

local ACTION = {
  BLANK = 0,
  EQUIP = 1,
  USE = 2,
  USE_SELF = 3,
  USE_TARGET = 4,
  USE_CROSS = 5
}

-- Lista de magias do TFS (opcode 202) — docs: otserv_860/docs/SPELL-LIST-PLAN.md
local SPELL_LIST_ENABLED = false -- disabled for testing
local SPELL_LIST_OPCODE = 202
local serverSpellList = nil
local serverSpellListMeta = nil
local assignSpellPendingWidget = nil
local assignSpellListTimeoutEvent = nil
local assignSpellCategoryCallback = nil
local SPELL_LIST_TIMEOUT_MS = 5000

local SPELL_CATEGORIES = { "attack", "support", "healing", "runes" }
local SPELL_CATEGORY_BUTTON_IDS = {
  attack = "tabAttack",
  support = "tabSupport",
  healing = "tabHealing",
  runes = "tabRunas",
}
local ASSIGN_SPELL_CATEGORY_SETTING = "assignSpellCategory"

local RUNE_CONJURE_PREFIXES = { "adevo ", "adana ", "adori ", "adura " }

local function isRuneConjureWords(words)
  if not words or words:len() == 0 then
    return false
  end
  if words == "adori blank" then
    return true
  end
  for _, prefix in ipairs(RUNE_CONJURE_PREFIXES) do
    if words:sub(1, #prefix) == prefix then
      return true
    end
  end
  return false
end

local function resolveClientCategory(words, localData)
  if isRuneConjureWords(words) then
    return "runes"
  end
  if localData then
    if localData.type == "Conjure" then
      return "support"
    end
    if localData.group then
      if localData.group[1] then
        return "attack"
      end
      if localData.group[2] then
        return "healing"
      end
      return "support"
    end
  end
  return "support"
end

-- SpellInfo usa vocations 1–8 (sorc/druid/pala/knight + promovidas).
-- TFS 8.60 envia os mesmos ids; mapeamento legado abaixo só para alguns protocolos 9.10+.
local function translateVocation(id)
  local version = g_game.getClientVersion()
  if version < 910 or (version >= 860 and version < 1100) then
    return id
  end

  if id == 1 or id == 11 then
    return 8 -- ek (legado — nao usar em 8.60)
  elseif id == 2 or id == 12 then
    return 7 -- rp
  elseif id == 3 or id == 13 then
    return 5 -- ms
  elseif id == 4 or id == 14 then
    return 6 -- ed
  end

  return id
end

local function isSpell(text) -- returns bool or table (spelldata, param text)
  text = text:lower():trim()

  for spellName, spellData in pairs(SpellInfo['Default']) do
    local words = spellData.words
    local param = spellData.parameter
    local data = spellData
    data.spellName = spellName

    if not param then
      if words == text then
        return {data=data}
      end
    else
      if text:find(words) then
        text = text:gsub(words, ""):trim()
        text = text:gsub('"', "")
        text = text:gsub("'", "")
        return {data=data, param=text}
      end
    end
  end

  return false
end

local function cancelAssignSpellListTimeout()
  if assignSpellListTimeoutEvent then
    removeEvent(assignSpellListTimeoutEvent)
    assignSpellListTimeoutEvent = nil
  end
end

local function clearServerSpellList()
  serverSpellList = nil
  serverSpellListMeta = nil
  assignSpellPendingWidget = nil
  cancelAssignSpellListTimeout()
end

local function requestServerSpellList()
  if not SPELL_LIST_ENABLED or not g_game.getFeature(GameExtendedOpcode) then
    return
  end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedJSONOpcode(SPELL_LIST_OPCODE, { action = "request", data = {} })
  end
end

local function lookupLocalSpellInfo(spellName, words)
  return Spells.lookupLocalInfo(spellName, words)
end

local function spellGroupsToArray(spellData)
  local groups = {}
  if spellData and spellData.group then
    for groupId in pairs(spellData.group) do
      table.insert(groups, groupId)
    end
  end
  return groups
end

local function buildSpellPreviewData(spellName, serverEntry, localData)
  local name = spellName or (serverEntry and serverEntry.name) or ""
  local words = (serverEntry and serverEntry.words) or (localData and localData.words) or ""
  local level = (serverEntry and serverEntry.level) or (localData and localData.level) or 0
  local mana = (serverEntry and serverEntry.mana) or (localData and localData.mana) or 0
  local param = false
  if serverEntry and serverEntry.parameter ~= nil then
    param = serverEntry.parameter
  elseif localData then
    param = localData.parameter
  end

  local spellId = 0
  local exhaustion = 2000
  local vocations = {}
  local source
  local clip

  if localData then
    spellId = localData.id or spellId
    exhaustion = localData.exhaustion or exhaustion
    vocations = localData.vocations or vocations
  end

  local iconData = Spells.getSpellIcon(name, words)
  source = iconData.source
  clip = iconData.clip

  return {
    words = words,
    cd = exhaustion / 1000,
    mana = mana,
    level = level,
    source = source,
    clip = clip,
    name = name,
    param = param,
    group = spellGroupsToArray(localData),
    id = spellId,
    vocations = vocations,
  }
end

local function onSpellListExtendedJSONOpcode(protocol, code, jsonData)
  if type(jsonData) ~= "table" or jsonData.action ~= "spellList" then
    return
  end
  local data = jsonData.data
  if type(data) ~= "table" or type(data.spells) ~= "table" then
    return
  end

  serverSpellList = data.spells
  serverSpellListMeta = data
  cancelAssignSpellListTimeout()

  if assignSpellPendingWidget then
    local w = assignSpellPendingWidget
    assignSpellPendingWidget = nil
    if window and not window:isDestroyed() then
      destroyAssignWindows()
      assignSpell(w)
    end
  end
end

function init()
  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onSpellGroupCooldown = onSpellGroupCooldown,
    onSpellCooldown = onSpellCooldown
  })

  if SPELL_LIST_ENABLED then
    ProtocolGame.registerExtendedJSONOpcode(SPELL_LIST_OPCODE, onSpellListExtendedJSONOpcode)
  end

  if g_game.isOnline() then
    online()
  end

  -- taken from game_hotkeys
  mouseGrabberWidget = g_ui.createWidget('UIWidget')
  mouseGrabberWidget:setVisible(false)
  mouseGrabberWidget:setFocusable(false)
  mouseGrabberWidget.onMouseRelease = onDropActionButton
end

function terminate()
  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onSpellGroupCooldown = onSpellGroupCooldown,
    onSpellCooldown = onSpellCooldown
  })

  if SPELL_LIST_ENABLED then
    ProtocolGame.unregisterExtendedJSONOpcode(SPELL_LIST_OPCODE, onSpellListExtendedJSONOpcode)
  end
  clearServerSpellList()
end

function createActionBars()
  local bottomPanel = modules.game_interface.getBottomActionPanel()
  local leftPanel = modules.game_interface.getLeftActionPanel()
  local rightPanel = modules.game_interface.getRightActionPanel()

  -- 1-3: bottom
  -- 4-6: left
  -- 7-9: right
  for i=1,9 do
    local parent
    local index
    local layout

    if i <= 3 then
      parent = bottomPanel
      index = i
      layout = 'actionbar'
    elseif i <= 6 then
      parent = leftPanel
      index = i - 3
      layout = 'sideactionbar'
    else
      parent = rightPanel
      index = i - 6
      layout = 'sideactionbar'
    end

    actionBars[i] = g_ui.loadUI(layout, parent)
    actionBars[i]:setId("actionbar."..i)
    actionBars[i].n = i
    parent:moveChildToIndex(actionBars[i], index)
  end
end

function offline()
  -- save settings to json
  save()

  clearServerSpellList()

  -- destroy windows
  destroyAssignWindows()
  mouseGrabberWidget:destroy()

  -- remove binds
  for index, actionbar in ipairs(actionBars) do
    if actionbar.tabBar then
      for i, actionButton in ipairs(actionbar.tabBar:getChildren()) do
        local callback = actionButton.callback
        local hotkey = actionButton.hotkey and actionButton.hotkey:len() > 0 and actionButton.hotkey or false

        if callback and hotkey then
          local gameRootPanel = modules.game_interface.getRootPanel()
          g_keyboard.unbindKeyPress(hotkey, callback, gameRootPanel)
        end
      end
    end
  end

  -- destroy actionbars
  for i, panel in ipairs(actionBars) do
    panel:destroy()
  end
end

function online()
  settingsFile = modules.client_profiles.getSettingsFilePath("actionbar_v2.json")
  -- load settings
  load()

  -- create actionbars
  createActionBars()

  if SPELL_LIST_ENABLED then
    scheduleEvent(requestServerSpellList, 1200)
  end

  -- show & setup actionbars
  show()

  destroyAssignWindows()
end

function show()
  for i=1,#actionBars do
    local actionbar = actionBars[i]
    local enabled = g_settings.getBoolean("actionbar"..i, false)

    actionbar:setOn(enabled)
    setupActionBar(i)
  end
end

function refresh()
  -- first save
  save()

  -- recheck file
  settingsFile = modules.client_profiles.getSettingsFilePath("actionbar_v2.json")

  -- load settings
  load()

  -- setup actionbars
  show()

  destroyAssignWindows()
end

function translateHotkeyDesc(text)
  -- formatting similar to cip Tibia 12
  if not text then 
    return ""
  end

  local values = {
    {"Shift", "S"},
    {"Ctrl", "C"},
    {"+", ""},
    {"PageUp", "PgUp"},
    {"PageDown", "PgDown"},
    {"Enter", "Return"},
    {"Insert", "Ins"},
    {"Delete", "Del"},
    {"Escape", "Esc"}
  }

  for i, v in pairs(values) do
    text = text:gsub(v[1], v[2])
  end

  if text:len() > 6 then
    text = text:sub(text:len()-3,text:len())
    text = "..."..text
  end

  return text
end

function destroyAssignWindows()
  cancelAssignSpellListTimeout()
  assignSpellPendingWidget = nil
  assignSpellCategoryCallback = nil
  local windows = {
    'assignItemWindow',
    'assignSpellWindow',
    'assignTextWindow',
    'assignHotkeyWindow'
  }

  local rootWidget = g_ui.getRootWidget()
  for i, id in ipairs(windows) do
    local widget = rootWidget[id]

    if widget then
      widget:destroy()
    end
  end
end

function changeLockState(widget)
  local actionbar = widget:getParent():getParent()

  widget:setOn(not widget:isOn())
  widget.image:setOn(widget:isOn())
  actionbar.locked = not widget:isOn()

  settings[actionbar:getId()] = not widget:isOn() or nil
end

function moveActionButtons(widget)
  local dir = widget:getId()
  local actionBar = widget:getParent():getParent()
  local scroll = actionBar.actionScroll
  local buttons = {actionBar.prevPanel.prev, actionBar.prevPanel.first, actionBar.nextPanel.next, actionBar.nextPanel.last}

  if dir == "next" then
    scroll:increment(37)
  elseif dir == "last" then
    scroll:setValue(scroll:getMaximum())
  elseif dir == "prev" then
    scroll:decrement(37)
  else
    scroll:setValue(scroll:getMinimum())
  end

  local prevEnabled = scroll:getValue() > 0
  local nextEnabled = scroll:getValue() < scroll:getMaximum()
  
  buttons[1]:setOn(prevEnabled)
  buttons[2]:setOn(prevEnabled)
  buttons[3]:setOn(nextEnabled)
  buttons[4]:setOn(nextEnabled)
  buttons[1].image:setOn(prevEnabled)
  buttons[2].image:setOn(prevEnabled)
  buttons[3].image:setOn(nextEnabled)
  buttons[4].image:setOn(nextEnabled)
end

function onDropActionButton(self, mousePosition, mouseButton)
  if not g_ui.isMouseGrabbed() then return end

  local clickedWidget = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)
  if clickedWidget and clickedWidget:getParent() and clickedWidget:getParent():getStyleName():find('ActionButton') then
    if cachedSettings then
      clickedWidget = clickedWidget:getParent()
      if clickedWidget ~= cachedSettings.widget then
        local clickedHotkey = clickedWidget.hotkey
        local cachedHotkey = cachedSettings.widget.hotkey

        settings[cachedSettings.id] = settings[clickedWidget:getId()]
        settings[clickedWidget:getId()] = cachedSettings.data
        
        local clickedTill = clickedWidget.cooldownTill or 0
        local clickedStart = clickedWidget.cooldownStart or 0
        local cachedTill = cachedSettings.widget.cooldownTill or 0
        local cachedStart = cachedSettings.widget.cooldownStart or 0

        cachedSettings.widget.cooldownTill = clickedTill
        cachedSettings.widget.cooldownStart = clickedStart
        clickedWidget.cooldownTill = cachedTill
        clickedWidget.cooldownStart = cachedStart

        -- hotkeys remain unchanged
        settings[cachedSettings.id] = settings[cachedSettings.id] or {}
        settings[cachedSettings.id].hotkey = cachedHotkey
        settings[clickedWidget:getId()] = settings[clickedWidget:getId()] or {}
        settings[clickedWidget:getId()].hotkey = clickedHotkey

        updateCooldown(clickedWidget)
        updateCooldown(cachedSettings.widget)
        setupButton(cachedSettings.widget)
        setupButton(clickedWidget)
      end
    end
  end

  cachedSettings.widget.item:setBorderColor('#00000000')
  cachedSettings = nil
  g_mouse.popCursor('target')
  self:ungrabMouse()
end

function setupActionBar(n)
  local actionbar = actionBars[n]
  local visible = actionbar:isVisible()
  locked = settings[actionbar:getId()]
  actionbar.tabBar.onMouseWheel = nil -- disable scroll wheel

  actionbar.locked = locked
  actionbar.nextPanel.lock:setOn(not locked)
  actionbar.nextPanel.lock.image:setOn(not locked)

  if not visible then
    return actionbar.tabBar:destroyChildren() -- will hopefully lower stress
  else
    actionbar.tabBar:destroyChildren()
    for i=1,50 do
      local layout = n < 4 and 'ActionButton' or 'SideActionButton'
      local widget = g_ui.createWidget(layout, actionbar.tabBar)
      widget:setId(actionbar.n.."."..i)

      setupButton(widget)
    end
  end
end

function setupButton(widget)
  local id = widget:getId()
  local config = settings[id]
  local actionbar = widget:getParent():getParent()

  -- disable count
  widget.item:setShowCount(false)

  -- remove callback to avoid recurrency
  widget.item.onItemChange = nil

  -- clear settings
  widget.type = TYPE.BLANK
  widget.text:setText("")
  widget.parameterText:setText("")
  if widget.item:getItemId() ~= 0 then
    widget.item:setItemId(0)
  end
  widget.item:setOn(false)
  widget.autoSay = nil
  widget.action = ACTION.BLANK
  widget.spellData = nil
  widget.item:setItemVisible(true)
  widget.text:setImageSource('')
  widget.hotkey = config and config.hotkey or ""
  widget.callback = nil

  -- add new settings
  if config and config.type then
    widget.item:setOn(true)
    widget.type = config.type
    widget.text:setText(config.sayText or "")
    if widget.item:getItemId() ~= (config.itemId and config.itemId > 100 and config.itemId or 0) then
      widget.item:setItem(Item.create(config.itemId, 50))
    end
    widget.sayText = config.sayText
    widget.autoSay = config.autoSay
    widget.action = config.action
    widget.spellData = config.spellData
    if config.type ~= 0 and config.type ~= 3 then
      widget.item:setItemVisible(false)
    end
  end

  -- callback
  setupAction(widget)

  --hotkey
  widget.hotkeyLabel:setText(translateHotkeyDesc(widget.hotkey))
  
  if widget.spellData then
    --image
    widget.text:setImageSource(widget.spellData.source)
    widget.text:setImageClip(widget.spellData.clip)

    --param
    local param = widget.spellData.param
    if param and param:len() > 6 then
      param = param:sub(1,5) .. "..."
    end
    widget.parameterText:setText(param or "")
  else
    widget.text:setImageSource('')
  end

  widget.item.onDragEnter = function(self)
    if g_ui.isMouseGrabbed() or actionbar.locked then return end
    mouseGrabberWidget:grabMouse()
    g_mouse.pushCursor('target')

    self:setBorderColor('#FFFFFF')
    cachedSettings = {id=widget:getId(), data=settings[widget:getId()], widget=widget}
  end

  -- popupmenu & execute action
  widget.onMouseRelease = function(widget, mousePos, mouseButton)
    if mouseButton == MouseRightButton then 

      local menu = g_ui.createWidget('PopupMenu')
      menu:setGameMenu(true)
      menu:addOption(widget.spellId and tr('Edit Spell') or tr('Assign Spell'), function() assignSpell(widget) end)
      menu:addOption(widget.item:getItemId() > 100 and tr('Edit Object') or tr('Assign Object'), function() assignItem(widget) end)
      menu:addOption(widget.text:getText():len() > 0 and tr('Edit Text') or tr('Assign Text'), function() assignText(widget) end)
      menu:addOption(widget.hotkey and tr('Edit Hotkey') or tr('Assign Hotkey'), function() assignHotkey(widget) end)

      if widget.type > 0 then
        menu:addSeparator()
        menu:addOption(tr('Clear Action'), function() resetSlot(widget) end)
      end
      menu:display(mousePos)
    elseif mouseButton == MouseLeftButton and widget.callback then 
      widget.callback()
    end
  end

  widget.item.onItemChange = function(widget)
    widget:setOn(true)
    assignItem(widget:getParent())
  end

  -- tooltip
  local itemAction
  if widget.type == TYPE.ITEM then
    if widget.action == ACTION.EQUIP then
      itemAction = "Equip/Unequip this object"
    elseif widget.action == ACTION.USE then
      itemAction = "Use this object"
    elseif widget.action == ACTION.USE_SELF then
      itemAction = "Use this object on Yourself"
    elseif widget.action == ACTION.USE_TARGET then
      itemAction = "Use this object on Attack Target"
    elseif widget.action == ACTION.USE_CROSS then
      itemAction = "Use this object with Crosshair"
    end
  end

  local actionDesc
  local spellData = widget.spellData
  if widget.type == TYPE.BLANK then
    actionDesc = "None"
  elseif widget.type == TYPE.TEXT then
    actionDesc = 'Say: "'..widget.text:getText()..'"\n'
    actionDesc = actionDesc.. "Auto sent:  " .. (widget.autoSay and "Yes" or "No")
  elseif widget.type == TYPE.SPELL then
    local paramText 
    if spellData.param and spellData.param:len() > 0 then
      paramText = ' "'.. spellData.param ..'"' 
    else 
      paramText = ""
    end
    local castWords = spellData.words
    if not castWords or castWords:len() == 0 then
      castWords = spellData.name or ""
    end
    actionDesc = "Cast: " .. castWords .. paramText .. "\n"
    actionDesc = actionDesc.. "Cooldown:  "..spellData.cd.."s\n"
    actionDesc = actionDesc.. "Mana:  "..spellData.mana
  elseif widget.type == TYPE.ITEM then
    actionDesc = itemAction
  end

  local hotkeyDesc = widget.hotkey and widget.hotkey:len() > 0 and widget.hotkey or "None"
  local tooltip = "Action Button "..id
  tooltip = tooltip.."\n\n\tAction:  ".. actionDesc
  tooltip = tooltip.."\nHotkeys:  ".. hotkeyDesc

  widget.item:setTooltip(tooltip)
end

function resetSlot(widget)
  local hotkey = settings[widget:getId()] and settings[widget:getId()].hotkey or nil
  if hotkey and hotkey:len() > 0 and widget.callback then
    local gameRootPanel = modules.game_interface.getRootPanel()
    g_keyboard.unbindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
  end
  
  if hotkey then
    settings[widget:getId()] = {hotkey=hotkey}
  else
    settings[widget:getId()] = nil
  end

  setupButton(widget)
end

function assignItem(widget)
  destroyAssignWindows()
  local radio = UIRadioGroup.create()
  local item = widget.item:getItem()
  local id = widget.item:getItemId()

  -- check if item wasn't cleared
  if id == 0 and widget.item:isOn() then
    return resetSlot(widget) 
  end

  -- create window
  window = g_ui.loadUI('object', g_ui.getRootWidget())
  window:show()
  window:raise()
  window:focus()

  -- basics
  window:setText("Assign Object to Action Button "..widget:getId())
  window:setId("assignItemWindow")

  -- select item: ativa cursor de mira, usuário clica no item desejado
  window.select.onClick = function()
    local grabber = g_ui.createWidget('UIWidget', rootWidget)
    grabber:setVisible(false)
    grabber:setFocusable(true)

    grabber.onMouseRelease = function(self, mousePos, mouseButton)
      if not g_ui.isMouseGrabbed() then return end
      local clicked = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePos, false)
      if clicked and clicked:getClassName() == 'UIItem' and not clicked:isVirtual() then
        local clickedItem = clicked:getItem()
        if clickedItem and clickedItem:getId() > 100 then
          window.item:setItem(Item.create(clickedItem:getId(), clickedItem:getCount()))
        end
      end
      g_mouse.popCursor('target')
      self:ungrabMouse()
      grabber:ungrabKeyboard()
      grabber:destroy()
    end

    grabber.onKeyDown = function(self, keyCode, mods)
      if keyCode == KeyEscape then
        g_mouse.popCursor('target')
        self:ungrabMouse()
        self:ungrabKeyboard()
        grabber:destroy()
        return true
      end
      return false
    end

    grabber:grabMouse()
    grabber:grabKeyboard()
    g_mouse.pushCursor('target')
  end

  -- checks
  window.item:setShowCount(false)
  window.item.onItemChange = function(widget)
    local item = window.item:getItem()

    if item then
      local isMulti = item:isMultiUse()
      local isValid = item:getId() >= 100

      for i, child in ipairs(window.checks:getChildren()) do
        -- adiciona ao radio group
        radio:addWidget(child)

        if not isValid then
          -- item inválido: desabilita tudo
          child:setEnabled(false)
          child:setVisible(true)
        elseif i == 4 then
          -- Equip/Unequip: suportado no servidor 8.60 via handler customizado (opcode 0x77)
          child:setVisible(true)
          child:setEnabled(true)
        else
          -- Use on yourself (1), Use on target (2), With crosshair (3), Use (5)
          child:setEnabled(true)
          child:setVisible(true)
        end
      end

      -- auto-seleção: multiUse → useSelf; outros → use
      local children = window.checks:getChildren()
      if isMulti then
        -- seleciona "Use on yourself" (i=1)
        local useSelfWidget = children[1]
        if useSelfWidget and useSelfWidget:isEnabled() then
          radio:selectWidget(useSelfWidget)
        end
      else
        -- seleciona "Use" (i=5)
        local useWidget = children[5]
        if useWidget and useWidget:isEnabled() then
          radio:selectWidget(useWidget)
        end
      end
    end

    -- validation
    window.buttonOk:setEnabled(item and item:getId() >= 100)
    window.buttonApply:setEnabled(item and item:getId() >= 100)
  end

  window.item:setItemId(id)

  -- select current action, if exists
  local actionType = widget.action or 0
  if actionType > ACTION.BLANK then
    local id
    if actionType == ACTION.USE_SELF then
      id = "useSelf"
    elseif actionType == ACTION.USE_TARGET then
      id = "useTarget"
    elseif actionType == ACTION.USE_CROSS then
      id = "useCross"
    elseif actionType == ACTION.EQUIP then
      id = "equip"
    elseif actionType == ACTION.USE then
      id = "use"
    end

    for i, child in ipairs(radio.widgets) do
      local childId = child:getId()
      if childId == id then
        radio:selectWidget(child)
        break
      end
    end
  end

  -- functions
  local okFunc = function(destroy)
    local hotkey = settings[widget:getId()] and settings[widget:getId()].hotkey
    if hotkey and hotkey:len() > 0 and widget.callback then
      local gameRootPanel = modules.game_interface.getRootPanel()
      g_keyboard.unbindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
    end

    settings[widget:getId()] = {hotkey=hotkey}
    settings[widget:getId()].itemId = window.item:getItemId()
    settings[widget:getId()].type = TYPE.ITEM

    local selected = radio:getSelectedWidget():getId()
    if selected == "useSelf" then
      settings[widget:getId()].action = ACTION.USE_SELF
    elseif selected == "useTarget" then
      settings[widget:getId()].action = ACTION.USE_TARGET
    elseif selected == "useCross" then
      settings[widget:getId()].action = ACTION.USE_CROSS
    elseif selected == "equip" then
      settings[widget:getId()].action = ACTION.EQUIP
    else
      settings[widget:getId()].action = ACTION.USE
    end

    if destroy then
      window:destroy()
      radio:destroy()
    end
    setupButton(widget)
  end

  local cancelFunc = function()
    setupButton(widget)
    window:destroy()
    radio:destroy()
  end

  -- callbacks
  window.buttonOk.onClick = function() okFunc(true) end
  window.onEnter = function() okFunc(true) end
  window.buttonApply.onClick = function() okFunc(false) end
  window.buttonClose.onClick = cancelFunc
  window.onEscape = cancelFunc

  local actionbar = widget:getParent():getParent()
  if actionbar.locked then
    cancelFunc()
  end
end

function assignText(widget)
  destroyAssignWindows()

  -- create window
  window = g_ui.loadUI('text', g_ui.getRootWidget())
  window:show()
  window:raise()
  window:focus()

  window.text.onTextChange = function(self, text)
    window.buttonOk:setEnabled(text:len() > 0)
    window.buttonApply:setEnabled(text:len() > 0)
  end

  -- copy settings from current widget
  window.text:setText(widget.text:getText())
  if widget.type > 0 then
    window.checkPanel.tick:setChecked(widget.autoSay)
  end

  -- functions
  local okFunc = function(destroy) 
    local autoSay = window.checkPanel.tick:isChecked()
    local text = window.text:getText()

    local hotkey = settings[widget:getId()] and settings[widget:getId()].hotkey
    if hotkey and hotkey:len() > 0 and widget.callback then
      local gameRootPanel = modules.game_interface.getRootPanel()
      g_keyboard.unbindKeyPress(hotkey, widget.callback, gameRootPanel)
    end

    settings[widget:getId()] = {hotkey=hotkey}

    local spell = isSpell(text)
    if spell then -- entered text is spell
      local paramText = spell.param
      local spellData = spell.data
      local newGroup = {}
      for groupId, duration in pairs(spellData.group) do
        table.insert(newGroup, groupId)
      end
      spellData.group = newGroup

  
      settings[widget:getId()].type = TYPE.SPELL
      settings[widget:getId()].spellData = {
        words = spellData.words,
        cd = spellData.exhaustion/1000,
        mana = spellData.mana,
        source = SpelllistSettings['Default'].iconFile,
        clip = Spells.getImageClip(SpellIcons[spellData.icon][1], 'Default'),
        name = spellData.spellName,
        param = paramText,
        group = spellData.group,
        id = spellData.id
      }
    else -- is just text
      settings[widget:getId()].sayText = text
      settings[widget:getId()].type = TYPE.TEXT
      settings[widget:getId()].autoSay = autoSay
    end
  
    if destroy then
      window:destroy()
    end
    setupButton(widget)
  end
  local cancelFunc = function()
    window:destroy()
    setupButton(widget)
  end

  -- buttons
  window.buttonOk.onClick = function() okFunc(true) end
  window.buttonApply.onClick = function() okFunc(false) end
  window.buttonClose.onClick = cancelFunc
  window.onEscape = cancelFunc
  window.onEnter = function() okFunc(true) end

  local actionbar = widget:getParent():getParent()
  if actionbar.locked then
    cancelFunc()
  end
end

function onAssignSpellCategoryClick(category)
  if assignSpellCategoryCallback then
    assignSpellCategoryCallback(category)
  end
end

function assignSpell(widget)
  destroyAssignWindows()
  local radio = UIRadioGroup.create()

  -- create window
  window = g_ui.loadUI('spell', g_ui.getRootWidget())
  window:show()
  window:raise()
  window:focus()

  window:setText("Assign Spell to Action Button "..widget:getId())

  local player = g_game.getLocalPlayer()
  window.checkPanel.tick:setChecked(player:getVocation() ~= 0)
  window.checkPanel.tickLevel:setChecked(true)

  local currentCategory = g_settings.getString(ASSIGN_SPELL_CATEGORY_SETTING, "attack")
  if not table.find(SPELL_CATEGORIES, currentCategory) then
    currentCategory = "attack"
  end

  local filterSpells

  local function updateCategoryTabs()
    for category, buttonId in pairs(SPELL_CATEGORY_BUTTON_IDS) do
      local button = window.categoryPanel:getChildById(buttonId)
      if button then
        button:setOn(category == currentCategory)
      end
    end
  end

  local function setCategory(category, saveSettings)
    if not table.find(SPELL_CATEGORIES, category) then
      category = "attack"
    end
    currentCategory = category
    updateCategoryTabs()
    if saveSettings ~= false then
      g_settings.set(ASSIGN_SPELL_CATEGORY_SETTING, category)
    end
    if filterSpells then
      filterSpells()
    end
  end

  assignSpellCategoryCallback = function(category)
    setCategory(category)
  end

  updateCategoryTabs()

  local function addSpellPreview(spellName, serverEntry, localData)
    local preview = g_ui.createWidget('SpellPreview', window.spellList)
    radio:addWidget(preview)

    local spellData = buildSpellPreviewData(spellName, serverEntry, localData)
    local displayName = spellName or spellData.name
    local displayLabel = spellData.words
    if not displayLabel or displayLabel:len() == 0 then
      displayLabel = displayName
    end

    preview:setId(spellData.id > 0 and tostring(spellData.id) or displayName)
    preview:setText(displayLabel)
    preview.voc = spellData.vocations
    preview.param = spellData.param
    preview.source = spellData.source
    preview.clip = spellData.clip
    preview.image:setImageSource(spellData.source)
    preview.image:setImageClip(spellData.clip)
    preview.spellData = spellData
    preview.category = (serverEntry and serverEntry.category)
      or resolveClientCategory(serverEntry and serverEntry.words or spellData.words, localData)
  end

  local usingServerList = serverSpellList and #serverSpellList > 0
  window.usingServerList = usingServerList

  if usingServerList then
    cancelAssignSpellListTimeout()
    for _, entry in ipairs(serverSpellList) do
      local name, localData = lookupLocalSpellInfo(entry.name, entry.words)
      addSpellPreview(name or entry.name, entry, localData)
    end
  elseif not SPELL_LIST_ENABLED then
    cancelAssignSpellListTimeout()
    window.usingServerList = false
    for spellName, localData in pairs(SpellInfo['Default']) do
      addSpellPreview(spellName, nil, localData)
    end
  else
    assignSpellPendingWidget = widget
    requestServerSpellList()
    window.preview:setText(tr("Carregando magias do servidor..."))
    window.preview.image:setImageSource("")
    cancelAssignSpellListTimeout()
    assignSpellListTimeoutEvent = scheduleEvent(function()
      assignSpellListTimeoutEvent = nil
      if assignSpellPendingWidget ~= widget then
        return
      end
      assignSpellPendingWidget = nil
      displayInfoBox(tr("Assign Spell"),
        tr("Nao foi possivel carregar magias do servidor.\nVerifique ExtendedOpcodeSpellList no login e reinicie o TFS."))
      destroyAssignWindows()
    end, SPELL_LIST_TIMEOUT_MS)
  end

  local widgets = window.spellList:getChildren()
  table.sort(widgets, function(a, b)
    local aw = a.spellData.words or a.spellData.name or ""
    local bw = b.spellData.words or b.spellData.name or ""
    return aw < bw
  end)
  for i, child in ipairs(widgets) do
    window.spellList:moveChildToIndex(child, i)
  end

  local function filterSpells()
    -- disable callback
    window.spellList.onChildFocusChange = nil

    local widgets = window.spellList:getChildren()
    local player = g_game.getLocalPlayer()
    local vocation = translateVocation(player:getVocation())
    local playerLevel = player:getLevel()

    local filterVocation = window.checkPanel.tick:isChecked()
    local filterLevel = window.checkPanel.tickLevel:isChecked()

    -- visible
    local firstVisible = nil
    local skipVocationFilter = window.usingServerList

    for i, child in ipairs(widgets) do
      local vocViable = skipVocationFilter or not filterVocation
        or (vocation ~= nil and table.find(child.voc, vocation) ~= nil)
      local spellLevel = child.spellData.level or 0
      local lvlViable = not filterLevel or (playerLevel >= spellLevel)
      local categoryOk = child.category == currentCategory
      local viable = vocViable and lvlViable and categoryOk

      child:setVisible(viable)
      if viable and not firstVisible then
        firstVisible = child
        radio:selectWidget(firstVisible)
      end
    end

    local currentSpell = widget.spellData and widget.spellData.id or 0
    local currentName = widget.spellData and widget.spellData.name
    local currentWords = widget.spellData and widget.spellData.words

    for i, child in ipairs(radio.widgets) do
      local sd = child.spellData
      if sd then
        local matched = (currentSpell > 0 and sd.id == currentSpell)
          or (currentWords and sd.words == currentWords)
          or (currentName and sd.name == currentName)
        if matched then
          if child.category == currentCategory then
            child:setVisible(true)
            window.spellList:ensureChildVisible(child)
            radio:selectWidget(child)
          end
          break
        end
      end
    end
  end

  -- callback
  radio.onSelectionChange = function(widget, selected)
    if selected then
      local name = selected:getText()
      local source = selected.source
      local clip = selected.clip
      local param = selected.param

      -- preview
      window.preview:setText(name)
      window.preview.image:setImageSource(source)
      window.preview.image:setImageClip(clip)

      -- param
      window.paramLabel:setOn(param)
      window.paramText:setEnabled(param)
      window.spellList:ensureChildVisible(widget)
    end
  end

  window.checkPanel.tick.onCheckChange = filterSpells
  window.checkPanel.tickLevel.onCheckChange = filterSpells

  local assignedCategory = nil
  if widget.spellData then
    local sd = widget.spellData
    for _, child in ipairs(window.spellList:getChildren()) do
      local csd = child.spellData
      if csd then
        local matched = (sd.id and sd.id > 0 and csd.id == sd.id)
          or (sd.words and csd.words == sd.words)
          or (sd.name and csd.name == sd.name)
        if matched then
          assignedCategory = child.category
          break
        end
      end
    end
  end

  if assignedCategory then
    setCategory(assignedCategory, false)
  else
    filterSpells()
  end

  local okFunc = function(destroy) 
    local selected = radio:getSelectedWidget()
    local paramWidgetText = window.paramText:getText()
    if not selected then return end

    selected.spellData.param = paramWidgetText

    local hotkey = settings[widget:getId()] and settings[widget:getId()].hotkey   
    if hotkey and hotkey:len() > 0 and widget.callback then
      local gameRootPanel = modules.game_interface.getRootPanel()
      g_keyboard.unbindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
    end

    settings[widget:getId()] = {hotkey=hotkey}
    settings[widget:getId()].spellData = selected.spellData
    settings[widget:getId()].type = TYPE.SPELL
 
    if destroy then
      assignSpellCategoryCallback = nil
      window:destroy()
    end
    setupButton(widget)
  end
  local cancelFunc = function()
    cancelAssignSpellListTimeout()
    assignSpellCategoryCallback = nil
    if assignSpellPendingWidget == widget then
      assignSpellPendingWidget = nil
    end
    window:destroy()
    setupButton(widget)
  end

  window.buttonOk.onClick = function() okFunc(true) end
  window.buttonApply.onClick = function() okFunc(false) end
  window.buttonClose.onClick = cancelFunc
  window.onEscape = cancelFunc
  window.onEnter = function() okFunc(true) end

  local actionbar = widget:getParent():getParent()
  if actionbar.locked then
    cancelFunc()
  end
end

function assignHotkey(widget)
  destroyAssignWindows()

  -- create window
  window = g_ui.loadUI('hotkey', g_ui.getRootWidget())
  window:show()
  window:raise()
  window:focus()

  local barN = widget:getParent():getParent().n
  local barDesc
  if barN < 4 then
    barDesc = "Bottom"
  elseif barN < 7 then
    barDesc = "Left"
  else
    barDesc = "Right"
  end

  -- things
  barDesc = barDesc.." Action Bar: Action Button "..widget:getId()
  window:setText('Edit Hotkey for "'..barDesc)
  window.desc:setText(window.desc:getText()..barDesc..'"')
  window.display:setText(widget.hotkey or "")
  
  -- hotkey
  window:grabKeyboard()
  window.onKeyDown = function(window, keyCode, keyboardModifiers)
    local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
    window.display:setText(keyCombo)
    return true
  end

  local okFunc = function() 
    local hotkey = window.display:getText()

    if settings[widget:getId()].hotkey and settings[widget:getId()].hotkey:len() > 0 and widget.callback then
      local gameRootPanel = modules.game_interface.getRootPanel()
      g_keyboard.unbindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
    end
    settings[widget:getId()] = settings[widget:getId()] or {}
    settings[widget:getId()].hotkey = hotkey
  
    window:destroy()
    setupButton(widget)
  end
  local clearFunc = function() 
    window.display:setText('')
    local hotkey = window.display:getText()

    if settings[widget:getId()].hotkey and settings[widget:getId()].hotkey:len() > 0 and widget.callback then
      local gameRootPanel = modules.game_interface.getRootPanel()
      g_keyboard.unbindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
    end
    settings[widget:getId()] = settings[widget:getId()] or {}
    settings[widget:getId()].hotkey = hotkey
  
    window:destroy()
    setupButton(widget)
  end
  local closeFunc = function() 
    window:destroy()
    setupButton(widget)
  end

  window.buttonOk.onClick = okFunc
  window.buttonClear.onClick = clearFunc
  window.buttonClose.onClick = closeFunc

  local actionbar = widget:getParent():getParent()
  if actionbar.locked then
    cancelFunc()
  end
end

function setupAction(widget)
  if widget.type == TYPE.BLANK then 
    return
  end
  if widget.type == TYPE.TEXT then
    widget.callback = function()
      if modules.game_interface.isChatVisible() then
        if widget.autoSay then
          modules.game_console.sendMessage(widget.sayText)
        else
          modules.game_console.setTextEditText(widget.sayText)
        end
      elseif widget.autoSay then
        g_game.talk(widget.sayText)
      end
    end
  elseif widget.type == TYPE.SPELL then
    widget.callback = function()
      if g_app.isMobile() then -- turn to direction of targer
        local target = g_game.getAttackingCreature()
        if target then
          local pos = g_game.getLocalPlayer():getPosition()
          local tpos = target:getPosition()
          if pos and tpos then
            local offx = tpos.x - pos.x
            local offy = tpos.y - pos.y
            if offy < 0 and offx <= 0 and math.abs(offx) < math.abs(offy) then
              g_game.turn(Directions.North)
            elseif offy > 0 and offx >= 0 and math.abs(offx) < math.abs(offy) then
              g_game.turn(Directions.South)
            elseif offx < 0 and offy <= 0 and math.abs(offx) > math.abs(offy) then
              g_game.turn(Directions.West)
            elseif offx > 0 and offy >= 0 and math.abs(offx) > math.abs(offy) then
              g_game.turn(Directions.East)
            end
          end
        end
      end
      local paramText 
      if widget.spellData.param and widget.spellData.param:len() > 0 then
        paramText = ' "'.. widget.spellData.param ..'"' 
      else 
        paramText = ""
      end
      g_game.talk(widget.spellData.words..paramText)
    end
  elseif widget.type == TYPE.ITEM then
    widget.callback = function()
      if widget.action == ACTION.BLANK then
        return
      elseif widget.action == ACTION.EQUIP then
        -- 910+ nativo; 860 usa opcode 0x77 no TFS deste repo (playerEquipItem)
        if g_game.getClientVersion() >= 860 then
          g_game.equipItemId(widget.item:getItemId(), widget.item:getItemSubType() or 0)
          return
        end
      elseif widget.action == ACTION.USE then
        if g_game.getClientVersion() < 780 then
          local item = g_game.findPlayerItem(widget.item:getItemId(), widget.item:getItemSubType() or -1)
          if item then
            g_game.use(item)
          end
        else
          g_game.useInventoryItem(widget.item:getItemId())
        end
      elseif widget.action == ACTION.USE_SELF then
        if g_game.getClientVersion() < 780 then
          local item = g_game.findPlayerItem(widget.item:getItemId(), widget.item:getItemSubType() or -1)
          if item then
            g_game.useWith(item, g_game.getLocalPlayer())
          end
        else
          g_game.useInventoryItemWith(widget.item:getItemId(), g_game.getLocalPlayer(), widget.item:getItemSubType() or -1)
        end
      elseif widget.action == ACTION.USE_TARGET then
        local attackingCreature = g_game.getAttackingCreature()
        if not attackingCreature then
          local item = Item.create(widget.item:getItemId())
          if g_game.getClientVersion() < 780 then
            local tmpItem = g_game.findPlayerItem(widget.item:getItemId(), widget.item:getItemSubType() or -1)
            if not tmpItem then return end
            item = tmpItem
          end
          modules.game_interface.startUseWith(item, widget.item:getItemSubType() or - 1)
          return
        end
        if not attackingCreature:getTile() then return end
        if g_game.getClientVersion() < 780 then
          local item = g_game.findPlayerItem(widget.item:getItemId(), widget.item:getItemSubType() or -1)
          if item then
            g_game.useWith(item, attackingCreature, widget.item:getItemSubType() or -1)
          end
        else
          g_game.useInventoryItemWith(widget.item:getItemId(), attackingCreature, widget.item:getItemSubType() or -1)
        end
      elseif widget.action == ACTION.USE_CROSS then
        local item = Item.create(widget.item:getItemId())
        if g_game.getClientVersion() < 780 then
          local tmpItem = g_game.findPlayerItem(widget.item:getItemId(), widget.item:getItemSubType() or -1)
          if not tmpItem then return true end
          item = tmpItem
        end
        modules.game_interface.startUseWith(item, widget.item:getItemSubType() or - 1)
      end
    end
  end

  if widget.hotkey and widget.hotkey:len() > 0 and widget.callback then
    local gameRootPanel = modules.game_interface.getRootPanel()
    g_keyboard.bindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
  end
end

function onSpellCooldown(iconId, duration)
  for index, actionbar in ipairs(actionBars) do
    for i, child in ipairs(actionbar.tabBar:getChildren()) do
      if child.type == 2 and child.spellData.id == iconId then
        startCooldown(child, duration)
      end
    end
  end
end

function onSpellGroupCooldown(groupId, duration)
  for index, actionbar in ipairs(actionBars) do
    for i, child in ipairs(actionbar.tabBar:getChildren()) do
      if child.type == 2 and child.spellData.group then
        for i, group in ipairs(child.spellData.group) do
          if groupId == group then
            startCooldown(child, duration)
          end
        end
      end
    end
  end
end

function startCooldown(action, duration)
  if type(action.cooldownTill) == 'number' and action.cooldownTill > g_clock.millis() + duration then
    return -- already has cooldown with greater duration
  end
  action.cooldownStart = g_clock.millis()
  action.cooldownTill = g_clock.millis() + duration
  updateCooldown(action)
end

function updateCooldown(action)
  if not action or not action.cooldownTill then return end
  local timeleft = action.cooldownTill - g_clock.millis()
  if timeleft <= 50 then
    action.cooldown:setPercent(100)
    action.cooldownEvent = nil
    action.cooldown:setText("")
    return
  end
  local duration = action.cooldownTill - action.cooldownStart
  local formattedText
  if timeleft > 60000 then
    formattedText = math.floor(timeleft / 60000) .. "m"
  else
    formattedText = timeleft/1000
    formattedText = math.floor(formattedText * 10) / 10
    formattedText = math.floor(formattedText) .. "." .. math.floor(formattedText * 10) % 10
  end

  local retry
  if timeleft > 60000 then
    retry = math.min(math.floor(timeleft * 0.1), 60 * 1000) -- max 1min
    retry = math.max(retry, 100) -- min 100
  elseif timeleft > 1000 then
    retry = 100
  else
    retry = 30
  end
  action.cooldown:setText(formattedText) 
  action.cooldown:setPercent(100 - math.floor(100 * timeleft / duration))
  action.cooldownEvent = scheduleEvent(function() updateCooldown(action) end, retry)
end

function save()
  local status, result = pcall(function() return json.encode(settings, 2) end)
  if not status then
      return g_logger.error(
                 "Error while saving top bar settings. Data won't be saved. Details: " ..
                     result)
  end

  if result:len() > 100 * 1024 * 1024 then
      return g_logger.error(
                 "Something went wrong, file is above 100MB, won't be saved")
  end

  g_resources.writeFileContents(settingsFile, result)
end

function load()
  if g_resources.fileExists(settingsFile) then
      local status, result = pcall(function()
          return json.decode(g_resources.readFileContents(settingsFile))
      end)
      if not status then
          return g_logger.error(
                     "Error while reading top bar settings file. To fix this problem you can delete storage.json. Details: " ..
                         result)
      end
      settings = result
  else
      settings = {}
  end
end