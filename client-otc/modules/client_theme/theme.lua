ClientTheme = {}

local currentTheme = 'dark'
local widgetStyles = setmetatable({}, { __mode = 'k' })

local PALETTES = {
  dark = {
    text = '#dfdfdf',
    textMuted = '#aaaaaa',
    panelBg = '#32323ccc',
    panelLight = '#3c3c48cc',
    hoverBg = '#484858',
    selectionBg = '#585868',
    consoleBg = '#32323cee',
    consoleBorder = '#585868',
    chatColor = '#c87800',
  },
  medium = {
    text = '#e8e8ec',
    textMuted = '#c0c0c8',
    panelBg = '#585868cc',
    panelLight = '#686878cc',
    hoverBg = '#686878',
    selectionBg = '#787888',
    consoleBg = '#585868ee',
    consoleBorder = '#787888',
    chatColor = '#d88800',
  },
  light = {
    text = '#2e2e38',
    textMuted = '#4a4a58',
    panelBg = '#b0b0bccc',
    panelLight = '#c8c8d4cc',
    hoverBg = '#c8d4e8',
    selectionBg = '#8898b0',
    consoleBg = '#b0b0bcee',
    consoleBorder = '#9898a8',
    chatColor = '#c87800',
  },
}

local STYLE_IMAGES = {
  TopMenu = 'panel_top',
  TopMenuPanel = 'panel_top',
  MiniWindow = 'miniwindow',
  HeadlessWindow = 'window_headless',
  Window = 'window',
  MainWindow = 'window',
  StaticWindow = 'window',
  Button = 'button',
  TabButton = 'tabbutton_rounded',
  MoveableTabBarButton = 'tabbutton_square',
  TabBarButton = 'tabbutton_square',
  TabBarRoundedButton = 'tabbutton_rounded',
  FlatPanel = 'panel_flat',
  ScrollableFlatPanel = 'panel_flat',
  LightFlatPanel = 'panel_lightflat',
  TextEdit = 'textedit',
  ComboBox = 'combobox_square',
  ComboBoxRounded = 'combobox_rounded',
  CheckBox = 'checkbox',
  ButtonBox = 'button',
  ConsolePanel = 'panel_bottom',
  NextButton = 'arrow_horizontal',
  PreviousButton = 'arrow_horizontal',
  AddButton = 'icon_add',
}

local SLOT_STYLES = {
  HeadSlot = 'head',
  BodySlot = 'body',
  LegSlot = 'legs',
  FeetSlot = 'feet',
  NeckSlot = 'neck',
  LeftSlot = 'left-hand',
  FingerSlot = 'finger',
  BackSlot = 'back',
  RightSlot = 'right-hand',
  AmmoSlot = 'ammo',
}

local TEXT_STYLES = {
  Label = true,
  FlatLabel = true,
  MenuLabel = true,
  GameLabel = true,
  SkillNameLabel = true,
  SkillValueLabel = true,
  TextEdit = true,
  PasswordTextEdit = true,
  MultilineTextEdit = true,
  ComboBox = true,
  ComboBoxRounded = true,
  TopMenuFrameCounterLabel = true,
  TopMenuPingLabel = true,
}

local LOGIN_ROOT_IDS = {
  enterGame = true,
  charactersWindow = true,
  createAccountWindow = true,
  createCharacterWindow = true,
}

local function widgetAlive(widget)
  if not widget then
    return false
  end
  local ok, destroyed = pcall(function()
    return widget:isDestroyed()
  end)
  return ok and not destroyed
end

local function rememberStyle(widget, styleName)
  if widget and styleName and styleName:len() > 0 then
    widgetStyles[widget] = styleName
  end
end

-- getStyleName() no C++ crasha se m_style == nil; nunca chamar sem getStyle().
local function styleNameOf(widget, styleNameHint)
  if styleNameHint and styleNameHint:len() > 0 then
    return styleNameHint
  end
  if not widgetAlive(widget) then
    return nil
  end
  if widgetStyles[widget] then
    return widgetStyles[widget]
  end
  local style = widget:getStyle()
  if not style then
    return nil
  end
  local name = widget:getStyleName()
  if name and name:len() > 0 then
    rememberStyle(widget, name)
    return name
  end
  return nil
end

local function isLoginTree(widget)
  if not widgetAlive(widget) then
    return false
  end
  local node = widget
  while node do
    local id = node:getId()
    if id and LOGIN_ROOT_IDS[id] then
      return true
    end
    node = node:getParent()
  end
  return false
end

local function themeUiImage(name)
  return '/images/ui/theme/' .. currentTheme .. '/' .. name
end

local function themeSlotImage(name)
  return '/images/game/slots/theme/' .. currentTheme .. '/' .. name
end

local function applyTextColor(widget, palette, styleName)
  if not styleName or not TEXT_STYLES[styleName] then
    return
  end
  widget:setColor(palette.text)
end

local function applyStyleImage(widget, palette, styleName)
  if not styleName then
    return
  end

  local uiImage = STYLE_IMAGES[styleName]
  if uiImage then
    widget:setImageSource(themeUiImage(uiImage))
  end

  local slotImage = SLOT_STYLES[styleName]
  if slotImage then
    widget:setImageSource(themeSlotImage(slotImage))
  end

  if styleName == 'FlatPanel' or styleName == 'ScrollableFlatPanel' then
    widget:setBackgroundColor(palette.panelBg)
  elseif styleName == 'LightFlatPanel' then
    widget:setBackgroundColor(palette.panelLight)
  elseif styleName == 'MiniWindow' or styleName == 'Window' or styleName == 'HeadlessWindow' then
    widget:setColor(palette.text)
  elseif styleName == 'MoveableTabBarButton' or styleName == 'TabBarButton' or styleName == 'TabBarRoundedButton' then
    widget:setColor(palette.text)
    widget:setIconColor(palette.text)
  elseif styleName == 'TopMenuFrameCounterLabel' or styleName == 'TopMenuPingLabel' then
    widget:setColor(palette.text)
  elseif styleName == 'ConsoleLabel' or styleName == 'ConsolePhantomLabel' then
    widget:setColor(palette.chatColor)
  end
end

function ClientTheme.applyWidget(widget, styleNameHint)
  if not widgetAlive(widget) or isLoginTree(widget) then
    return
  end

  local palette = PALETTES[currentTheme]
  if not palette then
    return
  end

  local styleName = styleNameOf(widget, styleNameHint)
  if not styleName then
    return
  end

  rememberStyle(widget, styleName)
  applyTextColor(widget, palette, styleName)
  applyStyleImage(widget, palette, styleName)
end

local function visitTree(widget)
  if not widgetAlive(widget) then
    return
  end

  pcall(function()
    local style = widget:getStyle()
    if style then
      local name = widget:getStyleName()
      if name and name:len() > 0 then
        ClientTheme.applyWidget(widget, name)
      end
    end
  end)

  local children = widget:getChildren()
  if children then
    for _, child in ipairs(children) do
      visitTree(child)
    end
  end
end

function ClientTheme.getTheme()
  return currentTheme
end

function ClientTheme.getPalette()
  return PALETTES[currentTheme]
end

function ClientTheme.applyTheme(theme, force)
  if not PALETTES[theme] then
    theme = 'dark'
  end
  if not force and theme == currentTheme then
    return
  end

  currentTheme = theme
  g_settings.set('uiTheme', theme)

  for widget, styleName in pairs(widgetStyles) do
    if widgetAlive(widget) then
      ClientTheme.applyWidget(widget, styleName)
    else
      widgetStyles[widget] = nil
    end
  end

  local root = g_ui.getRootWidget()
  if root then
    visitTree(root)
  end
end

function init()
  -- Desativado para usar estritamente o layout "modern" sem misturar com assets escuros do client_theme
  --[[
  local saved = g_settings.getString('uiTheme')
  if saved:len() == 0 then
    local legacyLayout = g_settings.getString('layout'):lower()
    if legacyLayout == 'modern-medium' then
      saved = 'medium'
    elseif legacyLayout == 'modern-light' then
      saved = 'light'
    else
      saved = 'dark'
    end
  end

  currentTheme = PALETTES[saved] and saved or 'dark'

  -- Aplica apos todos os modulos client carregarem (nao intercepta displayUI/loadUI)
  scheduleEvent(function()
    ClientTheme.applyTheme(currentTheme, true)
  end, 500)
  ]]
end

function terminate()
end
