local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local emote = {}

local sfx_py_omg = freeslot("sfx_py_omg")
local S_PLAY_POYO_OOH = freeslot("S_PLAY_POYO_OOH")

sfxinfo[sfx_py_omg].caption = "OOH"
states[S_PLAY_POYO_OOH] = {
	sprite = SPR_PLAY,
	frame = SPR2_TAL1,
	tics = 17,
	action = PoyoPennynickel.EmoteAction,
	nextstate = S_PLAY_STND
}

table.insert(Class.emotes, emote)

-- LOGIC
emote.name = "Ooh"
emote.use = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	mo.state = S_PLAY_POYO_OOH
	S_StartSound(mo, sfx_py_omg)
end
emote.update = function(player, active) end
emote.active = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	return mo.state == S_PLAY_POYO_OOH
end
emote.finish = function(player) end