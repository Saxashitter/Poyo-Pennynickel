local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local emote = {}

local sfx_py_bel = freeslot("sfx_py_bel")
local S_PLAY_POYO_EYES = freeslot("S_PLAY_POYO_EYES")

sfxinfo[sfx_py_omg].caption = "OOH"
states[S_PLAY_POYO_EYES] = {
	sprite = SPR_PLAY,
	frame = SPR2_TAL4,
	tics = -1,
	action = PoyoPennynickel.EmoteAction,
	nextstate = S_PLAY_STND
}

table.insert(Class.emotes, emote)

-- LOGIC
emote.name = "Eyes"
emote.use = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	mo.state = S_PLAY_POYO_EYES
	S_StartSound(mo, sfx_py_bel)
end
emote.update = function(player, active) end
emote.active = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	return mo.state == S_PLAY_POYO_EYES
end
emote.finish = function(player) end