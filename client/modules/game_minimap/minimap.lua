minimapWidget = nil
minimapButton = nil
minimapWindow = nil
minimapExpandButton = nil
fullmapOverlay = nil
fullmapHolder = nil
fullmapCloseButton = nil
fullmapView = false
loaded = false
oldZoom = nil
oldPos = nil
fullmapEscapeHandler = nil
partyDots = {}
partyRemoteMembers = {}
partyDotRefreshEvent = nil
partyDotRequestEvent = nil
partyDotBlinkEvent = nil
partyDotBlinkVisible = true
creaturePartyHooked = false
lastPartyMinimapRequestAt = 0

local FULLMAP_SIZE_RATIO = 0.62
local PARTY_DOT_REFRESH_MS = 150
local PARTY_DOT_REQUEST_MS = 250
local PARTY_DOT_BLINK_MS = 450

local function isValidMapCoordinate(value)
  return type(value) == 'number'
end

local function isValidPartyMemberEntry(member)
  return type(member) == 'table'
      and type(member.name) == 'string'
      and isValidMapCoordinate(member.x)
      and isValidMapCoordinate(member.y)
      and isValidMapCoordinate(member.z)
end

function init()
  g_ui.importStyle('minimap_overlay')

  minimapWindow = g_ui.loadUI('minimap', modules.game_interface.getRightPanel())
  minimapWindow:setContentMinimumHeight(64)

  if not minimapWindow.forceOpen then
    minimapButton = modules.client_topmenu.addRightGameToggleButton('minimapButton',
      tr('Minimap') .. ' (Ctrl+M)', '/images/topbuttons/minimap', toggle)
    minimapButton:setOn(true)
  end

  minimapWidget = minimapWindow:recursiveGetChildById('minimap')
  minimapExpandButton = minimapWidget:getChildById('expandWidget')
  if minimapExpandButton then
    minimapExpandButton.onClick = toggleFullMap
  end

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyPress('Alt+Left', function() minimapWidget:move(1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Right', function() minimapWidget:move(-1,0) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Up', function() minimapWidget:move(0,1) end, gameRootPanel)
  g_keyboard.bindKeyPress('Alt+Down', function() minimapWidget:move(0,-1) end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+M', toggle)
  g_keyboard.bindKeyDown('Ctrl+Shift+M', toggleFullMap)

  minimapWindow:setup()

  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  connect(LocalPlayer, {
    onPositionChange = onLocalPlayerPositionChange,
    onShieldChange = onLocalPlayerShieldChange,
  })

  if g_game.isOnline() then
    online()
  end
end

function terminate()
  if fullmapView then
    closeFullMap()
  end
  destroyFullMapOverlay()
  stopPartyDotRefresh()
  stopPartyDotRequests()
  clearPartyDots()
  unhookCreaturePartyEvents()

  if g_game.isOnline() then
    saveMap()
  end

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  disconnect(LocalPlayer, {
    onPositionChange = onLocalPlayerPositionChange,
    onShieldChange = onLocalPlayerShieldChange,
  })

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.unbindKeyPress('Alt+Left', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Right', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Up', gameRootPanel)
  g_keyboard.unbindKeyPress('Alt+Down', gameRootPanel)
  g_keyboard.unbindKeyDown('Ctrl+M')
  g_keyboard.unbindKeyDown('Ctrl+Shift+M')
  unbindFullMapEscape()

  minimapWindow:destroy()
  if minimapButton then
    minimapButton:destroy()
  end
end

function toggle()
  if not minimapButton then return end
  if minimapButton:isOn() then
    minimapWindow:close()
    minimapButton:setOn(false)
  else
    minimapWindow:open()
    minimapButton:setOn(true)
  end
end

function onMiniWindowClose()
  if minimapButton then
    minimapButton:setOn(false)
  end
end

function online()
  loadMap()
  hookCreaturePartyEvents()
  updateCameraPosition()
  startPartyDotRefresh()
end

function offline()
  if fullmapView then
    closeFullMap()
  end
  stopPartyDotRefresh()
  stopPartyDotRequests()
  clearPartyDots()
  partyRemoteMembers = {}
  saveMap()
end

function onLocalPlayerPositionChange()
  updateCameraPosition()
  local now = g_clock.millis()
  if now - lastPartyMinimapRequestAt >= 200 then
    lastPartyMinimapRequestAt = now
    requestPartyMinimapPositions()
  end
end

function onLocalPlayerShieldChange()
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer and not localPlayer:isPartyMember() then
    partyRemoteMembers = {}
    clearPartyDots()
  else
    requestPartyMinimapPositions()
    refreshPartyDots()
  end
end

-- Chamado por modules.game_party ao receber opcode 204
function onPartyStatusUpdate(data)
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return
  end

  if type(data) ~= 'table' or not data.inParty then
    partyRemoteMembers = {}
    refreshPartyDots()
    return
  end

  local localName = localPlayer:getName()
  local now = g_clock.millis()
  local members = data.members
  if type(members) ~= 'table' then
    return
  end

  local receivedNames = {}
  for _, member in ipairs(members) do
    if isValidPartyMemberEntry(member) and member.name ~= localName then
      receivedNames[member.name] = true
      partyRemoteMembers[member.name] = {
        name = member.name,
        id = member.id,
        x = member.x,
        y = member.y,
        z = member.z,
        updatedAt = now,
      }
    end
  end

  for name, _ in pairs(partyRemoteMembers) do
    if not receivedNames[name] then
      partyRemoteMembers[name] = nil
    end
  end
  refreshPartyDots()
end

function requestPartyMinimapPositions()
  if modules.game_party and modules.game_party.requestPartyStatus then
    lastPartyMinimapRequestAt = g_clock.millis()
    modules.game_party.requestPartyStatus()
  end
end

function clearPartyDots()
  for _, dot in pairs(partyDots) do
    dot:destroy()
  end
  partyDots = {}
end

function collectVisiblePartyMembers()
  local visible = {}
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return visible
  end

  local playerPos = localPlayer:getPosition()
  if not playerPos then
    return visible
  end

  local now = g_clock.millis()
  for _, creature in ipairs(g_map.getSpectators(playerPos, false)) do
    if creature:isPlayer() and not creature:isLocalPlayer() and creature:isPartyMember() then
      local livePos = creature:getPosition()
      local name = creature:getName()
      if livePos and name then
        visible[name] = {
          name = name,
          x = livePos.x,
          y = livePos.y,
          z = livePos.z,
          updatedAt = now,
        }
      end
    end
  end
  return visible
end

function resolvePartyMemberPosition(name, member)
  if not isValidPartyMemberEntry(member) then
    return nil
  end

  local pos = {
    x = member.x,
    y = member.y,
    z = member.z,
  }

  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return pos
  end

  local playerPos = localPlayer:getPosition()
  if not playerPos then
    return pos
  end

  for _, creature in ipairs(g_map.getSpectators(playerPos, false)) do
    if creature:isPlayer() and creature:getName() == name and creature:isPartyMember() then
      local livePos = creature:getPosition()
      if livePos then
        return livePos
      end
    end
  end

  return pos
end

function getOrCreatePartyDot(memberKey)
  local dot = partyDots[memberKey]
  if dot then
    return dot
  end
  if not minimapWidget then
    return nil
  end
  dot = g_ui.createWidget('MinimapPartyDot', minimapWidget)
  dot:setTooltip('')
  partyDots[memberKey] = dot
  return dot
end

function removePartyDot(memberKey)
  local dot = partyDots[memberKey]
  if dot then
    dot:destroy()
    partyDots[memberKey] = nil
  end
end

function onCreaturePartyPositionChange(creature)
  if not creature or not creature:isPlayer() or creature:isLocalPlayer() then
    return
  end
  if creature:isPartyMember() then
    requestPartyMinimapPositions()
    refreshPartyDots()
  end
end

function onCreaturePartyShieldChange(creature)
  if not creature or not creature:isPlayer() then
    return
  end

  if creature:isPartyMember() then
    requestPartyMinimapPositions()
  else
    local name = creature:getName()
    if name then
      partyRemoteMembers[name] = nil
      removePartyDot(name)
    end
  end
  refreshPartyDots()
end

function hookCreaturePartyEvents()
  if creaturePartyHooked then
    return
  end
  connect(Creature, {
    onPositionChange = onCreaturePartyPositionChange,
    onShieldChange = onCreaturePartyShieldChange,
  })
  creaturePartyHooked = true
end

function unhookCreaturePartyEvents()
  if not creaturePartyHooked then
    return
  end
  disconnect(Creature, {
    onPositionChange = onCreaturePartyPositionChange,
    onShieldChange = onCreaturePartyShieldChange,
  })
  creaturePartyHooked = false
end

function startPartyDotRefresh()
  stopPartyDotRefresh()
  stopPartyDotRequests()
  partyDotBlinkVisible = true
  partyDotRefreshEvent = cycleEvent(refreshPartyDots, PARTY_DOT_REFRESH_MS)
  requestPartyMinimapPositions()
  partyDotRequestEvent = cycleEvent(requestPartyMinimapPositions, PARTY_DOT_REQUEST_MS)
  partyDotBlinkEvent = cycleEvent(togglePartyDotBlink, PARTY_DOT_BLINK_MS)
end

function stopPartyDotRefresh()
  if partyDotRefreshEvent then
    removeEvent(partyDotRefreshEvent)
    partyDotRefreshEvent = nil
  end
  if partyDotBlinkEvent then
    removeEvent(partyDotBlinkEvent)
    partyDotBlinkEvent = nil
  end
end

function togglePartyDotBlink()
  partyDotBlinkVisible = not partyDotBlinkVisible
  for _, dot in pairs(partyDots) do
    if dot.partyOtherFloor then
      if partyDotBlinkVisible then
        dot:show()
      else
        dot:hide()
      end
    end
  end
end

function stopPartyDotRequests()
  if partyDotRequestEvent then
    removeEvent(partyDotRequestEvent)
    partyDotRequestEvent = nil
  end
end

function refreshPartyDots()
  if not minimapWidget or not g_game.isOnline() then
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer or not localPlayer:isPartyMember() then
    clearPartyDots()
    partyRemoteMembers = {}
    return
  end

  local cameraPos = minimapWidget:getCameraPosition()
  local cameraZ = cameraPos.z
  local seenDots = {}
  local membersToDraw = {}

  for name, member in pairs(partyRemoteMembers) do
    membersToDraw[name] = member
  end
  for name, member in pairs(collectVisiblePartyMembers()) do
    local cached = partyRemoteMembers[name]
    if not cached or member.updatedAt >= cached.updatedAt then
      membersToDraw[name] = member
    end
  end

  for name, member in pairs(membersToDraw) do
    local pos = resolvePartyMemberPosition(name, member)
    if pos then
      seenDots[name] = true
      local dot = getOrCreatePartyDot(name)
      if dot then
        local otherFloor = pos.z ~= cameraZ
        dot.partyOtherFloor = otherFloor
        local anchorPos = { x = pos.x, y = pos.y, z = cameraZ }
        minimapWidget:centerInPosition(dot, anchorPos)

        if otherFloor then
          dot:setTooltip(string.format('%s\n(%s %d)', name, tr('Floor'), pos.z))
          if partyDotBlinkVisible then
            dot:show()
          else
            dot:hide()
          end
        else
          dot:setTooltip(name)
          dot:show()
        end
      end
    end
  end

  for memberKey, _ in pairs(partyDots) do
    if not seenDots[memberKey] then
      removePartyDot(memberKey)
    end
  end
end

function loadMap()
  local clientVersion = g_game.getClientVersion()

  g_minimap.clean()
  loaded = false

  local minimapFile = '/minimap.otmm'
  local dataMinimapFile = '/data' .. minimapFile
  local versionedMinimapFile = '/minimap' .. clientVersion .. '.otmm'
  if g_resources.fileExists(dataMinimapFile) then
    loaded = g_minimap.loadOtmm(dataMinimapFile)
  end
  if not loaded and g_resources.fileExists(versionedMinimapFile) then
    loaded = g_minimap.loadOtmm(versionedMinimapFile)
  end
  if not loaded and g_resources.fileExists(minimapFile) then
    loaded = g_minimap.loadOtmm(minimapFile)
  end
  if not loaded then
    print("Minimap couldn't be loaded, file missing?")
  end
  minimapWidget:load()
end

function saveMap()
  local clientVersion = g_game.getClientVersion()
  local minimapFile = '/minimap' .. clientVersion .. '.otmm'
  g_minimap.saveOtmm(minimapFile)
  minimapWidget:save()
end

function updateCameraPosition()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local pos = player:getPosition()
  if not pos then return end
  if not minimapWidget:isDragging() then
    if not fullmapView then
      minimapWidget:setCameraPosition(player:getPosition())
    end
    minimapWidget:setCrossPosition(player:getPosition())
    refreshPartyDots()
  end
end

function destroyFullMapOverlay()
  if fullmapOverlay then
    fullmapOverlay:destroy()
    fullmapOverlay = nil
    fullmapHolder = nil
    fullmapCloseButton = nil
  end
end

function ensureFullMapOverlay()
  if fullmapOverlay then
    return
  end

  local rootPanel = modules.game_interface.getRootPanel()
  fullmapOverlay = g_ui.createWidget('MinimapFullMapOverlay', rootPanel)
  fullmapHolder = fullmapOverlay:recursiveGetChildById('minimapHolder')
  fullmapCloseButton = fullmapOverlay:recursiveGetChildById('closeButton')

  local backdrop = fullmapOverlay:getChildById('backdrop')
  if backdrop then
    backdrop.onMousePress = onFullMapBackdropPress
  end

  if fullmapCloseButton then
    fullmapCloseButton.onClick = closeFullMap
  end
end

function onFullMapBackdropPress(widget, mousePos, mouseButton)
  if mouseButton == MouseLeftButton then
    closeFullMap()
  end
  return true
end

function bindFullMapEscape()
  if fullmapEscapeHandler then
    return
  end
  local gameRootPanel = modules.game_interface.getRootPanel()
  fullmapEscapeHandler = function()
    if fullmapView then
      closeFullMap()
    end
  end
  g_keyboard.bindKeyDown('Escape', fullmapEscapeHandler, gameRootPanel)
end

function unbindFullMapEscape()
  if not fullmapEscapeHandler then
    return
  end
  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.unbindKeyDown('Escape', fullmapEscapeHandler, gameRootPanel)
  fullmapEscapeHandler = nil
end

function updateExpandButtonState()
  if not minimapExpandButton then
    return
  end
  if fullmapView then
    minimapExpandButton:setText(tr('Close'))
    minimapExpandButton:setOn(true)
  else
    minimapExpandButton:setText(tr('Expand'))
    minimapExpandButton:setOn(false)
  end
end

function openFullMap()
  if fullmapView or not minimapWidget then
    return
  end

  ensureFullMapOverlay()

  local rootPanel = modules.game_interface.getRootPanel()
  local frameWidth = math.max(320, math.floor(rootPanel:getWidth() * FULLMAP_SIZE_RATIO))
  local frameHeight = math.max(260, math.floor(rootPanel:getHeight() * FULLMAP_SIZE_RATIO))
  local titleHeight = 26
  local mapWidth = frameWidth - 4
  local mapHeight = frameHeight - titleHeight - 6

  local frame = fullmapOverlay:getChildById('frame')
  if frame then
    frame:setSize({ width = frameWidth, height = frameHeight })
  end

  fullmapView = true
  minimapWindow:hide()

  fullmapOverlay:show()
  fullmapOverlay:raise()
  if fullmapCloseButton then
    fullmapCloseButton:raise()
  end

  minimapWidget:setParent(fullmapHolder)
  minimapWidget:breakAnchors()
  minimapWidget:fill('parent')
  minimapWidget:setMargin(2)
  minimapWidget:setAlternativeWidgetsVisible(true)

  local zoom = oldZoom or minimapWidget:getZoom()
  local pos = oldPos or minimapWidget:getCameraPosition()
  oldZoom = minimapWidget:getZoom()
  oldPos = minimapWidget:getCameraPosition()
  minimapWidget:setZoom(zoom)
  minimapWidget:setCameraPosition(pos)

  local player = g_game.getLocalPlayer()
  if player then
    minimapWidget:setCameraPosition(player:getPosition())
    minimapWidget:setCrossPosition(player:getPosition())
  end

  bindFullMapEscape()
  updateExpandButtonState()
end

function closeFullMap()
  if not fullmapView or not minimapWidget then
    return
  end

  fullmapView = false

  local contentsPanel = minimapWindow:getChildById('contentsPanel')
  minimapWidget:setParent(contentsPanel)
  minimapWidget:breakAnchors()
  minimapWidget:fill('parent')
  minimapWidget:setAlternativeWidgetsVisible(false)

  local zoom = oldZoom or 0
  local pos = oldPos or minimapWidget:getCameraPosition()
  oldZoom = minimapWidget:getZoom()
  oldPos = minimapWidget:getCameraPosition()
  minimapWidget:setZoom(zoom)
  minimapWidget:setCameraPosition(pos)

  if fullmapOverlay then
    fullmapOverlay:hide()
  end

  minimapWindow:show()
  unbindFullMapEscape()
  updateExpandButtonState()
  updateCameraPosition()
end

function toggleFullMap()
  if fullmapView then
    closeFullMap()
  else
    openFullMap()
  end
end
