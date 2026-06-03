-- OTCv8 map viewport sync (extended opcode 206)
-- Doc: docs/VIEWPORT-MODULE.md

Otcv8Viewport = {
	OPCODE = 206,
}

function Otcv8Viewport.handleMode(player, mode)
	if type(mode) ~= "string" then
		return false
	end

	if mode ~= "classic" and mode ~= "wide" then
		return false
	end

	return player:setMapViewportMode(mode)
end
