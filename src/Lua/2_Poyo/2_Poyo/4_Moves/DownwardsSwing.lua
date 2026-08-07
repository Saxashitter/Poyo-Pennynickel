/*
	Poyo puts his bat over his head, and aggressively swings it downwards.
	This launches him forward slightly, but it's hard cap is Poyo’s max speed.
	However, if you use it while above Poyo’s max speed, it doesn't slow
	you down. If you are aiming this attack over 45 degrees from your
	moving direction, Poyo’s attack will launch you towards where you're aiming,
	but not redirect your momentum, which should help you redirect.
	Think of it as rowing a boat. This move can only be used once mid-air,
	and after using it, it will disallow you from using your double jump ability
	until you land.
*/

local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local S_PLAY_POYO_DOWNWARDS_SWING = freeslot("S_PLAY_POYO_DOWNWARDS_SWING")

-- the angle in which the attack is done
Class.downwardsSwingAngle = 0

-- the time in which the player is moved forward
Class.downwardsSwingMove = 0

local ANIMATION_LENGTH = D -- the animation length
local FRAME_START = C -- when the hitbox starts
local ANIMATION_TICS = 3 -- the tics of the animation
local ANIMATION_END_TICS = 9 -- the tics of the last frame of the animation
local THRUST_SPEED = 25 * FU -- the speed that the player is launched after FRAME_START
local SEMI_THRUST_SPEED = 12 * FU -- used for direction correction... not sure how to explain but its an additional thrust
local THRUST_TIME = 20 -- the tics that speed remains for
local ANIMATION_POWERS = STR_ATTACK|STR_WALL|STR_FLOOR|STR_SPRING|STR_ANIM|STR_HEAVY -- the animation's pw_powers flags
local ANIMATION_PANIM = PA_ABILITY -- the panim of the animation

local function animationAction(mo)
	if not mo.valid then return end
	if not mo.player then return end

	local frame = mo.frame & FF_FRAMEMASK
	
	mo.player.panim = ANIMATION_PANIM

	if frame == A then -- start of animation
		mo.poyoChar.downwardsSwingMove = 0
		mo.poyoChar.downwardsSwingAngle = mo.angle

		mo.momx = $/2
		mo.momy = $/2
	end

	if frame == FRAME_START then
		mo.poyoChar.downwardsSwingMove = THRUST_TIME
		P_Thrust(mo, mo.poyoChar.downwardsSwingAngle, FixedMul(SEMI_THRUST_SPEED, mo.scale))
	end

	if frame >= FRAME_START then
		-- constantly apply
		mo.player.powers[pw_strong] = ANIMATION_POWERS
	end

	if frame == ANIMATION_LENGTH then
		mo.tics = ANIMATION_END_TICS
	end
end

states[S_PLAY_POYO_DOWNWARDS_SWING] = {
	sprite = SPR_PLAY,
	frame = SPR2_MLEE|FF_SPR2ENDSTATE,
	tics = ANIMATION_TICS,
	action = animationAction,
	var1 = S_PLAY_WALK,
	nextstate = S_PLAY_POYO_DOWNWARDS_SWING
}

PoyoPennynickel:addScript("PlayerSpin", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if MM and MM:isMM() then return end
	if P_IsObjectOnGround(mo) then return end
	if P_PlayerInPain(player) then return end
	if not mo.health then return end
	if player.pflags & PF_SPINDOWN then return end 
	if class.skateboard then return end
	-- if not class:canDashAggressiveAttack() then return end

	if mo.state == S_PLAY_POYO_DOWNWARDS_SWING then return end
-- 	if mo.state == S_PLAY_POYO_DASH_ATTACK then return end
-- 	if mo.state == S_PLAY_POYO_DASH_BOUNCE then return end
-- 	if mo.state == S_PLAY_POYO_UPPERCUT then return end
	if mo.state == S_PLAY_POYO_GRAPPLED then return end

	mo.state = S_PLAY_POYO_DOWNWARDS_SWING
end)

PoyoPennynickel:addScript("PlayerMobjUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if mo.state ~= S_PLAY_POYO_DOWNWARDS_SWING then return end
	local angle = class.downwardsSwingAngle
	player.drawangle = angle

	if class.downwardsSwingMove then
		local tics = class.downwardsSwingMove
		local t = FU - FixedDiv(class.downwardsSwingMove, THRUST_TIME)
		local speed = ease.outquart(t, FixedMul(THRUST_SPEED, mo.scale), 0)

		local omomx = mo.momx
		local omomy = mo.momy

		mo.momx = P_ReturnThrustX(nil, angle, speed)
		mo.momy = P_ReturnThrustY(nil, angle, speed)

		P_XYMovement(mo)

		if mo.state ~= S_PLAY_POYO_DOWNWARDS_SWING then return end
		if mo.eflags & MFE_SPRUNG then mo.state = S_PLAY_WALK return end

		mo.momx, mo.momy = omomx, omomy
		class.downwardsSwingMove = $ - 1
	end

	if mo.frame & FF_FRAMEMASK < ANIMATION_LENGTH then
		P_SetObjectMomZ(mo, -FU / 2, true)
	end
end)