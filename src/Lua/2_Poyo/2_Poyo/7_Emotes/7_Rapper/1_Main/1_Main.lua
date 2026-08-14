local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

PoyoPennynickel.FNF = {}

local S_PLAY_POYO_FNF = freeslot("S_PLAY_POYO_FNF")
local MATCHMAKE_DISTANCE = 512*FU

states[S_PLAY_POYO_FNF] = {
	sprite = SPR_PLAY,
	frame = SPR2_DEAD,
	tics = -1,
	action = PoyoPennynickel.EmoteAction,
	nextstate = S_PLAY_STND
}

table.insert(Class.emotes, PoyoPennynickel.FNF)

local function returnClosestPlayer(mo)
	local player
	local dist = INT32_MAX

	searchBlockmap("objects", function(_, mobj)
		if not mobj.valid then return end
		if not mobj.health then return end
		if mobj.type ~= MT_PLAYER then return end
		if not mobj.player then return end
		if mobj == mo then return end
		if not PoyoPennynickel.FNF:PlayerIsValid(mobj.player) then return end
		if PoyoPennynickel.FNF:PlayerIsInRapBattle(mobj.player) then return end

		local playerDist = R_PointToDist2(mo.x, mo.y, mobj.x, mobj.y)
		if playerDist > dist then return end

		player = mobj.player
		dist = playerDist
	end,
	mo,
	mo.x - MATCHMAKE_DISTANCE,
	mo.x + MATCHMAKE_DISTANCE,
	mo.y - MATCHMAKE_DISTANCE,
	mo.y + MATCHMAKE_DISTANCE)

	return player, dist
end

-- LOGIC
PoyoPennynickel.FNF.name = "Rap Battle"
PoyoPennynickel.FNF.use = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	mo.state = S_PLAY_POYO_FNF

	local found = returnClosestPlayer(mo)
	if not found then return end

	PoyoPennynickel.FNF:StartRapBattle(player, found, 1)
end
PoyoPennynickel.FNF.update = function(player, active) end
PoyoPennynickel.FNF.active = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	return mo.state == S_PLAY_POYO_FNF
end
PoyoPennynickel.FNF.finish = function(player, pressed_emote_button)
	local result, match, side = PoyoPennynickel.FNF:PlayerIsInRapBattle(consoleplayer)
	if not result then return end

	match.players[side] = nil
	if player == consoleplayer then
		self:ResetClientRapBattle()
	end
end