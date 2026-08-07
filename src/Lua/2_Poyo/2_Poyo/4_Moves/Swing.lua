local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

/*
	If you are under Poyo’s running speed, or if you aren’t moving yourself,
	Poyo will swing left and right depending on how much you spam Spin.
	Your friction is divided by 2 while using this move, yet you can’t do
	anything other than jump out of it. Use this to conserve momentum.
	This attack is also able to reflect projectiles from in front of you.
*/

local S_PLAY_POYO_SWING = freeslot("S_PLAY_POYO_SWING")

local ANIMATION_LENGTH = D -- the animation length
local FRAME_START = A -- when the hitbox starts
local FRAME_SPAM = D -- the frame that you can attack again after
local FRICTION = FU -- the friction of this move while its active
local ANIMATION_TICS = 2 -- the tics of the animation
local ANIMATION_END_TICS = 8 -- the tics of the last frame of the animation
local ANIMATION_POWERS = STR_ATTACK|STR_WALL|STR_SPRING|STR_ANIM -- the animation's pw_powers flags
local ANIMATION_PANIM = PA_ABILITY -- the panim of the animation

local function animationAction(mo)
	if not mo.valid then return end
	if not mo.player then return end

	local frame = mo.frame & FF_FRAMEMASK

	mo.player.panim = ANIMATION_PANIM

	if frame >= FRAME_START then
		mo.player.powers[pw_strong] = ANIMATION_POWERS
	end

	if frame == ANIMATION_LENGTH then
		mo.tics = ANIMATION_END_TICS
	end
end

states[S_PLAY_POYO_SWING] = {
	sprite = SPR_PLAY,
	frame = SPR2_MLEE|FF_SPR2ENDSTATE,
	tics = ANIMATION_TICS,
	nextstate = S_PLAY_POYO_SWING,
	action = animationAction,
	var1 = S_PLAY_WALK
}

PoyoPennynickel:addScript("PlayerSpin", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if MM and MM:isMM() then return end
	if not P_IsObjectOnGround(mo) then return end
	if P_PlayerInPain(player) then return end
	if not mo.health then return end
	if player.pflags & PF_SPINDOWN then return end 
	if class.skateboard then return end

	if mo.state == S_PLAY_POYO_SWING then
		if mo.frame & FF_FRAMEMASK < FRAME_START then return end

		-- reset state...
		mo.state = S_PLAY_STND
	elseif class:canDashAggressiveAttack() then return end

	mo.state = S_PLAY_POYO_SWING
end)

PoyoPennynickel:addScript("PlayerMobjUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if mo.state == S_PLAY_POYO_SWING then
		mo.friction = FRICTION
	end
end)

PoyoPennynickel:addScript("PlayerKilled", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if mo.state == S_PLAY_POYO_SWING then
		mo.momx = $/2
		mo.momy = $/2
		
		mo.state = S_PLAY_WALK
	end
end)