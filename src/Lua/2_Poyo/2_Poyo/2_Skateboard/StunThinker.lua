local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

Class.skateboardStunMoveFactor = FU / 2

local S_PLAY_POYO_SKATEBOARD_STUN = freeslot("S_PLAY_POYO_SKATEBOARD_STUN")

states[S_PLAY_POYO_SKATEBOARD_STUN] = {
	sprite = SPR_PLAY,
	frame = SPR2_DEAD,
	tics = -1,
	action = function(mo)
		if not mo then return end
		if not mo.valid then return end
		if not mo.player then return end

		mo.player.panim = PA_SPRING
	end
}

function Class:doSkateboardStun(board)
	self.mo.state = S_PLAY_POYO_SKATEBOARD_STUN
	self.mo.momz = board.momz

	self.mo.player.pflags = $ & ~(PF_JUMPED|PF_THOKKED|PF_STARTJUMP)
end

PoyoPennynickel:addScript("PlayerUpdate", function(player)
	local mo = player.mo
	local class = player.mo.poyoChar

	if mo.state == S_PLAY_POYO_SKATEBOARD_STUN then
		mo.movefactor = class.skateboardStunMoveFactor
	end
end)