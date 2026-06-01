AccountRegister = {}

local createAccountWindow
local createCharacterWindow
local registerMeta

local function getRegisterApiUrl()
  if RegisterApi and type(RegisterApi) == 'string' and RegisterApi:len() > 8 then
    return RegisterApi
  end
  if Servers and G and G.server and Servers[G.server] and type(Servers[G.server]) == 'table' and Servers[G.server].registerUrl then
    return Servers[G.server].registerUrl
  end
  return 'http://localhost/login.php'
end

local function formatRegisterErrors(data)
  if type(data.errors) == 'table' then
    local parts = {}
    for field, msg in pairs(data.errors) do
      table.insert(parts, tostring(msg))
    end
    if #parts > 0 then
      return table.concat(parts, '\n')
    end
  end
  return data.errorMessage or tr('Registration failed.')
end

local function setStatus(widget, text, isError)
  if not widget then return end
  widget:setText(text or '')
  if isError == false then
    widget:setColor('#66cc66')
  else
    widget:setColor('#ff6666')
  end
end

local function fillComboFromMeta(combo, items, defaultIndex)
  combo:clearOptions()
  if not items or #items == 0 then
    return
  end
  for i, item in ipairs(items) do
    combo:addOption(item.name, item.id)
  end
  if defaultIndex and defaultIndex > 0 and defaultIndex <= #items then
    combo:setCurrentOption(items[defaultIndex].name, false)
  elseif #items > 0 then
    combo:setCurrentOption(items[1].name, false)
  end
end

local function getComboId(combo)
  if not combo then return nil end
  local option = combo:getCurrentOption()
  if not option or not option.data then
    return tonumber(option and option.text)
  end
  return tonumber(option.data)
end

function AccountRegister.populateCharacterFields(window, meta)
  if not window or not meta then return end
  fillComboFromMeta(window:getChildById('sex'), meta.genders, 2)
  fillComboFromMeta(window:getChildById('vocation'), meta.vocations, 1)
  fillComboFromMeta(window:getChildById('town'), meta.towns, 1)
end

function AccountRegister.fetchMeta(callback)
  if registerMeta then
    callback(registerMeta, nil)
    return
  end

  HTTP.postJSON(getRegisterApiUrl(), { type = 'registerMeta' }, function(data, err)
    if err then
      callback(nil, err)
      return
    end
    if data and data.errorCode then
      callback(nil, formatRegisterErrors(data))
      return
    end
    if data and data.success then
      registerMeta = data
      callback(registerMeta, nil)
      return
    end
    callback(nil, tr('Invalid response from registration server.'))
  end)
end

function AccountRegister.showCreateAccount()
  AccountRegister.fetchMeta(function(meta, err)
    if err then
      displayErrorBox(tr('Registration'), err)
      return
    end

    if createAccountWindow then
      createAccountWindow:destroy()
    end

    createAccountWindow = g_ui.displayUI(EnterGame.resolveUiPath('entergame_createaccount'))
    if not createAccountWindow then
      displayErrorBox(tr('Registration'), tr('Could not open registration window. Check the client log.'))
      return
    end

    AccountRegister.populateCharacterFields(createAccountWindow, meta)

    if not meta.createCharacterOnRegister then
      createAccountWindow:getChildById('characterName'):disable()
      createAccountWindow:getChildById('sex'):disable()
      createAccountWindow:getChildById('vocation'):disable()
      createAccountWindow:getChildById('town'):disable()
    end

    createAccountWindow:raise()
    createAccountWindow:focus()
  end)
end

function AccountRegister.hideCreateAccount()
  if createAccountWindow then
    createAccountWindow:destroy()
    createAccountWindow = nil
  end
end

function AccountRegister.submitCreateAccount()
  if not createAccountWindow then return end

  local statusLabel = createAccountWindow:getChildById('statusLabel')
  setStatus(statusLabel, tr('Please wait...'), false)

  local accountName = createAccountWindow:getChildById('accountName'):getText()
  local password = createAccountWindow:getChildById('password'):getText()

  local data = {
    type = 'createAccount',
    account = accountName,
    email = createAccountWindow:getChildById('email'):getText(),
    password = password,
    password2 = createAccountWindow:getChildById('password2'):getText(),
    accept_rules = createAccountWindow:getChildById('acceptRules'):isChecked(),
    name = createAccountWindow:getChildById('characterName'):getText(),
    sex = getComboId(createAccountWindow:getChildById('sex')),
    vocation = getComboId(createAccountWindow:getChildById('vocation')),
    town = getComboId(createAccountWindow:getChildById('town')),
  }

  createAccountWindow:getChildById('submitButton'):disable()

  HTTP.postJSON(getRegisterApiUrl(), data, function(response, err)
    if createAccountWindow then
      createAccountWindow:getChildById('submitButton'):enable()
    end
    if err then
      if statusLabel then setStatus(statusLabel, err, true) end
      return
    end
    if response and response.errorCode then
      if statusLabel then setStatus(statusLabel, formatRegisterErrors(response), true) end
      return
    end
    if not response or not response.success then
      if statusLabel then setStatus(statusLabel, tr('Registration failed.'), true) end
      return
    end

    AccountRegister.hideCreateAccount()

    if enterGame then
      enterGame:getChildById('accountNameTextEdit'):setText(accountName)
      enterGame:getChildById('accountPasswordTextEdit'):setText(password)
      enterGame:getChildById('rememberPasswordBox'):setChecked(true)
    end

    local msg = response.message or tr('Account created successfully.')
    local infoBox = displayInfoBox(tr('Registration'), msg)
    infoBox.onOk = function()
      EnterGame.doLogin(accountName, password)
    end
  end)
end

function AccountRegister.showCreateCharacter()
  AccountRegister.fetchMeta(function(meta, err)
    if err then
      displayErrorBox(tr('Registration'), err)
      return
    end

    if not G or not G.account or G.account:len() == 0 then
      displayErrorBox(tr('Registration'), tr('You must be logged in to create a character.'))
      return
    end

    if createCharacterWindow then
      createCharacterWindow:destroy()
    end

    createCharacterWindow = g_ui.displayUI(EnterGame.resolveUiPath('characterlist_create'))
    if not createCharacterWindow then
      displayErrorBox(tr('Registration'), tr('Could not open character creation window. Check the client log.'))
      return
    end
    AccountRegister.populateCharacterFields(createCharacterWindow, meta)
    createCharacterWindow:raise()
    createCharacterWindow:focus()
  end)
end

function AccountRegister.hideCreateCharacter()
  if createCharacterWindow then
    createCharacterWindow:destroy()
    createCharacterWindow = nil
  end
end

function AccountRegister.submitCreateCharacter()
  if not createCharacterWindow then return end

  local statusLabel = createCharacterWindow:getChildById('statusLabel')
  setStatus(statusLabel, tr('Please wait...'), false)

  local data = {
    type = 'createCharacter',
    account = G.account,
    password = G.password,
    name = createCharacterWindow:getChildById('characterName'):getText(),
    sex = getComboId(createCharacterWindow:getChildById('sex')),
    vocation = getComboId(createCharacterWindow:getChildById('vocation')),
    town = getComboId(createCharacterWindow:getChildById('town')),
  }

  createCharacterWindow:getChildById('submitButton'):disable()

  HTTP.postJSON(getRegisterApiUrl(), data, function(response, err)
    if createCharacterWindow then
      createCharacterWindow:getChildById('submitButton'):enable()
    end
    if err then
      if statusLabel then setStatus(statusLabel, err, true) end
      return
    end
    if response and response.errorCode then
      if statusLabel then setStatus(statusLabel, formatRegisterErrors(response), true) end
      return
    end
    if not response or not response.success then
      if statusLabel then setStatus(statusLabel, tr('Could not create character.'), true) end
      return
    end

    AccountRegister.hideCreateCharacter()

    local msg = response.message or tr('Character created successfully.')
    local infoBox = displayInfoBox(tr('Registration'), msg)
    infoBox.onOk = function()
      if CharacterList and CharacterList.refresh then
        CharacterList.refresh()
      end
    end
  end)
end

function AccountRegister.terminate()
  AccountRegister.hideCreateAccount()
  AccountRegister.hideCreateCharacter()
  registerMeta = nil
end
