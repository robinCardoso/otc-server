-- private variables
local background
local clientVersionLabel

-- public functions
function init()
  background = g_ui.displayUI('background')
  if not background then
    g_logger.error('client_background: falha ao carregar background.otui')
    return
  end
  background:lower()

  clientVersionLabel = background:getChildById('clientVersionLabel')
  clientVersionLabel:setText('OTClientV8 ' .. g_app.getVersion() .. '\nrev ' .. g_app.getBuildRevision() .. '\nMade by:\n' .. g_app.getAuthor() .. "")
  
  if not g_game.isOnline() then
    addEvent(function() g_effects.fadeIn(clientVersionLabel, 1500) end)
  end

  connect(g_game, { onGameStart = hide })
  connect(g_game, { onGameEnd = show })
end

function terminate()
  disconnect(g_game, { onGameStart = hide })
  disconnect(g_game, { onGameEnd = show })

  if background then
    g_effects.cancelFade(background:getChildById('clientVersionLabel'))
    background:destroy()
  end

  background = nil
end

function hide()
  if background then
    background:hide()
  end
end

function show()
  if background then
    background:show()
  end
end

function hideVersionLabel()
  if background then
    background:getChildById('clientVersionLabel'):hide()
  end
end

function setVersionText(text)
  if clientVersionLabel then
    clientVersionLabel:setText(text)
  end
end

function getBackground()
  return background
end