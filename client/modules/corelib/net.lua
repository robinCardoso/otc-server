-- Nomes/hints para logs (client_diaglog) e mensagem ao jogador
local NETWORK_ERROR_NAMES = {
  [1] = "host_unreachable",
  [2] = "eof_normal_disconnect",
  [110] = "timed_out",
  [111] = "connection_refused",
  [10053] = "WSAECONNABORTED",
  [10054] = "WSAECONNRESET",
  [10060] = "WSAETIMEDOUT",
  [10061] = "WSAECONNREFUSED",
}

local NETWORK_ERROR_HINTS = {
  [2] = "Desconexão normal (fim de arquivo). Não indica crash do servidor.",
  [10054] = "O servidor fechou o TCP de repente (crash do tfs.exe, kill do processo ou queda de rede). Abra data/logs/tfs/ no servidor na mesma hora.",
  [10053] = "Conexão abortada no meio do jogo.",
  [10060] = "Timeout de rede.",
  [10061] = "Nada escutando na porta (servidor offline).",
  [111] = "Conexão recusada — servidor parado ou porta errada.",
  [110] = "Timeout — servidor lento ou offline.",
}

function getNetworkErrorName(errcode)
  return NETWORK_ERROR_NAMES[errcode] or "unknown"
end

function getNetworkErrorHint(errcode)
  return NETWORK_ERROR_HINTS[errcode] or ""
end

function translateNetworkError(errcode, connecting, errdesc)
  local text
  if errcode == 111 or errcode == 10061 then
    text = tr('Connection refused, the server might be offline or restarting.\nPlease try again later.')
  elseif errcode == 110 or errcode == 10060 then
    text = tr('Connection timed out. Either your network is failing or the server is offline.')
  elseif errcode == 1 then
    text = tr('Connection failed, the server address does not exist.')
  elseif errcode == 10054 then
    text = tr('Connection lost: the game server closed the link abruptly.\nIf you were playing, the server likely crashed — check the TFS console log.')
  elseif errcode == 10053 then
    text = tr('Connection aborted. The link was cut while you were online.')
  elseif errcode == 2 then
    text = tr('Disconnected from the server.')
  elseif connecting then
    text = tr('Connection failed.')
  else
    text = tr('Your connection has been lost.\nEither your network or the server went down.')
  end
  local hint = getNetworkErrorHint(errcode)
  if hint ~= "" then
    text = text .. '\n\n' .. hint
  end
  text = text .. ' ' .. tr('(ERROR %d)', errcode)
  if errdesc and errdesc ~= "" and errdesc ~= tostring(errcode) then
    text = text .. '\n' .. tostring(errdesc)
  end
  return text
end
