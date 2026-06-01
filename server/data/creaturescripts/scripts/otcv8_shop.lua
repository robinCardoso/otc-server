-- OTCv8 game_shop — extended opcode 201 (JSON)
--
-- ADICIONAR / EDITAR ITENS DA LOJA → função initShop() NESTE ARQUIVO (abaixo).
-- Não editar game_shop do cliente para novos produtos (só UI genérica).
-- Saldo: accounts.coins | Doc: docs/SHOP-MODULE.md + otcv8-dev/docs/SHOP-MODULE.md

local SHOP_EXTENDED_OPCODE = 201
local SHOP_CATEGORIES = nil
local SHOP_CALLBACKS = nil
local SHOP_BUY_URL = ""
local SHOP_AD = { image = "", url = "", text = "" }
local MAX_PACKET_SIZE = 60000
local STATUS_STORAGE = 1150001
local HISTORY_STORAGE = 1150002

-- Saldo da loja: coluna `coins` da conta (god tem 9999 em coins; premium_points é outro sistema)
local function getPoints(player)
	local resultId = db.storeQuery("SELECT `coins`, `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
	if not resultId then
		return 0
	end
	local coins = result.getNumber(resultId, "coins")
	result.free(resultId)
	return coins
end

local function getStatus(player)
	return {
		ad = SHOP_AD,
		points = getPoints(player),
		buyUrl = SHOP_BUY_URL
	}
end

local function sendJSON(player, action, data, forceStatus)
	local status = nil
	if forceStatus or player:getStorageValue(STATUS_STORAGE) < 1 or player:getStorageValue(STATUS_STORAGE) + 10 < os.time() then
		status = getStatus(player)
	end
	player:setStorageValue(STATUS_STORAGE, os.time())

	local buffer = json.encode({ action = action, data = data, status = status })
	local chunks = {}
	for i = 1, #buffer, MAX_PACKET_SIZE do
		chunks[#chunks + 1] = buffer:sub(i, i + MAX_PACKET_SIZE - 1)
	end

	if #chunks == 1 then
		return player:sendExtendedOpcode(SHOP_EXTENDED_OPCODE, chunks[1])
	end
	player:sendExtendedOpcode(SHOP_EXTENDED_OPCODE, "S" .. chunks[1])
	for i = 2, #chunks - 1 do
		player:sendExtendedOpcode(SHOP_EXTENDED_OPCODE, "P" .. chunks[i])
	end
	return player:sendExtendedOpcode(SHOP_EXTENDED_OPCODE, "E" .. chunks[#chunks])
end

local function sendMessage(player, title, msg, forceStatus)
	sendJSON(player, "message", { title = title, msg = msg }, forceStatus)
end

local function defaultItemBuyAction(player, offer)
	if player:addItem(offer.itemId, offer.count, false) then
		return true
	end
	return "Can't add item! Do you have enough space?"
end

local function addCategory(data)
	data.offers = {}
	table.insert(SHOP_CATEGORIES, data)
	table.insert(SHOP_CALLBACKS, {})
	local index = #SHOP_CATEGORIES
	return {
		addItem = function(cost, itemId, count, title, description, callback)
			if not callback then
				callback = defaultItemBuyAction
			end
			table.insert(SHOP_CATEGORIES[index].offers, {
				cost = cost,
				type = "item",
				item = ItemType(itemId):getClientId(),
				itemId = itemId,
				count = count,
				title = title,
				description = description
			})
			table.insert(SHOP_CALLBACKS[index], callback)
		end
	}
end

local function initShop()
	SHOP_CATEGORIES = {}
	SHOP_CALLBACKS = {}

	local items = addCategory({
		type = "item",
		item = ItemType(2160):getClientId(),
		count = 1,
		name = "Items"
	})
	items.addItem(5, 2148, 100, "100 gold coins", "Pacote de gold para teste.")
	items.addItem(10, 2466, 1, "Golden armor", "Armadura dourada (exemplo).")
	items.addItem(3, 2382, 1, "Club", "Arma simples para teste.")
end

local function processBuy(player, data)
	local categoryId = tonumber(data.category)
	local offerId = tonumber(data.offer)
	if not categoryId or not offerId then
		return sendMessage(player, "Error!", "Invalid offer")
	end

	local category = SHOP_CATEGORIES[categoryId]
	if not category then
		return sendMessage(player, "Error!", "Invalid category")
	end

	local offer = category.offers[offerId]
	local callback = SHOP_CALLBACKS[categoryId][offerId]
	if not offer or not callback or data.title ~= offer.title or data.cost ~= offer.cost then
		sendJSON(player, "categories", SHOP_CATEGORIES)
		return sendMessage(player, "Error!", "Invalid offer")
	end

	local points = getPoints(player)
	if offer.cost > points then
		return sendMessage(player, "Error!", "You don't have enough points.", true)
	end

	local status = callback(player, offer)
	if status == true then
		db.query("UPDATE `accounts` SET `coins` = `coins` - " .. offer.cost .. " WHERE `id` = " .. player:getAccountId())
		return sendMessage(player, "Success!", "You bought " .. offer.title .. "!", true)
	end
	sendMessage(player, "Error!", status or "Purchase failed")
end

local function sendHistory(player)
	if player:getStorageValue(HISTORY_STORAGE) > 0 and player:getStorageValue(HISTORY_STORAGE) + 10 > os.time() then
		return
	end
	player:setStorageValue(HISTORY_STORAGE, os.time())

	local history = {}
	local resultId = db.storeQuery("SELECT * FROM `shop_history` WHERE `account` = " .. player:getAccountId() .. " ORDER BY `id` DESC LIMIT 50")
	if resultId then
		repeat
			local details = result.getString(resultId, "details")
			local ok, entry = pcall(function() return json.decode(details) end)
			if not ok then
				entry = {
					type = "image",
					title = result.getString(resultId, "title"),
					cost = result.getNumber(resultId, "cost")
				}
			end
			entry.description = "Bought on " .. result.getString(resultId, "date") .. " for " .. result.getNumber(resultId, "cost") .. " points."
			table.insert(history, entry)
		until not result.next(resultId)
		result.free(resultId)
	end
	sendJSON(player, "history", history)
end

function onExtendedOpcode(player, opcode, buffer)
	if opcode ~= SHOP_EXTENDED_OPCODE then
		return false
	end

	local ok, jsonData = pcall(function() return json.decode(buffer) end)
	if not ok or type(jsonData) ~= "table" then
		return false
	end

	local action = jsonData.action
	local data = jsonData.data
	if type(action) ~= "string" then
		return false
	end
	if data == nil then
		data = {}
	end

	if not SHOP_CATEGORIES then
		initShop()
	end

	if action == "init" then
		sendJSON(player, "categories", SHOP_CATEGORIES, true)
	elseif action == "buy" then
		processBuy(player, data)
	elseif action == "history" then
		sendHistory(player)
	end
	return true
end
