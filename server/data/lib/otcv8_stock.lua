-- OTCv8 depot stock (opcode 205)
-- Doc: docs/STOCK-MODULE.md

Otcv8Stock = {
	OPCODE = 205,
	MAX_PACKET_SIZE = 60000,
	REQUIRE_PZ = false,
	BLOCK_PK_SKULL = true,
	PK_BLOCK_MESSAGE = "Voce nao pode usar o estoque com skull de PK.",
}

local function getDepotBoxCount()
	return configManager.getNumber("depotBoxes")
end

-- TFS 8.60: ItemType nao expoe getWorth(); moedas/gemas por id
local VALUABLE_ITEM_IDS = {
	[2148] = true, -- gold coin
	[2152] = true, -- platinum coin
	[2160] = true, -- crystal coin
	[2146] = true, [2147] = true, [2149] = true, [2150] = true, -- small gems
	[2155] = true, [2156] = true, [2157] = true, [2158] = true,
	[2159] = true, [2161] = true, [2162] = true, [2163] = true,
	[2177] = true, [2179] = true,
}

local FOOD_ITEM_IDS = nil

local function getFoodItemIds()
	if FOOD_ITEM_IDS then
		return FOOD_ITEM_IDS
	end
	FOOD_ITEM_IDS = {}
	local file = io.open("data/actions/scripts/others/consumables/food.lua", "r")
	if file then
		local content = file:read("*a")
		file:close()
		for id in content:gmatch("%[(%d+)%]%s*=%s*{") do
			FOOD_ITEM_IDS[tonumber(id)] = true
		end
	end
	return FOOD_ITEM_IDS
end

function Otcv8Stock.sendJSON(player, action, data)
	local buffer = json.encode({ action = action, data = data })
	local opcode = Otcv8Stock.OPCODE
	local chunks = {}
	for i = 1, #buffer, Otcv8Stock.MAX_PACKET_SIZE do
		chunks[#chunks + 1] = buffer:sub(i, i + Otcv8Stock.MAX_PACKET_SIZE - 1)
	end

	if #chunks == 1 then
		return player:sendExtendedOpcode(opcode, chunks[1])
	end
	player:sendExtendedOpcode(opcode, "S" .. chunks[1])
	for i = 2, #chunks - 1 do
		player:sendExtendedOpcode(opcode, "P" .. chunks[i])
	end
	return player:sendExtendedOpcode(opcode, "E" .. chunks[#chunks])
end

function Otcv8Stock.sendResult(player, ok, message, catalog)
	return Otcv8Stock.sendJSON(player, "result", {
		ok = ok,
		message = message or "",
		catalog = catalog,
	})
end

function Otcv8Stock.isPkLocked(player)
	if not Otcv8Stock.BLOCK_PK_SKULL or not player then
		return false
	end
	return player:getSkull() >= SKULL_WHITE
end

function Otcv8Stock.canView(player)
	if not player then
		return false, "Jogador invalido."
	end
	if Otcv8Stock.REQUIRE_PZ then
		local tile = Tile(player:getPosition())
		if not tile or not tile:hasFlag(TILESTATE_PROTECTIONZONE) then
			return false, "Voce precisa estar em uma protection zone."
		end
	end
	return true
end

function Otcv8Stock.canModify(player)
	local ok, err = Otcv8Stock.canView(player)
	if not ok then
		return false, err
	end
	if Otcv8Stock.isPkLocked(player) then
		return false, Otcv8Stock.PK_BLOCK_MESSAGE
	end
	return true
end

-- compat: scripts antigos
function Otcv8Stock.canUse(player)
	return Otcv8Stock.canModify(player)
end

function Otcv8Stock.isValidItem(item)
	if not item then
		return false
	end
	local ok, parent = pcall(function() return item:getParent() end)
	return ok and parent ~= nil
end

function Otcv8Stock.getCategory(itemId)
	local itemType = ItemType(itemId)
	if not itemType then
		return "other"
	end
	if itemType:isRune() then
		return "runes"
	end
	if itemType:isFluidContainer() or getFoodItemIds()[itemId] then
		return "food"
	end
	if itemType:isContainer() then
		return "containers"
	end
	if VALUABLE_ITEM_IDS[itemId] then
		return "valuables"
	end
	local ok, slot = pcall(function() return itemType:getSlotPosition() end)
	if ok and slot and slot > 0 then
		return "equipment"
	end
	return "other"
end

function Otcv8Stock.getContainerByPath(root, path)
	if not root or not root:isContainer() then
		return nil
	end
	local container = root
	if not path or #path == 0 then
		return container
	end
	for _, idx in ipairs(path) do
		idx = tonumber(idx)
		if idx == nil then
			return nil
		end
		local sub = container:getItem(idx)
		if not sub or not sub:isContainer() then
			return nil
		end
		container = sub
	end
	return container
end

function Otcv8Stock.resolvePlayerItem(player, data)
	if not player or not data then
		return nil
	end
	local invSlot = tonumber(data.invSlot or data.slot)
	if not invSlot then
		return nil
	end
	local itemId = tonumber(data.itemId)

	if invSlot >= CONST_SLOT_HEAD and invSlot <= CONST_SLOT_AMMO and invSlot ~= CONST_SLOT_BACKPACK then
		local item = player:getSlotItem(invSlot)
		if item and (not itemId or item:getId() == itemId) then
			return item
		end
		return nil
	end

	if invSlot == CONST_SLOT_BACKPACK then
		local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
		if not backpack then
			return nil
		end
		local container = Otcv8Stock.getContainerByPath(backpack, data.path or {})
		if not container then
			return nil
		end
		local index = tonumber(data.index)
		if index == nil then
			return nil
		end
		local item = container:getItem(index)
		if item and (not itemId or item:getId() == itemId) then
			return item
		end
	end
	return nil
end

function Otcv8Stock.resolveDepotItem(player, data)
	if not player or not data then
		return nil
	end
	local box = tonumber(data.depotBox)
	local index = tonumber(data.index)
	if not box or index == nil then
		return nil
	end
	local chest = player:getDepotChest(box, false)
	if not chest then
		return nil
	end
	local container = Otcv8Stock.getContainerByPath(chest, data.path or {})
	if not container then
		return nil
	end
	local itemId = tonumber(data.itemId)
	local item = container:getItem(index)
	if item and (not itemId or item:getId() == itemId) then
		return item
	end
	return nil
end

function Otcv8Stock.isItemInsideContainer(item, container)
	if not item or not container then
		return false
	end
	local current = item
	while current do
		if current == container then
			return true
		end
		local parent = current:getParent()
		if not parent then
			break
		end
		if parent == container then
			return true
		end
		if parent.isItem and parent:isItem() then
			current = parent
		else
			break
		end
	end
	return false
end

function Otcv8Stock.getDepotBoxForItem(player, item)
	if not Otcv8Stock.isValidItem(item) then
		return nil
	end
	for box = 1, getDepotBoxCount() do
		local chest = player:getDepotChest(box, false)
		if chest and Otcv8Stock.isItemInsideContainer(item, chest) then
			return box
		end
	end
	return nil
end

function Otcv8Stock.isItemInPlayerDepot(player, item)
	return Otcv8Stock.getDepotBoxForItem(player, item) ~= nil
end

function Otcv8Stock.isItemInPlayerInventory(player, item)
	if not Otcv8Stock.isValidItem(item) then
		return false
	end
	if item:getTopParent() == player then
		return true
	end
	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not backpack or not backpack:isContainer() then
		return false
	end
	local current = item
	while current do
		if current == backpack then
			return true
		end
		local parent = current:getParent()
		if not parent then
			break
		end
		if parent.isItem and parent:isItem() then
			current = parent
		else
			break
		end
	end
	return false
end

function Otcv8Stock.collectFromContainer(container, depotBox, items, path)
	path = path or {}
	for i = 0, container:getSize() - 1 do
		local item = container:getItem(i)
		if item then
			local itemId = item:getId()
			local itemType = ItemType(itemId)
			items[#items + 1] = {
				itemId = itemId,
				clientId = itemType and itemType:getClientId() or itemId,
				count = item:getCount(),
				name = item:getName(),
				depotBox = depotBox,
				path = path,
				index = i,
				category = Otcv8Stock.getCategory(itemId),
			}
			if item:isContainer() then
				local childPath = {}
				for _, idx in ipairs(path) do
					childPath[#childPath + 1] = idx
				end
				childPath[#childPath + 1] = i
				Otcv8Stock.collectFromContainer(item, depotBox, items, childPath)
			end
		end
	end
end

function Otcv8Stock.buildPlayerSlots(player)
	local slots = {}
	for slot = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
		local item = player:getSlotItem(slot)
		if item then
			local itemId = item:getId()
			local itemType = ItemType(itemId)
			slots[#slots + 1] = {
				itemId = itemId,
				clientId = itemType and itemType:getClientId() or itemId,
				count = item:getCount(),
				name = item:getName(),
				invSlot = slot,
				category = Otcv8Stock.getCategory(itemId),
			}
		end
	end

	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	if backpack and backpack:isContainer() then
		local function collectBp(container, path)
			path = path or {}
			for i = 0, container:getSize() - 1 do
				local item = container:getItem(i)
				if item then
					local itemId = item:getId()
					local itemType = ItemType(itemId)
					slots[#slots + 1] = {
						itemId = itemId,
						clientId = itemType and itemType:getClientId() or itemId,
						count = item:getCount(),
						name = item:getName(),
						invSlot = CONST_SLOT_BACKPACK,
						path = path,
						index = i,
						category = Otcv8Stock.getCategory(itemId),
					}
					if item:isContainer() then
						local childPath = {}
						for _, idx in ipairs(path) do
							childPath[#childPath + 1] = idx
						end
						childPath[#childPath + 1] = i
						collectBp(item, childPath)
					end
				end
			end
		end
		collectBp(backpack)
	end
	return slots
end

local function sortItems(items, mode)
	mode = mode or "name"
	table.sort(items, function(a, b)
		if mode == "id" then
			if a.itemId == b.itemId then
				return (a.name or "") < (b.name or "")
			end
			return a.itemId < b.itemId
		elseif mode == "count" then
			if a.count == b.count then
				return (a.name or "") < (b.name or "")
			end
			return a.count > b.count
		end
		local na, nb = (a.name or ""):lower(), (b.name or ""):lower()
		if na == nb then
			return a.itemId < b.itemId
		end
		return na < nb
	end)
end

function Otcv8Stock.buildCatalog(player, options)
	options = options or {}
	local items = {}
	local totalCount = 0

	for box = 1, getDepotBoxCount() do
		local chest = player:getDepotChest(box, false)
		if chest then
			Otcv8Stock.collectFromContainer(chest, box, items)
		end
	end

	for _, entry in ipairs(items) do
		totalCount = totalCount + entry.count
	end

	local filter = options.filter
	if filter and filter ~= "" and filter ~= "all" then
		local filtered = {}
		for _, entry in ipairs(items) do
			if entry.category == filter then
				filtered[#filtered + 1] = entry
			end
		end
		items = filtered
	end

	local search = options.search
	if search and search ~= "" then
		search = search:lower()
		local filtered = {}
		for _, entry in ipairs(items) do
			if (entry.name or ""):lower():find(search, 1, true) then
				filtered[#filtered + 1] = entry
			end
		end
		items = filtered
	end

	sortItems(items, options.sort)

	local distinct = {}
	for _, entry in ipairs(items) do
		distinct[entry.clientId] = true
	end
	local distinctCount = 0
	for _ in pairs(distinct) do
		distinctCount = distinctCount + 1
	end

	local readOnly = Otcv8Stock.isPkLocked(player)
	return {
		items = items,
		summary = {
			slots = #items,
			distinct = distinctCount,
			totalCount = totalCount,
			depotLimit = player:getGroup() and player:getGroup():getMaxDepotItems() or configManager.getNumber("freeDepotLimit"),
		},
		playerSlots = Otcv8Stock.buildPlayerSlots(player),
		readOnly = readOnly,
		blockReason = readOnly and Otcv8Stock.PK_BLOCK_MESSAGE or "",
	}
end

function Otcv8Stock.sendCatalog(player, options)
	return Otcv8Stock.sendJSON(player, "catalog", Otcv8Stock.buildCatalog(player, options))
end

function Otcv8Stock.findFirstDepotChestWithSpace(player)
	for box = 1, getDepotBoxCount() do
		local chest = player:getDepotChest(box, true)
		if chest and chest:getEmptySlots(true) > 0 then
			return chest
		end
	end
	return nil
end

local DEPOT_MAX_STACK = 100

function Otcv8Stock.findDepotTargetForItem(player, item)
	if not item then
		return nil
	end
	local itemId = item:getId()
	local itemType = ItemType(itemId)
	if not itemType then
		return nil
	end

	local mergeChest, mergeRoom = nil, 0
	local emptyChest = nil

	for box = 1, getDepotBoxCount() do
		local chest = player:getDepotChest(box, false)
		if not chest then
			chest = player:getDepotChest(box, true)
		end
		if chest then
			if itemType:isStackable() then
				for i = 0, chest:getSize() - 1 do
					local stack = chest:getItem(i)
					if stack and stack:getId() == itemId then
						local room = DEPOT_MAX_STACK - stack:getCount()
						if room > mergeRoom then
							mergeRoom = room
							mergeChest = chest
						end
					end
				end
			end

			if not emptyChest and chest:getEmptySlots(true) > 0 then
				emptyChest = chest
			end
		end
	end

	if mergeRoom > 0 and mergeChest then
		return mergeChest
	end
	return emptyChest
end

function Otcv8Stock.depositToDepot(player, item, count)
	if not Otcv8Stock.isValidItem(item) then
		return false, "Item nao encontrado."
	end

	count = math.max(1, math.min(tonumber(count) or 1, item:getCount()))
	local movedTotal = 0

	while movedTotal < count do
		if not Otcv8Stock.isValidItem(item) then
			break
		end

		local chest = Otcv8Stock.findDepotTargetForItem(player, item)
		if not chest then
			if movedTotal > 0 then
				return true
			end
			return false, "Seu depot esta cheio."
		end

		local batch = count - movedTotal
		local itemType = ItemType(item:getId())
		if itemType and itemType:isStackable() then
			local room = 0
			for i = 0, chest:getSize() - 1 do
				local stack = chest:getItem(i)
				if stack and stack:getId() == item:getId() then
					room = math.max(room, DEPOT_MAX_STACK - stack:getCount())
				end
			end
			if room > 0 then
				batch = math.min(batch, room)
			end
		end

		if not Otcv8Stock.moveCountToCylinder(item, chest, batch) then
			print(string.format("[Otcv8Stock] depositToDepot move failed: player=%s itemId=%d batch=%d movedSoFar=%d",
				player:getName(), item:getId(), batch, movedTotal))
			if movedTotal > 0 then
				return true
			end
			return false, "Nao foi possivel depositar o item."
		end

		movedTotal = movedTotal + batch
	end

	if movedTotal > 0 then
		return true
	end
	return false, "Nao foi possivel depositar o item."
end

function Otcv8Stock.getPlayerBackpack(player)
	if not player then
		return nil
	end
	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	if backpack and backpack:isContainer() then
		return backpack
	end
	return nil
end

function Otcv8Stock.playerHasFreeEquipSlot(player, itemId)
	local itemType = ItemType(itemId)
	if not itemType or type(itemType.usesSlot) ~= "function" then
		return false
	end
	for slot = CONST_SLOT_HEAD, CONST_SLOT_AMMO do
		if itemType:usesSlot(slot) and not player:getSlotItem(slot) then
			return true
		end
	end
	return false
end

function Otcv8Stock.backpackHasRoomForItem(backpack, item)
	if not backpack or not item or not backpack:isContainer() then
		return false
	end
	local itemId = item:getId()
	local itemType = ItemType(itemId)

	local function containerHasRoom(container, depth)
		if not container or not container:isContainer() then
			return false
		end
		depth = depth or 0
		if depth > 16 then
			return false
		end

		local empty = 0
		if type(container.getEmptySlots) == "function" then
			empty = container:getEmptySlots(true) or 0
			if empty == 0 then
				empty = container:getEmptySlots(false) or 0
			end
		end
		if empty == 0 and type(container.getCapacity) == "function" and type(container.getSize) == "function" then
			empty = container:getCapacity() - container:getSize()
		end

		if empty > 0 then
			return true
		end

		if itemType and itemType:isStackable() then
			for i = 0, container:getSize() - 1 do
				local stack = container:getItem(i)
				if stack and stack:getId() == itemId and stack:getCount() < 100 then
					return true
				end
			end
		end

		for i = 0, container:getSize() - 1 do
			local child = container:getItem(i)
			if child and child:isContainer() and containerHasRoom(child, depth + 1) then
				return true
			end
		end
		return false
	end

	return containerHasRoom(backpack, 0)
end

function Otcv8Stock.collectWithdrawTargets(player)
	local targets = {}
	local seen = {}

	local function addTarget(cylinder)
		if cylinder and not seen[cylinder] then
			seen[cylinder] = true
			targets[#targets + 1] = cylinder
		end
	end

	local function scanContainer(container)
		if not container or not container.isContainer or not container:isContainer() then
			return
		end
		addTarget(container)
		for i = 0, container:getSize() - 1 do
			local child = container:getItem(i)
			if child and child:isContainer() then
				scanContainer(child)
			end
		end
	end

	local backpack = Otcv8Stock.getPlayerBackpack(player)
	if backpack then
		scanContainer(backpack)
	end
	return targets
end

function Otcv8Stock.hasInventorySpaceFor(player, item, count)
	if not player or not item then
		return false, "Item invalido."
	end
	count = math.max(1, tonumber(count) or 1)
	local backpack = Otcv8Stock.getPlayerBackpack(player)
	if not backpack then
		return false, "Equipe uma mochila para retirar itens."
	end
	local itemType = ItemType(item:getId())
	if not itemType then
		return false, "Item invalido."
	end
	if player:getFreeCapacity() < itemType:getWeight(count) then
		return false, "Capacidade insuficiente."
	end
	if Otcv8Stock.playerHasFreeEquipSlot(player, item:getId()) then
		return true
	end
	if not Otcv8Stock.backpackHasRoomForItem(backpack, item) then
		return false, "Mochila cheia."
	end
	return true
end

function Otcv8Stock.isInventoryOnlyItem(itemId)
	local itemType = ItemType(itemId)
	if not itemType then
		return true
	end
	local wt = itemType:getWeaponType()
	if wt and wt ~= WEAPON_NONE then
		return false
	end
	local ok, slotPos = pcall(function()
		return itemType:getSlotPosition()
	end)
	if ok and slotPos and slotPos > 0 then
		return false
	end
	return true
end

function Otcv8Stock.tryCreateItemsInCylinder(cylinder, itemId, amount)
	if not cylinder or not itemId or amount < 1 then
		return false
	end
	-- Nunca player:addItem direto — moedas iam para mao se slot vazio (queryAdd antigo)
	if cylinder.isContainer and cylinder:isContainer() and cylinder.addItem then
		local added = cylinder:addItem(itemId, amount)
		return added ~= nil and added ~= false
	end
	return false
end

function Otcv8Stock.moveCountToCylinder(item, cylinder, count)
	if not Otcv8Stock.isValidItem(item) or not cylinder then
		return false
	end
	local want = tonumber(count)
	if not want or want < 1 then
		want = 1
	end
	want = math.min(want, item:getCount())
	local itemId = item:getId()

	local function transferMovingItem(movingItem, amount)
		if not Otcv8Stock.isValidItem(movingItem) then
			return false
		end
		if movingItem:moveTo(cylinder) then
			return true
		end
		if Otcv8Stock.tryCreateItemsInCylinder(cylinder, itemId, amount) then
			movingItem:remove(amount)
			return true
		end
		return false
	end

	if want >= item:getCount() then
		return transferMovingItem(item, want)
	end

	local splitItem = item:split(want)
	if not splitItem then
		return false
	end
	return transferMovingItem(splitItem, want)
end

function Otcv8Stock.withdrawToPlayer(player, item, count)
	local okSpace, spaceErr = Otcv8Stock.hasInventorySpaceFor(player, item, count)
	if not okSpace then
		return false, spaceErr
	end

	for _, target in ipairs(Otcv8Stock.collectWithdrawTargets(player)) do
		if Otcv8Stock.moveCountToCylinder(item, target, count) then
			return true
		end
	end

	-- Ultimo recurso: criar dentro da mochila (nunca equipar moeda/runa solta na mao)
	local want = math.max(1, math.min(tonumber(count) or 1, item:getCount()))
	local backpack = Otcv8Stock.getPlayerBackpack(player)
	if backpack and Otcv8Stock.tryCreateItemsInCylinder(backpack, item:getId(), want) then
		item:remove(want)
		return true
	end

	return false, "Nao foi possivel mover o item para o inventario."
end

function Otcv8Stock.handleRequest(player, data)
	local ok, err = Otcv8Stock.canView(player)
	if not ok then
		return Otcv8Stock.sendResult(player, false, err)
	end
	return Otcv8Stock.sendCatalog(player, data or {})
end

function Otcv8Stock.handleWithdraw(player, data)
	local ok, err = Otcv8Stock.canModify(player)
	if not ok then
		return Otcv8Stock.sendResult(player, false, err)
	end

	local item = Otcv8Stock.resolveDepotItem(player, data)
	if not item then
		return Otcv8Stock.sendResult(player, false, "Item nao encontrado.")
	end
	if not Otcv8Stock.isItemInPlayerDepot(player, item) then
		return Otcv8Stock.sendResult(player, false, "Item nao esta no seu depot.")
	end

	local count = math.max(1, math.min(tonumber(data and data.count) or 1, item:getCount()))
	local withdrawn, withdrawErr = Otcv8Stock.withdrawToPlayer(player, item, count)
	if not withdrawn then
		return Otcv8Stock.sendResult(player, false, withdrawErr or "Nao foi possivel retirar o item.")
	end

	local catalog = Otcv8Stock.buildCatalog(player, {})
	return Otcv8Stock.sendResult(player, true, "", catalog)
end

function Otcv8Stock.handleDeposit(player, data)
	local ok, err = Otcv8Stock.canModify(player)
	if not ok then
		return Otcv8Stock.sendResult(player, false, err)
	end

	local count = data and tonumber(data.count) or 1
	local item = Otcv8Stock.resolvePlayerItem(player, data)
	if not item then
		return Otcv8Stock.sendResult(player, false, "Item nao encontrado.")
	end
	if not Otcv8Stock.isItemInPlayerInventory(player, item) then
		return Otcv8Stock.sendResult(player, false, "Item nao esta no seu inventario.")
	end

	local deposited, depositErr = Otcv8Stock.depositToDepot(player, item, count)
	if not deposited then
		return Otcv8Stock.sendResult(player, false, depositErr or "Nao foi possivel depositar o item.")
	end

	local catalog = Otcv8Stock.buildCatalog(player, {})
	return Otcv8Stock.sendResult(player, true, "", catalog)
end

function Otcv8Stock.handleDepositAll(player)
	local ok, err = Otcv8Stock.canModify(player)
	if not ok then
		return Otcv8Stock.sendResult(player, false, err)
	end

	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not backpack or not backpack:isContainer() then
		return Otcv8Stock.sendResult(player, false, "Sem mochila.")
	end

	local moved = 0
	local failed = 0
	local function tryDepositFrom(container)
		for i = container:getSize() - 1, 0, -1 do
			local item = container:getItem(i)
			if item and Otcv8Stock.isValidItem(item) then
				if item:isContainer() then
					tryDepositFrom(item)
				end
				if Otcv8Stock.isValidItem(item) then
					local deposited, depositErr = Otcv8Stock.depositToDepot(player, item, item:getCount())
					if deposited then
						moved = moved + 1
					else
						failed = failed + 1
						print(string.format("[Otcv8Stock] depositAll skip: player=%s itemId=%d err=%s",
							player:getName(), item:getId(), tostring(depositErr or "unknown")))
					end
				end
			end
		end
	end
	tryDepositFrom(backpack)

	if moved == 0 then
		local msg = failed > 0 and "Nenhum item depositado (depot cheio?)." or "Nada para depositar."
		return Otcv8Stock.sendResult(player, false, msg)
	end

	local catalog = Otcv8Stock.buildCatalog(player, {})
	local msg = "Depositados " .. moved .. " item(ns)."
	if failed > 0 then
		msg = msg .. " (" .. failed .. " falharam.)"
	end
	return Otcv8Stock.sendResult(player, true, msg, catalog)
end

function Otcv8Stock.handleSort(player, data)
	local ok, err = Otcv8Stock.canView(player)
	if not ok then
		return Otcv8Stock.sendResult(player, false, err)
	end
	return Otcv8Stock.sendCatalog(player, { sort = (data and data.mode) or "name" })
end

function Otcv8Stock.handleAction(player, action, data)
	if action == "request" then
		return Otcv8Stock.handleRequest(player, data)
	elseif action == "withdraw" then
		return Otcv8Stock.handleWithdraw(player, data)
	elseif action == "deposit" then
		return Otcv8Stock.handleDeposit(player, data)
	elseif action == "depositAll" then
		return Otcv8Stock.handleDepositAll(player)
	elseif action == "sort" then
		return Otcv8Stock.handleSort(player, data)
	end
	return Otcv8Stock.sendResult(player, false, "Acao desconhecida.")
end
