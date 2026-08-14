local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local emote = {}

local sfx_py_mmx = freeslot("sfx_py_mmx")
local S_PLAY_POYO_OVA = freeslot("S_PLAY_POYO_OVA")

sfxinfo[sfx_py_mmx].caption = "Cool ass pose."
states[S_PLAY_POYO_OVA] = {
	sprite = SPR_PLAY,
	frame = SPR2_TAL3,
	tics = -1,
	action = PoyoPennynickel.EmoteAction
}

table.insert(Class.emotes, emote)

-- LOGIC
emote.name = "Poyo CD"
emote.use = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	mo.state = S_PLAY_POYO_OVA
	S_StartSound(mo, sfx_py_mmx)
end
emote.update = function(player, active) end
emote.active = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	return mo.state == S_PLAY_POYO_OVA
end
emote.finish = function(player) end