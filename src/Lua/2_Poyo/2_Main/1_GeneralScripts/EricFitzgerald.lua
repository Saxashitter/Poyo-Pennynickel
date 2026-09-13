/*
	Saying "Eric Fitzgerald" in chat causes Poyo to slow turn to the camera. The music fades out, and then the game force quits.
*/

local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local LENGTH = 10 * TICRATE
local TURN_TIME = 5 * TICRATE
local SAY_TIME = 8 * TICRATE
local MUSIC_FADE_TIME = 3 * MUSICRATE
local FADE_BACK_TIME = MUSICRATE

local S_PLAY_POYO_UHOH = freeslot("S_PLAY_POYO_UHOH")

states[S_PLAY_POYO_UHOH] = {
	sprite = SPR_PLAY,
	frame = SPR2_STND,
	tics = -1, -- to check
	nextstate = S_PLAY_STND,
	action = function(mo)
		if not mo then return end
		if not mo.valid then return end
		if not mo.player then return end

		mo.player.panim = PA_IDLE
	end
}

-- t is fixed_t, 0 to FRACUNIT
local function LerpAngle(a, b, t)
    local diff = b - a -- wraps automatically to the shortest signed delta
    return a + FixedMul(diff, t)
end

Class.wasInQuitState = false
Class.quitAngle = 0
Class.quitLerp = 0

function Class:doQuitSequence()
	if self.mo.state == S_PLAY_POYO_UHOH and self.mo.player == consoleplayer then
		COM_BufInsertText(consoleplayer, "quit")
	end

	if P_IsObjectOnGround(self.mo) and self.mo.player.panim == PA_IDLE then
		self.mo.state = S_PLAY_POYO_UHOH
		self.quitAngle = self.mo.player.drawangle
		self.quitLerp = 0
		self.wasInQuitState = true
		S_FadeMusic(0, MUSIC_FADE_TIME, self.mo.player)
	end
end

addHook("PlayerMsg", function(source, type, target, msg)
	if type then return end
	if gamestate ~= GS_LEVEL then return end
	if not source then return end
	if not source.valid then return end
	if not source.mo then return end
	if not source.mo.valid then return end
	if not source.mo.poyoChar then return end

	msg = $:lower()
	if not msg:find("eric fitzgerald") then return end

	source.mo.poyoChar:doQuitSequence()
end)

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if mo.state == S_PLAY_POYO_UHOH then
		class.quitLerp = min(FU, $ + FU / TURN_TIME)
		player.drawangle = player.cmd.angleturn*FU + LerpAngle(0, ANGLE_180, class.quitLerp)
	elseif class.wasInQuitState and mo.state ~= S_PLAY_POYO_TRASHMYSTIA then
		S_FadeMusic(100, FADE_BACK_TIME, player)
	end
end)