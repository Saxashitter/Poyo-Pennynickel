local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

/*
	If you are over Poyo’s running speed, and if you are moving, Poyo will
	get a tiny boost to swing his bat forward, which depletes quickly.
	This jump just so happens to boost your momentum by 1.1x, but doesn't
	keep it, so you should use this if you want to get a proper running start.
*/

-- AS OF RIGHT NOW THIS USES TWRL FROM CHARACTERS.PK3, BUT WILL BE CHANGED TO BE PROPER!!

-- players spins an entire 360 degrees based on where they attacked
Class.dashAttackDrawangle = 0

-- angle of the attack so we can thrust
Class.dashAttackAngle = 0

local S_PLAY_POYO_DASH_ATTACK = freeslot("S_PLAY_POYO_DASH_ATTACK")

local ANIMATION_LENGTH = 20 -- the animation length
local ANIMATION_POWERS = STR_ATTACK|STR_WALL|STR_SPRING|STR_ANIM|STR_SPIKE -- the animation's pw_powers flags
local ANIMATION_PANIM = PA_ABILITY -- the panim of the animation
local SPEED_START = 55 * FU -- the speed that poyo gets when the move starts
local JUMP_TICS = 15 -- how long air-transitioned last for

Class.airTransitionedDashAttack = false -- if we transitioned it to air

local function animationAction(mo)
	if not mo.valid then return end
	if not mo.player then return end

	local frame = mo.frame & FF_FRAMEMASK

	mo.poyoChar.dashAttackAngle = mo.angle
	mo.poyoChar.dashAttackDrawangle = mo.player.drawangle
	mo.player.panim = ANIMATION_PANIM
	mo.player.powers[pw_strong] = ANIMATION_POWERS
	mo.poyoChar.dashAttack = true
end

function Class:getDashAttackSpeedXY()
	local mo = self.mo

	local t = FU - FixedDiv(mo.tics, ANIMATION_LENGTH)
	local speed = ease.outquart(t, FixedMul(SPEED_START, mo.scale), 0)

	local attack_angle = self.dashAttackAngle

	local momx = P_ReturnThrustX(nil, attack_angle, speed)
	local momy = P_ReturnThrustY(nil, attack_angle, speed)

	return momx, momy
end

states[S_PLAY_POYO_DASH_ATTACK] = {
	sprite = SPR_PLAY,
	frame = SPR2_MLEL,
	tics = ANIMATION_LENGTH,
	nextstate = S_PLAY_WALK,
	action = animationAction
}

PoyoPennynickel:addScript("PlayerSpin", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if MM and MM:isMM() then return end
	if not P_IsObjectOnGround(mo) then return end
	if P_PlayerInPain(player) then return end
	if not mo.health then return end
	if class.skateboard then return end
	if not class:canDashAggressiveAttack() then return end

	if mo.state == S_PLAY_POYO_DASH_ATTACK then return end
	if mo.state == S_PLAY_POYO_SWING then return end

	class.airTransitionedDashAttack = false
	mo.state = S_PLAY_POYO_DASH_ATTACK
	local momx, momy = class:getDashAttackSpeedXY()
	local mo_speed = R_PointToDist2(0, 0, mo.momx, mo.momy)
	local dash_speed = R_PointToDist2(0, 0, momx, momy)

	local div = FU / 3
	mo.momx = FixedMul($, div)
	mo.momy = FixedMul($, div)
	P_Thrust(mo, mo.angle, 8 * mo.scale)

	S_StartSound(mo, sfx_s238)
-- 	S_StartSound(mo, sfx_s244)
end)

PoyoPennynickel:addScript("PlayerMobjUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if mo.state == S_PLAY_POYO_DASH_ATTACK then
		if not S_SoundPlaying(mo, sfx_s3k7d) then
			S_StartSoundAtVolume(mo, sfx_s3k7d, 100)
		end


		local t = FU - FixedDiv(mo.tics, ANIMATION_LENGTH)
		local fixed_angle = AngleFixed(class.dashAttackDrawangle)
		local angle = FixedAngle(ease.outexpo(t, fixed_angle, fixed_angle + (360 * FU) * 2))

		player.drawangle = angle

		-- thrust player forward
		local momx, momy = class:getDashAttackSpeedXY()
		local moving = momx or momy

		if moving and not class.airTransitionedDashAttack then
			local attack_angle = class.dashAttackAngle

			local omomx = mo.momx
			local omomy = mo.momy

			mo.momx = momx
			mo.momy = momy

			mo.flags = $|MF_BOUNCE
			P_XYMovement(mo)
			if mo and mo.valid then
				mo.flags = $ & ~MF_BOUNCE
			end

			if mo and mo.valid and mo.state == S_PLAY_POYO_DASH_ATTACK then
				-- set the new angle, in case of technical difficulties...
				class.dashAttackAngle = R_PointToAngle2(0, 0, mo.momx, mo.momy)
				mo.momx = omomx
				mo.momy = omomy
			end
		end

		if class.airTransitionedDashAttack then
			class.dashAttackAngle = $ + 30 * ANG1
			player.drawangle = class.dashAttackAngle
		end

-- 		if mo.momz * P_MobjFlip(mo) < -4 * mo.scale then
-- 			local momz = mo.momz * P_MobjFlip(mo)

-- 			momz = min(-4 * mo.scale, FixedDiv(momz, FU * 100 / 86))

-- 			P_SetObjectMomZ(mo, FixedDiv(momz, mo.scale))
-- 		end
	else
		S_StopSoundByID(mo, sfx_s3k7d)
		class.airTransitionedDashAttack = false
	end
end)

PoyoPennynickel:addScript("PlayerJump", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if player.pflags & PF_JUMPED then return end
	if player.pflags & PF_JUMPDOWN then return end

	if mo.state == S_PLAY_POYO_DASH_ATTACK then
		player.pflags = $|PF_JUMPDOWN

-- 		if player.cmd.buttons & BT_SPIN then
-- 			P_DoJump(player, false)
-- 			S_StartSound(player.mo, sfx_thok)
-- 			return true
-- 		end

		local momx, momy = class:getDashAttackSpeedXY()

		mo.momx = $ + momx
		mo.momy = $ + momy

		local speed = R_PointToDist2(0, 0, mo.momx - player.cmomx, mo.momy - player.cmomy)
-- 		if speed > FixedMul(class.dashAttackJumpCap, mo.scale) then
-- 			local angle = R_PointToAngle2(0, 0, mo.momx - player.cmomx, mo.momy - player.cmomy)
-- 			local cap = FixedMul(class.dashAttackJumpCap, mo.scale)

-- 			mo.momx = P_ReturnThrustX(nil, angle, cap)
-- 			mo.momy = P_ReturnThrustY(nil, angle, cap)
-- 		end

		player.rmomx = mo.momx - player.cmomx
		player.rmomy = mo.momy - player.cmomy

		player.drawangle = player.mo.angle
		P_DoJump(player, true)
		S_StopSoundByID(mo, sfx_s3k7d)
		S_StopSoundByID(mo, sfx_s238)
		S_StartSound(mo, sfx_s3k7e)
		mo.state = S_PLAY_POYO_DASH_ATTACK
		mo.tics = JUMP_TICS
		class.airTransitionedDashAttack = true
		-- mo.state = S_PLAY_ROLL
		return true
	end
end)