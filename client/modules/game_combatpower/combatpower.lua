-- Combat power preview — opcode 203 (TFS getCombatPreview)
-- Doc: otserv_860/docs/COMBAT-POWER-PLAN.md

local COMBAT_POWER_OPCODE = 203

local VOCATION_NAMES = {
  [0] = "None",
  [1] = "Sorcerer",
  [2] = "Druid",
  [3] = "Paladin",
  [4] = "Knight",
  [5] = "Master Sorcerer",
  [6] = "Elder Druid",
  [7] = "Royal Paladin",
  [8] = "Elite Knight",
}

local FIGHT_MODE_NAMES = {
  attack = "Ataque",
  balanced = "Balanceado",
  defense = "Defesa",
  unknown = "?",
}

local KIND_NAMES = {
  melee = "Corpo a corpo",
  fist = "Punhos",
  distance = "Distancia",
  bow = "Arco",
  crossbow = "Besta",
  spear = "Lanca",
  wand = "Varinha",
  rod = "Cajado",
  other = "Outro",
}

local SPELL_GROUP_NAMES = {
  attack = "Dano",
  support = "Suporte",
  healing = "Cura",
  antidote = "Antidoto",
}

local SPELL_STATUS_COLORS = {
  ok = "#44cc66",
  soon = "#ffcc44",
  mana = "#ff8844",
  weapon = "#ff6666",
  locked = "#ffaaaa",
}

local SPELL_ROW_BG = {
  ok = "#1a4d2e",
  soon = "#4d4020",
  mana = "#4d3020",
  weapon = "#4d2020",
  locked = "#4d2020",
}

local SPELL_STATUS_LABELS = {
  ok = "OK",
  soon = "sem Lv",
  mana = "sem mana",
  weapon = "sem arma",
  locked = "sem Lv",
}

local STAT_VALUE_COLOR = "#ffcc00"
local STAT_PENALTY_COLOR = "#ffaa44"
local CHARM_VALUE_COLOR = "#ffd700"

local window = nil
local powerButton = nil
local serverCombatPower = nil
local requestEvent = nil
local loginRequestEvent = nil
local loginRequestPending = false
local loginPreviewRequested = false
local loginPreviewFetched = false
local loginQuietUntil = 0
local REQUEST_DEBOUNCE_MS = 600
local LOGIN_QUIET_MS = 3000
local LOGIN_REQUEST_DELAY_MS = 2400

-- refs OTUI (ids aninhados nao ficam em window.id no OTCv8)
local ui = {}

local function fmtRange(minVal, maxVal)
  local lo = math.abs(tonumber(minVal) or 0)
  local hi = math.abs(tonumber(maxVal) or 0)
  if lo > hi then
    lo, hi = hi, lo
  end
  return string.format("%d - %d", lo, hi)
end

local DISTANCE_ATTACK_KINDS = {
  distance = true,
  spear = true,
  bow = true,
  crossbow = true,
}

local function getVocationName(id)
  return VOCATION_NAMES[id] or ("Voc " .. tostring(id))
end

local function sendCombatPowerRequest()
  if not g_game.getFeature(GameExtendedOpcode) then
    return
  end
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    protocolGame:sendExtendedJSONOpcode(COMBAT_POWER_OPCODE, { action = "request", data = {} })
  end
end

local function requestCombatPower()
  sendCombatPowerRequest()
end

function scheduleRequest()
  if loginPreviewRequested and not loginPreviewFetched then
    return
  end
  if requestEvent then
    removeEvent(requestEvent)
  end
  requestEvent = scheduleEvent(function()
    requestEvent = nil
    sendCombatPowerRequest()
  end, REQUEST_DEBOUNCE_MS)
end

local function bindWindowWidgets()
  if not window then
    return
  end
  ui.headerLabel = window:recursiveGetChildById("headerLabel")
  ui.weaponValue = window:recursiveGetChildById("weaponValue")
  ui.skillValue = window:recursiveGetChildById("skillValue")
  ui.damageValue = window:recursiveGetChildById("damageValue")
  ui.elementRow = window:recursiveGetChildById("elementRow")
  ui.elementValue = window:recursiveGetChildById("elementValue")
  ui.distanceRow = window:recursiveGetChildById("distanceRow")
  ui.distanceValue = window:recursiveGetChildById("distanceValue")
  ui.charmRow = window:recursiveGetChildById("charmRow")
  ui.charmValue = window:recursiveGetChildById("charmValue")
  ui.defenseValue = window:recursiveGetChildById("defenseValue")
  ui.armorValue = window:recursiveGetChildById("armorValue")
  ui.shieldValue = window:recursiveGetChildById("shieldValue")
  ui.statsSectionPanel = window:recursiveGetChildById("statsSectionPanel")
  ui.equipmentList = window:recursiveGetChildById("equipmentList")
  ui.spellsList = window:recursiveGetChildById("spellsList")
  ui.healingList = window:recursiveGetChildById("healingList")
end

local function setStatValue(widget, text, penalty)
  if not widget then
    return
  end
  widget:setText(text)
  widget:setColor(penalty and STAT_PENALTY_COLOR or STAT_VALUE_COLOR)
end

local function fmtSpellEffect(spell)
  if (spell.damageMax or 0) > 0 then
    return string.format("dmg %d-%d", spell.damageMin or 0, spell.damageMax or 0)
  end
  if (spell.healMax or 0) > 0 then
    return string.format("cura %d-%d", spell.healMin or 0, spell.healMax or 0)
  end
  local group = spell.group or "support"
  if group == "attack" then
    return "dmg -"
  end
  return SPELL_GROUP_NAMES[group] or group
end

local function fmtSpellStatus(spell)
  local status = spell.status or "locked"
  if status == "soon" and (spell.levelDeficit or 0) > 0 then
    return string.format("Lv-%d", spell.levelDeficit)
  end
  return SPELL_STATUS_LABELS[status] or status
end

local function spellLineColor(spell)
  return SPELL_STATUS_COLORS[spell.status] or "#bbbbbb"
end

local function spellRowBackground(spell)
  return SPELL_ROW_BG[spell.status] or "#383838"
end

local function addListLine(list, text, color)
  if not list then
    return
  end
  local label = g_ui.createWidget("Label", list)
  label:setFont("verdana-11px-antialised")
  label:setTextWrap(true)
  label:setText(text)
  label:setColor(color or "#bbbbbb")
end

local function applySpellIconImage(widget, spellName, words)
  if not widget then
    return
  end
  local icon = Spells.getSpellIcon(spellName, words)
  if icon and icon.source then
    widget:setImageSource(icon.source)
    widget:setImageClip(icon.clip)
    widget:setVisible(true)
  else
    widget:setVisible(false)
  end
end

local function applyRuneIcon(row, runeName, serverItemId, clientId, count)
  if not row then
    return
  end
  local icon = Spells.getRuneDisplayIcon(runeName, serverItemId, clientId)
  if not icon then
    if row.iconImage then
      row.iconImage:setVisible(false)
    end
    if row.iconItem then
      row.iconItem:setVisible(false)
    end
    return
  end

  if icon.kind == 'spell' and row.iconImage then
    row.iconImage:setImageSource(icon.source)
    row.iconImage:setImageClip(icon.clip)
    row.iconImage:setVisible(true)
    if row.iconItem then
      row.iconItem:setVisible(false)
    end
  elseif icon.kind == 'item' and row.iconItem then
    Spells.applyItemIcon(row.iconItem, icon.clientId, count)
    row.iconItem:setVisible(true)
    if row.iconImage then
      row.iconImage:setVisible(false)
    end
  end
end

local function rebuildSpellList(spells)
  if not ui.spellsList then
    return
  end
  local list = ui.spellsList
  list:destroyChildren()

  if not spells or #spells == 0 then
    addListLine(list, tr("Nenhuma magia instantanea."), "#888888")
    return
  end

  for _, spell in ipairs(spells) do
    local words = spell.words or ""
    local title = words:len() > 0 and words or (spell.name or "?")
    local line = string.format("%s | Lv %d | mana %s | %s | %s",
      title, spell.level or 0, tostring(spell.mana or 0),
      fmtSpellEffect(spell), fmtSpellStatus(spell))
    local textColor = spellLineColor(spell)

    local row = g_ui.createWidget("CombatPowerSpellRow", list)
    row:setBackgroundColor(spellRowBackground(spell))

    if row.lineText then
      row.lineText:setText(line)
      row.lineText:setColor(textColor)
    end
    applySpellIconImage(row.iconImage, spell.name, spell.words)
  end
end

local function runeStatusBadge(rune)
  local status = rune.status or "ok"
  local textColor = SPELL_STATUS_COLORS[status] or "#88dd99"
  local badge = SPELL_STATUS_LABELS[status] or "OK"
  if status == "ok" then
    badge = tr("tem no inventario")
    textColor = SPELL_STATUS_COLORS.ok
  elseif status == "locked" and rune.reason == "maglevel" then
    badge = tr("falta ML")
  elseif status == "locked" and rune.reason == "level" then
    badge = tr("falta level")
  end
  return status, textColor, badge
end

local function runeDisplayTitle(rune)
  local runeTitle = rune.name or "?"
  if not runeTitle:lower():find("rune") then
    runeTitle = runeTitle .. " (rune)"
  end
  return runeTitle
end

local function addRuneRow(list, rune, line, textColor, okBackground)
  local row = g_ui.createWidget("CombatPowerRuneRow", list)
  if (rune.status or "ok") == "ok" and okBackground then
    row:setBackgroundColor(okBackground)
  end
  if row.lineText then
    row.lineText:setText(line)
    row.lineText:setColor(textColor)
  end
  applyRuneIcon(row, rune.name, rune.serverItemId or rune.itemId, rune.clientId, rune.count)
end

local function rebuildInventoryRunes(attackRunes, healingRunes)
  if not ui.healingList then
    return
  end
  local list = ui.healingList
  list:destroyChildren()

  local hasAttack = attackRunes and #attackRunes > 0
  local hasHealing = healingRunes and #healingRunes > 0

  if not hasAttack and not hasHealing then
    addListLine(list, tr("Sem runas no inventario."), "#888888")
    return
  end

  if hasAttack then
    for _, rune in ipairs(attackRunes) do
      local status, textColor, badge = runeStatusBadge(rune)
      if status == "ok" then
        textColor = "#ffaa66"
      end
      local line = string.format("%s | ML %d+ | dano: %s | %s",
        runeDisplayTitle(rune), rune.maglevel or 0,
        fmtRange(rune.damageMin, rune.damageMax), badge)
      addRuneRow(list, rune, line, textColor, "#4d3020")
    end
  end

  if hasHealing then
    for _, rune in ipairs(healingRunes) do
      local status, textColor, badge = runeStatusBadge(rune)
      local line = string.format("%s | ML %d+ | cura: %d-%d | %s",
        runeDisplayTitle(rune), rune.maglevel or 0, rune.healMin or 0, rune.healMax or 0, badge)
      addRuneRow(list, rune, line, textColor, "#1a4d2e")
    end
  end
end

local function rebuildEquipmentList(equipment)
  if not ui.equipmentList then
    return
  end
  local list = ui.equipmentList
  list:destroyChildren()

  if not equipment or #equipment == 0 then
    addListLine(list, tr("Nenhum item equipado."), "#888888")
    return
  end

  for _, item in ipairs(equipment) do
    local parts = { item.name or "?" }
    if (item.attack or 0) > 0 then
      parts[#parts + 1] = "atk " .. item.attack
    end
    if (item.defense or 0) > 0 then
      parts[#parts + 1] = "def " .. item.defense
    end
    if (item.armor or 0) > 0 then
      parts[#parts + 1] = "arm " .. item.armor
    end
    if (item.extraDefense or 0) > 0 then
      parts[#parts + 1] = "extradef " .. item.extraDefense
    end

    local row = g_ui.createWidget("CombatPowerEquipRow", list)
    if row.lineText then
      row.lineText:setText(string.format("[%s] %s", item.slot or "?", table.concat(parts, ", ")))
      row.lineText:setColor("#bbbbbb")
    end
    local spriteId = item.clientId or item.itemId
    if row.iconItem and spriteId and spriteId > 0 then
      Spells.applyItemIcon(row.iconItem, spriteId, 1)
      row.iconItem:setVisible(true)
    elseif row.iconItem then
      row.iconItem:setVisible(false)
    end
  end
end

local function applyCombatPower(data)
  if not window or not data or not ui.headerLabel then
    return
  end

  local attack = data.attack or {}
  local vocName = getVocationName(data.vocation)
  local fightName = FIGHT_MODE_NAMES[data.fightMode] or data.fightMode or "?"
  local wieldPenalty = (data.damageModifier or 100) < 100

  ui.headerLabel:setText(string.format(
    "%s  Lv %d\n%s | factor %.2f | wield %d%%",
    vocName, data.level or 0, fightName, data.attackFactor or 1, data.damageModifier or 100))

  local kindLabel = KIND_NAMES[attack.kind] or attack.kind or "?"
  setStatValue(ui.weaponValue, string.format("%s (%s)", attack.weaponName or "-", kindLabel), wieldPenalty)
  setStatValue(ui.skillValue, string.format("%d / atk %d", attack.skill or 0, attack.attackValue or 0), wieldPenalty)
  setStatValue(ui.damageValue, fmtRange(attack.min, attack.max), wieldPenalty)

  if ui.elementRow and ui.elementValue then
    if (attack.elementMax or 0) > 0 then
      ui.elementRow:setVisible(true)
      setStatValue(ui.elementValue, string.format("%s %s",
        attack.elementType or "", fmtRange(attack.elementMin, attack.elementMax)), wieldPenalty)
    else
      ui.elementRow:setVisible(false)
    end
  end

  if ui.distanceRow and ui.distanceValue then
    if DISTANCE_ATTACK_KINDS[attack.kind] and ((attack.minVsPlayer or 0) > 0 or (attack.minVsMonster or 0) > 0) then
      ui.distanceRow:setVisible(true)
      setStatValue(ui.distanceValue, string.format("%s / %s",
        fmtRange(attack.minVsPlayer, attack.max),
        fmtRange(attack.minVsMonster, attack.max)), wieldPenalty)
    else
      ui.distanceRow:setVisible(false)
    end
  end

  if ui.charmRow and ui.charmValue then
    local charmPercent = tonumber(attack.charmBonusPercent) or 0
    if charmPercent > 0 then
      ui.charmRow:setVisible(true)
      local charmLabel = attack.charmLabel or ""
      ui.charmValue:setText(string.format("+%d%% %s", charmPercent, charmLabel))
      ui.charmValue:setColor(CHARM_VALUE_COLOR)
    else
      ui.charmRow:setVisible(false)
    end
  end

  setStatValue(ui.defenseValue, tostring(data.defense or 0), false)
  setStatValue(ui.armorValue, tostring(data.armor or 0), false)

  local shieldText = "-"
  if attack.shieldName and attack.shieldName:len() > 0 then
    shieldText = string.format("%s (+%d)", attack.shieldName, attack.shieldDefense or 0)
  end
  setStatValue(ui.shieldValue, shieldText, false)

  if ui.statsSectionPanel then
    local statsHeight = 124
    if ui.elementRow and ui.elementRow:isVisible() then
      statsHeight = statsHeight + 21
    end
    if ui.distanceRow and ui.distanceRow:isVisible() then
      statsHeight = statsHeight + 21
    end
    if ui.charmRow and ui.charmRow:isVisible() then
      statsHeight = statsHeight + 21
    end
    ui.statsSectionPanel:setHeight(statsHeight)
  end

  rebuildEquipmentList(data.equipment)
  rebuildSpellList(data.spells)
  rebuildInventoryRunes(data.attackRunes, data.healingRunes)
end

local function onExtendedJSONOpcode(protocol, code, jsonData)
  if type(jsonData) ~= "table" or jsonData.action ~= "combatPower" then
    return
  end

  if jsonData.data and jsonData.data.error then
    return
  end

  serverCombatPower = jsonData.data
  loginPreviewFetched = true
  loginPreviewRequested = false
  loginRequestPending = false
  if window and window:isVisible() then
    applyCombatPower(serverCombatPower)
  end
end

local function onPlayerStateChange()
  if not g_game.isOnline() then
    return
  end
  if g_clock.millis() < loginQuietUntil then
    return
  end
  if not loginPreviewFetched then
    return
  end
  scheduleRequest()
end

local function onGameStart()
  serverCombatPower = nil
  loginPreviewFetched = false
  loginPreviewRequested = false
  loginQuietUntil = g_clock.millis() + LOGIN_QUIET_MS
  loginRequestPending = true
  if loginRequestEvent then
    removeEvent(loginRequestEvent)
  end
  if requestEvent then
    removeEvent(requestEvent)
    requestEvent = nil
  end
  loginRequestEvent = scheduleEvent(function()
    loginRequestEvent = nil
    loginRequestPending = false
    if loginPreviewFetched or loginPreviewRequested then
      return
    end
    loginPreviewRequested = true
    sendCombatPowerRequest()
  end, LOGIN_REQUEST_DELAY_MS)
end

local function onGameEnd()
  serverCombatPower = nil
  loginQuietUntil = 0
  loginRequestPending = false
  loginPreviewRequested = false
  loginPreviewFetched = false
  if loginRequestEvent then
    removeEvent(loginRequestEvent)
    loginRequestEvent = nil
  end
  if requestEvent then
    removeEvent(requestEvent)
    requestEvent = nil
  end
  hide()
end

function init()
  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd,
    onFightModeChange = onPlayerStateChange,
  })

  connect(LocalPlayer, {
    onInventoryChange = onPlayerStateChange,
    onLevelChange = onPlayerStateChange,
    onSkillChange = onPlayerStateChange,
    onMagicLevelChange = onPlayerStateChange,
  })

  connect(Container, {
    onUpdateItem = onPlayerStateChange,
  })

  ProtocolGame.registerExtendedJSONOpcode(COMBAT_POWER_OPCODE, onExtendedJSONOpcode)

  powerButton = modules.client_topmenu.addRightGameToggleButton(
    "combatPowerButton",
    tr("Poder de combate") .. " (Ctrl+Shift+O)",
    "/images/topbuttons/unjustifiedpoints",
    toggle,
    false,
    6
  )

  local gameRootPanel = modules.game_interface.getRootPanel()
  g_keyboard.bindKeyDown("Ctrl+Shift+O", toggle, gameRootPanel)

  if g_game.isOnline() then
    onGameStart()
  end
end

function terminate()
  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd,
    onFightModeChange = onPlayerStateChange,
  })

  disconnect(LocalPlayer, {
    onInventoryChange = onPlayerStateChange,
    onLevelChange = onPlayerStateChange,
    onSkillChange = onPlayerStateChange,
    onMagicLevelChange = onPlayerStateChange,
  })

  disconnect(Container, {
    onUpdateItem = onPlayerStateChange,
  })

  ProtocolGame.unregisterExtendedJSONOpcode(COMBAT_POWER_OPCODE, onExtendedJSONOpcode)

  local gameRootPanel = modules.game_interface.getRootPanel()
  if gameRootPanel then
    g_keyboard.unbindKeyDown("Ctrl+Shift+O", gameRootPanel)
  end

  if requestEvent then
    removeEvent(requestEvent)
    requestEvent = nil
  end

  if loginRequestEvent then
    removeEvent(loginRequestEvent)
    loginRequestEvent = nil
  end
  loginRequestPending = false
  loginPreviewRequested = false
  loginPreviewFetched = false

  if powerButton then
    powerButton:destroy()
    powerButton = nil
  end

  if window then
    window:destroy()
    window = nil
  end
  ui = {}
end

function toggle()
  if not powerButton then
    return
  end
  if powerButton:isOn() then
    hide()
  else
    show()
  end
end

function show()
  if not g_game.getFeature(GameExtendedOpcode) then
    displayInfoBox(tr("Combat Power"),
      tr("Requires GameExtendedOpcode and otcv8_combatpower.lua on the server.\nSee docs/COMBAT-POWER-PLAN.md"))
    return
  end

  if not window then
    window = g_ui.loadUI("combatpower", g_ui.getRootWidget())
    bindWindowWidgets()
  end

  if serverCombatPower then
    applyCombatPower(serverCombatPower)
  elseif loginRequestPending or loginPreviewRequested or requestEvent or not loginPreviewFetched then
    -- Aguarda o unico request automatico do login (ou resposta em voo).
  else
    scheduleRequest()
  end

  window:show()
  window:raise()
  window:focus()

  if powerButton then
    powerButton:setOn(true)
  end
end

function hide()
  if powerButton then
    powerButton:setOn(false)
  end
  if window then
    window:hide()
  end
end

-- export for otui @onClick
requestCombatPower = requestCombatPower
