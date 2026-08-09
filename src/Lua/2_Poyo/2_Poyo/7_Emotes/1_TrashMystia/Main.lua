local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local emote = {}

local sfx_psoboy = freeslot("sfx_psoboy")
local S_PLAY_POYO_TRASHMYSTIA = freeslot("S_PLAY_POYO_TRASHMYSTIA")

sfxinfo[sfx_psoboy].caption = "trash mystia"
states[S_PLAY_POYO_TRASHMYSTIA] = {
	sprite = SPR_PLAY,
	frame = SPR2_CLMB,
	tics = 1,
	action = PoyoPennynickel.EmoteAction,
	nextstate = S_PLAY_POYO_TRASHMYSTIA
}

table.insert(Class.emotes, emote)

-- LOGIC
emote.name = "Trash Mystia"
emote.use = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	mo.state = S_PLAY_POYO_TRASHMYSTIA
	S_FadeMusic(0, 1000, player)
end
emote.update = function(player, active)
	local mo = player.mo
	local class = mo.poyoChar

	if active and not S_SoundPlaying(mo, sfx_psoboy) then
		S_StartSound(mo, sfx_psoboy)
	elseif not active then
		S_StopSoundByID(mo, sfx_psoboy)
	end
end
emote.active = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	return mo.state == S_PLAY_POYO_TRASHMYSTIA
end
emote.finish = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	S_FadeMusic(100, 1000, player)
end