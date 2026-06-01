-- !estoque — debug depot stock (opcode 205)

function onSay(player, words, param)
	local ok, err = Otcv8Stock.canUse(player)
	if not ok then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "[Estoque] " .. err)
		return false
	end

	local catalog = Otcv8Stock.buildCatalog(player, {})
	local summary = catalog.summary or {}
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
		string.format("[Estoque] Stacks: %d | Tipos: %d | Total itens: %d | Limite depot: %d",
			summary.slots or 0, summary.distinct or 0, summary.totalCount or 0, summary.depotLimit or 0))

	Otcv8Stock.sendCatalog(player, {})
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Estoque] Opcode 205 enviado.")
	return false
end
