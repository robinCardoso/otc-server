-- Party panel — opcode 204 (partyStatus)
-- Doc: otserv_860/docs/PARTY-MODULE.md

local PARTY_OPCODE = 204

local VOCATION_NAMES = {
  [0] = 'None',
  [1] = 'Sorcerer',
  [2] = 'Druid',
  [3] = 'Paladin',
  [4] = 'Knight',
  [5] = 'Master Sorcerer',
  [6] = 'Elder Druid',
  [7] = 'Royal Paladin',
  [8] = 'Elite Knight',
}

partyWindow = nil
partyButton = nil
partyStatus = nil
partyOpcodeRegistered = false
requestEvent = nil
lastRequestAt = 0
local memberRowsByName = {}
local inviteRowsByName = {}

local ui = {}

local function getVocationName(id)
  return VOCATION_NAMES[id] or ('Voc ' .. tostring(id))
end

local function setBarPercent(bar, current, maximum)
  if not bar then
    return
  end
  maximum = tonumber(maximum) or 0
  current = tonumber(current) or 0
  if maximum <= 0 then
    bar:setPercent(0)
    return
  end
  bar:setPercent(math.max(0, math.min(100, math.floor((current / maximum) * 100))))
end

function registerPartyOpcode()
  if partyOpcodeRegistered then
    return
  end
  ProtocolGame.registerExtendedJSONOpcode(PARTY_OPCODE, onPartyExtendedJSON)
  partyOpcodeRegistered = true
end

function unregisterPartyOpcode()
  if not partyOpcodeRegistered then
    return
  end
  ProtocolGame.unregisterExtendedJSONOpcode(PARTY_OPCODE)
  partyOpcodeRegistered = false
end

function onPartyExtendedJSON(protocol, opcode, jsonData)
  if type(jsonData) ~= 'table' then
    return
  end
  local action = jsonData.action
  if action ~= 'partyStatus' and action ~= 'partyMinimap' then
    return
  end
  if type(jsonData.data) ~= 'table' then
    return
  end

  partyStatus = jsonData.data

  if partyWindow and partyButton and partyButton:isOn() then
    refreshPanel()
  end

  if modules.game_minimap and modules.game_minimap.onPartyStatusUpdate then
    modules.game_minimap.onPartyStatusUpdate(partyStatus)
  end
end

function requestPartyStatus()
  if not g_game.isOnline() or not g_game.getFeature(GameExtendedOpcode) then
    return
  end
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer or not localPlayer:isPartyMember() then
    return
  end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    lastRequestAt = g_clock.millis()
    protocolGame:sendExtendedJSONOpcode(PARTY_OPCODE, { action = 'request', data = {} })
  end
end

function scheduleRequest()
  if requestEvent then
    removeEvent(requestEvent)
  end
  requestEvent = scheduleEvent(function()
    requestEvent = nil
    requestPartyStatus()
  end, 200)
end

function getPartyStatus()
  return partyStatus
end

local function setLabelTextIfChanged(label, text)
  if label and label:getText() ~= text then
    label:setText(text)
  end
end

function clearMemberRows()
  memberRowsByName = {}
  if not ui.membersPanel then
    return
  end
  ui.membersPanel:destroyChildren()
end

function clearInviteRows()
  inviteRowsByName = {}
  if not ui.invitesPanel then
    return
  end
  ui.invitesPanel:destroyChildren()
end

function updateMemberRow(row, member, isSelf)
  local nameText = member.name or '?'
  if member.leader then
    nameText = nameText .. ' [' .. tr('Leader') .. ']'
  end
  if isSelf then
    nameText = nameText .. ' (' .. tr('You') .. ')'
  end

  local levelLabel = string.format('Lv %d - %s', member.level or 0, getVocationName(member.vocation))
  setLabelTextIfChanged(row.nameLabel, nameText .. '\n' .. levelLabel)

  setBarPercent(row.healthBar, member.hp, member.maxHp)
  setBarPercent(row.manaBar, member.mana, member.maxMana)

  local nameColor = '#e0e0e0'
  if member.leader then
    nameColor = '#ffdd66'
  elseif isSelf then
    nameColor = '#88bbff'
  end
  row.nameLabel:setColor(nameColor)
end

function syncMemberRows(members, localName)
  local seen = {}
  if type(members) == 'table' then
    for _, member in ipairs(members) do
      if type(member) == 'table' and member.name then
        seen[member.name] = true
        local row = memberRowsByName[member.name]
        if not row or row:isDestroyed() then
          row = g_ui.createWidget('PartyMemberRow', ui.membersPanel)
          memberRowsByName[member.name] = row
        end
        updateMemberRow(row, member, member.name == localName)
      end
    end
  end

  for name, row in pairs(memberRowsByName) do
    if not seen[name] then
      if row and not row:isDestroyed() then
        row:destroy()
      end
      memberRowsByName[name] = nil
    end
  end

  local memberCount = ui.membersPanel:getChildCount()
  ui.membersPanel:setHeight(math.max(10, memberCount * 48))
end

function syncInviteRows(invites)
  local seen = {}
  if type(invites) == 'table' then
    for _, invite in ipairs(invites) do
      if type(invite) == 'table' and invite.name then
        seen[invite.name] = true
        local row = inviteRowsByName[invite.name]
        if not row or row:isDestroyed() then
          row = g_ui.createWidget('PartyInviteRow', ui.invitesPanel)
          inviteRowsByName[invite.name] = row
        end
        setLabelTextIfChanged(row.inviteLabel, invite.name)
        row.inviteLabel:setTooltip(tr('Right-click player on map to revoke'))
      end
    end
  end

  for name, row in pairs(inviteRowsByName) do
    if not seen[name] then
      if row and not row:isDestroyed() then
        row:destroy()
      end
      inviteRowsByName[name] = nil
    end
  end
end

function refreshPanel()
  if not partyWindow then
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer or not partyStatus or not partyStatus.inParty then
    clearMemberRows()
    clearInviteRows()
    setLabelTextIfChanged(ui.sharedExpLabel, tr('You are not in a party.'))
    setLabelTextIfChanged(ui.bonusLabel, '')
    ui.sharedExpButton:setVisible(false)
    ui.leaveButton:setVisible(false)
    ui.invitesHeader:setVisible(false)
    ui.invitesPanel:setVisible(false)
    ui.membersPanel:setHeight(10)
    return
  end

  local localName = localPlayer:getName()
  syncMemberRows(partyStatus.members, localName)

  local bonus = partyStatus.vocationBonusPercent or 0
  if partyStatus.sharedExpActive then
    local line = tr('Shared exp: ON')
    if partyStatus.sharedExpEnabled == false then
      line = line .. ' (' .. tr('inactive') .. ')'
    end
    setLabelTextIfChanged(ui.sharedExpLabel, line)
  else
    setLabelTextIfChanged(ui.sharedExpLabel, tr('Shared exp: OFF'))
  end
  setLabelTextIfChanged(ui.bonusLabel, tr('Vocation bonus') .. ': +' .. tostring(bonus) .. '%')

  local invites = partyStatus.invites
  local hasInvites = type(invites) == 'table' and #invites > 0
  ui.invitesHeader:setVisible(hasInvites)
  ui.invitesPanel:setVisible(hasInvites)
  if hasInvites then
    syncInviteRows(invites)
    ui.invitesPanel:setHeight(#invites * 20)
  else
    clearInviteRows()
    ui.invitesPanel:setHeight(10)
  end

  ui.leaveButton:setVisible(true)
  local isLeader = partyStatus.isLeader or localPlayer:isPartyLeader()
  ui.sharedExpButton:setVisible(isLeader)
  if isLeader then
    if partyStatus.sharedExpActive then
      ui.sharedExpButton:setText(tr('Disable shared exp'))
    else
      ui.sharedExpButton:setText(tr('Enable shared exp'))
    end
  end
end

function onSharedExpClick()
  if not partyStatus or not partyStatus.isLeader then
    return
  end
  g_game.partyShareExperience(not partyStatus.sharedExpActive)
  scheduleRequest()
end

function onLeaveClick()
  g_game.partyLeave()
  partyStatus = nil
  refreshPanel()
end

function onLocalShieldChange()
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer and localPlayer:isPartyMember() then
    scheduleRequest()
  else
    partyStatus = nil
    refreshPanel()
    if modules.game_minimap and modules.game_minimap.onPartyStatusUpdate then
      modules.game_minimap.onPartyStatusUpdate(nil)
    end
  end
end

function bindUi()
  ui.sharedExpLabel = partyWindow:recursiveGetChildById('sharedExpLabel')
  ui.bonusLabel = partyWindow:recursiveGetChildById('bonusLabel')
  ui.membersPanel = partyWindow:recursiveGetChildById('membersPanel')
  ui.invitesHeader = partyWindow:recursiveGetChildById('invitesHeader')
  ui.invitesPanel = partyWindow:recursiveGetChildById('invitesPanel')
  ui.sharedExpButton = partyWindow:recursiveGetChildById('sharedExpButton')
  ui.leaveButton = partyWindow:recursiveGetChildById('leaveButton')

  ui.sharedExpButton.onClick = onSharedExpClick
  ui.leaveButton.onClick = onLeaveClick
end

function init()
  registerPartyOpcode()

  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd,
    onClientVersionChange = registerPartyOpcode,
  })

  connect(LocalPlayer, {
    onShieldChange = onLocalShieldChange,
  })

  partyButton = modules.client_topmenu.addRightGameToggleButton(
    'partyButton',
    tr('Party') .. ' (Ctrl+Shift+P)',
    '/images/topbuttons/party',
    toggle,
    false,
    5
  )
  partyButton:setOn(false)

  partyWindow = g_ui.loadUI('party', modules.game_interface.getRightPanel())
  partyWindow:setContentMinimumHeight(120)
  partyWindow:setup()
  bindUi()

  g_keyboard.bindKeyDown('Ctrl+Shift+P', toggle)

  if g_game.isOnline() then
    onGameStart()
  end
end

function terminate()
  g_keyboard.unbindKeyDown('Ctrl+Shift+P')

  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd,
    onClientVersionChange = registerPartyOpcode,
  })

  disconnect(LocalPlayer, {
    onShieldChange = onLocalShieldChange,
  })

  unregisterPartyOpcode()

  if requestEvent then
    removeEvent(requestEvent)
    requestEvent = nil
  end

  if partyWindow then
    partyWindow:destroy()
    partyWindow = nil
  end
  if partyButton then
    partyButton:destroy()
    partyButton = nil
  end

  partyStatus = nil
  memberRowsByName = {}
  inviteRowsByName = {}
end

function onGameStart()
  partyStatus = nil
  scheduleRequest()
end

function onGameEnd()
  partyStatus = nil
  if partyButton then
    partyButton:setOn(false)
  end
  if partyWindow then
    partyWindow:close()
  end
end

function toggle()
  if not partyButton or not partyWindow then
    return
  end
  if partyButton:isOn() then
    partyWindow:close()
    partyButton:setOn(false)
  else
    partyWindow:open()
    partyButton:setOn(true)
    scheduleRequest()
    refreshPanel()
  end
end

function onMiniWindowClose()
  if partyButton then
    partyButton:setOn(false)
  end
end

-- API para game_minimap
function applyPartyStatus(data)
  onPartyExtendedJSON(nil, PARTY_OPCODE, { action = 'partyStatus', data = data })
end
