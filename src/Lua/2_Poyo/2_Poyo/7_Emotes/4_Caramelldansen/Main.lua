local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local emote = {}

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

		local sides = {}
		sides[1] = P_SpawnGhostMobj(mo)
		sides[2] = P_SpawnGhostMobj(mo)
		for k, v in ipairs(sides) do
			v.dispoffset = -1
			v.colorized = true
			v.color = SKINCOLOR_RED
			v.frame = $|FF_ADD
		end

		local speed = 8 * mo.scale
		P_InstaThrust(sides[1], mo.player.cmd.angleturn*FU + ANGLE_90, speed)
		P_InstaThrust(sides[2], mo.player.cmd.angleturn*FU - ANGLE_90, speed)
	end,
	nextstate = S_PLAY_POYO_CARAMELLDANSEN
}

table.insert(Class.emotes, emote)

-- LOGIC
emote.name = "Caramelldansen"
emote.use = function(player, variant)
	-- 0 == no variant btw

	local mo = player.mo
	local class = mo.poyoChar

	class.caramelldansenTicker = 0
	class.caramelldansenLastBeat = 0
	mo.state = S_PLAY_POYO_CARAMELLDANSEN

	S_ChangeMusic(emote.variants[variant].song, true, player)

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
	local bpm = emote.variants[class.emoteVariant].bpm -- * FRACUNIT / MUSICRATE

	if player == consoleplayer then
		if S_MusicName() ~= emote.variants[class.emoteVariant].song then
			S_ChangeMusic(emote.variants[class.emoteVariant].song, true)

			if S_GetMusicLength() ~= 0 then
				S_SetMusicPosition(mr_time % S_GetMusicLength())
			end
		elseif S_GetMusicLength() ~= 0 and abs(S_GetMusicPosition() - (mr_time % S_GetMusicLength())) >= 500 then
			S_SetMusicPosition(mr_time % S_GetMusicLength())
		end
	end

	local beat = FixedMul(time, (bpm / 60) * FU / MUSICRATE) -- (songPosition / 1000) * (self.bpm / 60)
	local int_beat = beat/FU

	if int_beat ~= class.caramelldansenLastBeat then
		local frame = mo.frame & FF_FRAMEMASK
		mo.state = S_PLAY_POYO_CARAMELLDANSEN
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

emote.variants = {
	[0] = {name = "Caramelldansen", bpm = 164735, song = "PY_CDN"},
	[1] = {name = "Spiritual Domination", bpm = 155766, song = "PY_TST"}
}