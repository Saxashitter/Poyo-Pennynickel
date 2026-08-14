local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

PoyoPennynickel.FNF = {}

local S_PLAY_POYO_FNF = freeslot("S_PLAY_POYO_FNF")

states[S_PLAY_POYO_FNF] = {
	sprite = SPR_PLAY,
	frame = SPR2_DEAD,
	tics = -1,
	action = PoyoPennynickel.EmoteAction,
	nextstate = S_PLAY_STND
}

table.insert(Class.emotes, PoyoPennynickel.FNF)

-- LOGIC
PoyoPennynickel.FNF.name = "Rap Battle"
PoyoPennynickel.FNF.use = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	mo.state = S_PLAY_POYO_FNF
	PoyoPennynickel.FNF:StartRapBattle(player, nil, 1)
end
PoyoPennynickel.FNF.update = function(player, active) end
PoyoPennynickel.FNF.active = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	return mo.state == S_PLAY_POYO_FNF
end
PoyoPennynickel.FNF.finish = function(player) end