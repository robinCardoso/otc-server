-- OTCv8 party status + minimap (extended opcode 204)

Otcv8Party = {
	OPCODE = 204,
	MAX_PACKET_SIZE = 60000,
}

-- Legado: tabela separada (NÃO usar Otcv8PartyMinimap = Otcv8Party — isso quebra Otcv8Party.send)
Otcv8PartyMinimap = {}

function Otcv8Party.sendJSON(player, action, data)
	local buffer = json.encode({ action = action, data = data })
	local opcode = Otcv8Party.OPCODE
	local chunks = {}
	for i = 1, #buffer, Otcv8Party.MAX_PACKET_SIZE do
		chunks[#chunks + 1] = buffer:sub(i, i + Otcv8Party.MAX_PACKET_SIZE - 1)
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

local function getBaseVocationId(memberPlayer)
	local vocation = memberPlayer:getVocation()
	if not vocation then
		return 0
	end
	local id = vocation:getId()
	if id >= 5 and id <= 8 then
		return id - 4
	end
	return id
end

function Otcv8Party.calcVocationBonusPercent(party)
	if not party then
		return 0
	end

	local vocationIds = {}
	local leader = party:getLeader()
	if leader then
		local baseId = getBaseVocationId(leader)
		if baseId > 0 then
			vocationIds[baseId] = true
		end
	end

	for _, member in ipairs(party:getMembers()) do
		local baseId = getBaseVocationId(member)
		if baseId > 0 then
			vocationIds[baseId] = true
		end
	end

	local size = 0
	for _ in pairs(vocationIds) do
		size = size + 1
	end

	local extraExpRate
	if size > 1 then
		extraExpRate = (size * (10 + (size - 1) * 5)) / 100
	else
		extraExpRate = 0.20
	end
	return math.floor(extraExpRate * 100 + 0.5)
end

function Otcv8Party.buildMemberEntry(memberPlayer, leaderPlayer)
	local pos = memberPlayer:getPosition()
	local vocation = memberPlayer:getVocation()
	return {
		name = memberPlayer:getName(),
		id = memberPlayer:getId(),
		level = memberPlayer:getLevel(),
		vocation = vocation and vocation:getId() or 0,
		hp = memberPlayer:getHealth(),
		maxHp = memberPlayer:getMaxHealth(),
		mana = memberPlayer:getMana(),
		maxMana = memberPlayer:getMaxMana(),
		x = pos and pos.x or 0,
		y = pos and pos.y or 0,
		z = pos and pos.z or 0,
		leader = leaderPlayer and memberPlayer:getId() == leaderPlayer:getId(),
	}
end

function Otcv8Party.buildStatus(player)
	local party = player:getParty()
	if not party then
		return {
			inParty = false,
			isLeader = false,
			sharedExpActive = false,
			sharedExpEnabled = false,
			vocationBonusPercent = 0,
			members = {},
			invites = {},
		}
	end

	local leader = party:getLeader()
	local members = {}
	local seen = {}

	local function addMember(memberPlayer)
		if not memberPlayer then
			return
		end
		local memberId = memberPlayer:getId()
		if seen[memberId] then
			return
		end
		seen[memberId] = true
		members[#members + 1] = Otcv8Party.buildMemberEntry(memberPlayer, leader)
	end

	addMember(leader)
	for _, member in ipairs(party:getMembers()) do
		addMember(member)
	end

	local invites = {}
	for _, invitee in ipairs(party:getInvitees()) do
		invites[#invites + 1] = {
			name = invitee:getName(),
			id = invitee:getId(),
		}
	end

	return {
		inParty = true,
		isLeader = leader and player:getId() == leader:getId(),
		sharedExpActive = party:isSharedExperienceActive(),
		sharedExpEnabled = party:isSharedExperienceEnabled(),
		vocationBonusPercent = Otcv8Party.calcVocationBonusPercent(party),
		members = members,
		invites = invites,
	}
end

function Otcv8Party.send(player)
	return Otcv8Party.sendJSON(player, "partyStatus", Otcv8Party.buildStatus(player))
end

function Otcv8Party.pushAll()
	if Game.getGameState() ~= GAME_STATE_NORMAL then
		return
	end
	for _, player in ipairs(Game.getPlayers()) do
		if player and player:getParty() then
			local ok, err = pcall(Otcv8Party.send, player)
			if not ok then
				print("[Otcv8Party] push error: " .. tostring(err))
			end
		end
	end
end

function Otcv8PartyMinimap.buildPositions(player)
	local status = Otcv8Party.buildStatus(player)
	return { members = status.members }
end

function Otcv8PartyMinimap.send(player)
	return Otcv8Party.send(player)
end

function Otcv8PartyMinimap.pushAll()
	return Otcv8Party.pushAll()
end
