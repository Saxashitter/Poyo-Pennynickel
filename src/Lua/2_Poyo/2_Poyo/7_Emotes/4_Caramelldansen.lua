local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local emote = {}

-- doing this so we can modify it n shit
emote.bpm = 164735 -- 164 * FU + (735 * FU / 1000)
emote.song = "PY_CDN"

local S_PLAY_POYO_CARAMELLDANSEN = freeslot("S_PLAY_POYO_CARAMELLDANSEN")

local sfx_py_cdn = freeslot("sfx_py_cdn")
sfxinfo[sfx_py_cdn].caption = "look harry had a vagina malfunction"

states[S_PLAY_POYO_CARAMELLDANSEN] = {
	sprite = SPR_PLAY,
	frame = SPR2_BNCE,
	tics = 3,
	action = function(mo)
		PoyoPennynickel.EmoteAction(mo)

		if not mo then return end
		if not mo.valid then return end
		if not mo.player then return end

		local frame = mo.frame & FF_FRAMEMASK

		if frame == C or frame == F then
			mo.tics = -1
		end
		if frame == B or frame == E then
			mo.tics = 2
		end
	end,
	nextstate = S_PLAY_POYO_CARAMELLDANSEN
}

table.insert(Class.emotes, emote)

-- LOGIC
emote.name = "Caramelldansen"
emote.use = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	class.caramelldansenTicker = 0
	class.caramelldansenLastBeat = 0
	mo.state = S_PLAY_POYO_CARAMELLDANSEN

	S_ChangeMusic(emote.song, true)

-- 	S_StartSound(mo, sfx_py_omg)
end
emote.update = function(player, active)
	local mo = player.mo
	local class = mo.poyoChar

	if not active then return end

	class.caramelldansenTicker = $ + 1

	-- TODO: avoid FRACUNIT conversion entirely for bpm and all and just use MUSICRATE for optimization that we probably dont need but who gaf
	local mr_time = class.caramelldansenTicker * MUSICRATE / TICRATE
	local time = class.caramelldansenTicker * FRACUNIT / TICRATE
	local bpm = emote.bpm -- * FRACUNIT / MUSICRATE

	if S_MusicName() ~= "PY_CDN" then
		S_ChangeMusic("PY_CDN", true)

		if S_GetMusicLength() ~= 0 then
			S_SetMusicPosition(mr_time % S_GetMusicLength())
		end
	elseif S_GetMusicLength() ~= 0 and abs(S_GetMusicPosition() - (mr_time % S_GetMusicLength())) >= 500 then
		S_SetMusicPosition(mr_time % S_GetMusicLength())
	end

	local beat = FixedMul(time, (bpm / 60) * FU / MUSICRATE) -- (songPosition / 1000) * (self.bpm / 60)
	local int_beat = beat/FU

	if int_beat ~= class.caramelldansenLastBeat then
		local frame = mo.frame & FF_FRAMEMASK
		mo.frame = $ & ~FF_FRAMEMASK

		if frame <= C then
			mo.frame = $|D
		else
			mo.frame = $|A
		end

		mo.tics = states[mo.state].tics
	end
	class.caramelldansenLastBeat = int_beat	
end
emote.active = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	return mo.state == S_PLAY_POYO_CARAMELLDANSEN
end
emote.finish = function(player)
	S_ChangeMusic(mapmusname, true)
end