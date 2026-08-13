local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

Class.skateboardFrictionMult = FU * 100 / 95
Class.clingTime = 0
Class.clingSpeed = 0
Class.skateboard = false
Class.skateboarded = false -- so we can do hop off skateboard + grapple...
Class.lastDrawangle = 0 -- for momentum conversion thing

local S_PLAY_POYO_SKATEBOARD_CLING = freeslot("S_PLAY_POYO_SKATEBOARD_CLING")

states[S_PLAY_POYO_SKATEBOARD_CLING] = {
	sprite = SPR_PLAY,
	frame = SPR2_ROLL,
	tics = 5,
	nextstate = S_PLAY_POYO_SKATEBOARD_CLING,
	action = function(mo)
		if not mo.valid then return end
		if not mo.player then return end

		mo.player.panim = PA_ROLL
	end
}

local function canClimbLine(mo, line, side)
	return line and line.valid and side and side.valid and line.flags & ML_NOCLIMB == 0 and not P_CheckSkyHit(mo, line)
end

function Class:setSkatingStats(skate)
	local player = self.mo.player
	local info = skins[player.skin]

	if skate then
		player.normalspeed = 36 * FU
		player.acceleration = info.acceleration / 3
		player.accelstart = info.accelstart / 2
		player.thrustfactor = info.thrustfactor * 5 / 3
		return
	end

	player.normalspeed = info.normalspeed
	player.acceleration = info.acceleration
	player.accelstart = info.accelstart
	player.thrustfactor = info.thrustfactor
end

local function triggerSkateboard(player)
	local mo = player.mo
	local class = mo.poyoChar

	class.skateboard = not $
	mo.colorized = class.skateboard

	player.poyo_skateboard = class.skateboard

	if class.skateboard then
		class:setSkatingStats(true)
		if player.pflags & PF_JUMPED then
			player.pflags = $|PF_THOKKED
		end
	else
		class:setSkatingStats(false)

		-- double jump
		if not P_IsObjectOnGround(mo) then
			class.skateboarded = true
			player.pflags = $ & ~(PF_JUMPED|PF_SPINNING)
			P_DoJump(player, true)
			player.pflags = $|PF_THOKKED

			-- not holding jump when you do it? just give the player the full jump anyway
			if player.cmd.buttons & BT_JUMP == 0 then
				player.pflags = $ & ~PF_STARTJUMP
			end

			local board_info = mobjinfo[MT_POYO_SKATEBOARD]
			local board = P_SpawnMobjFromMobj(player.mo, 0, 0, -board_info.height, MT_POYO_SKATEBOARD)

			board.momx = player.mo.momx
			board.momy = player.mo.momy
			board.momz = -player.mo.momz

			board.tracer = player.mo
		end
	end
end

PoyoPennynickel:addScript("PlayerSpawn", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if player.poyo_skateboard then
		local info = skins[player.skin]

		class:setSkatingStats(false)
	end

	player.poyo_skateboard = nil
end)

PoyoPennynickel:addScript("PlayerJump", function(player)
	if P_IsObjectOnGround(player.mo) then return end
	if player.pflags & PF_JUMPDOWN then return end

	if player.mo.state == S_PLAY_POYO_SKATEBOARD_CLING then
		local mo = player.mo
		local class = mo.poyoChar
		local pflags = player.pflags & PF_THOKKED
		player.pflags = $ & ~(PF_JUMPED)

		local omomz = mo.momz
		local under = mo.momz * P_MobjFlip(mo) < 0
		P_DoJump(player, true)
		mo.momz = (12 * mo.scale) * P_MobjFlip(mo)
		if not under then
			mo.momz = (6 * mo.scale) * P_MobjFlip(mo)
			mo.momz = $ + omomz
		end

		player.pflags = $|pflags

		local control_direction = player.drawangle
		if player.cmd.forwardmove or player.cmd.sidemove then
			control_direction = player.cmd.angleturn * FU + R_PointToAngle2(0, 0, player.cmd.forwardmove<<16, -player.cmd.sidemove<<16)
		end

		local ratio = (FU / 2) + (FU / 7)
		local base_jump_speed = 35 * mo.scale

		local wall_speed = FixedMul(base_jump_speed, ratio)
		local direction_speed = base_jump_speed - wall_speed

		P_Thrust(mo, player.drawangle, wall_speed)
		P_Thrust(player.mo, control_direction, direction_speed)
		player.pflags = $|PF_JUMPDOWN
		S_StartSound(mo, sfx_s3k4c)

		return true
	end
end)

PoyoPennynickel:addScript("PlayerUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	local rollAnim = false
	-- if P_IsObjectOnGround(mo) then return end

	if MM and MM:isMM() then return end
	if ZE2 and gametype == GT_ZE2 then return end
	if player.cmd.buttons & BT_CUSTOM1 == 0 then return end
	if player.lastbuttons & BT_CUSTOM1 then return end

	if mo.state == S_PLAY_POYO_SWING then return end
	if mo.state == S_PLAY_POYO_DASH_ATTACK then
		if player.pflags & PF_JUMPED == 0 then return end
		rollAnim = true
	end

	-- if player.pflags & PF_JUMPED == 0 then return end
	if not mo.health then return end
	if mo.state == S_PLAY_POYO_GRAPPLE then return end
	if mo.state == S_PLAY_POYO_GRAPPLED then return end
	if P_PlayerInPain(player) then return end
-- 	if player.pflags & PF_THOKKED then return end
	if class.skateboarded then return end
	if player.exiting then return end
	if player.powers[pw_carry] then return end
	if player.pflags & PF_SLIDING then return end

	if rollAnim then
		mo.state = S_PLAY_ROLL
		mo.momx = $*5/6
		mo.momy = $*5/6
	end
	triggerSkateboard(player)
end)

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if not class.skateboarded then return end
	class.skateboarded = not P_IsObjectOnGround(mo) -- lazy
end)

PoyoPennynickel:addScript("PlayerMobjUpdate", function(player)
	local mo = player.mo
	local class = player.mo.poyoChar

	if not class.skateboard then return end

	mo.friction = min(FU, FixedMul($, class.skateboardFrictionMult))
-- 	mo.flags = $|MF_SLIDEME
	if P_IsObjectOnGround(mo) and mo.standingslope then
		local omomx = mo.momx
		local omomy = mo.momy

		P_ButteredSlope(mo)

		local nmomx = mo.momx
		local nmomy = mo.momy

		mo.momx = omomx + (nmomx - omomx) / 2
		mo.momy = omomy + (nmomy - omomy) / 2
	end

	class:setSkatingStats(player, true)

	-- wall cling....
	local line = lines[player.lastlinehit]
	local side = sides[player.lastsidehit]

	if mo.state == S_PLAY_POYO_SKATEBOARD_CLING
	and class.clingTime
	and canClimbLine(mo, line, side) then
		if not S_SoundPlaying(mo, sfx_s3k55) then
			S_StartSoundAtVolume(mo, sfx_s3k55, 50)
		end

		local pointx, pointy = P_ClosestPointOnLine(mo.x, mo.y, line)

		player.drawangle = R_PointToAngle2(pointx, pointy, mo.x, mo.y)
		class.lastDrawangle = player.drawangle

		local angle = class:getLineAngle(line)
		local speedAngle = R_PointToAngle2(0, 0, mo.momx, mo.momy)

		local moving_towards = angle - ANGLE_90
		local moving_behind = FixedMul(class.clingSpeed, cos(speedAngle - moving_towards)) < 0

		if moving_behind then
			moving_towards = angle + ANGLE_90
		end

		P_InstaThrust(mo, moving_towards, class.clingSpeed)
		P_Thrust(mo, player.drawangle, -FU*4)

		class.clingSpeed = FixedMul($, FU - FU / 17)
		class.clingTime = $ - 1
	else
		if mo.state == S_PLAY_POYO_SKATEBOARD_CLING then
			mo.state = S_PLAY_FALL
			local momz = FixedDiv(mo.momz, mo.scale) * P_MobjFlip(mo)

			if momz > 0 then
				mo.momz = 0
				P_Thrust(mo, class.lastDrawangle, -momz)
			end
		end
		if class.clingTime then
			class.clingTime = 0
		end
	end

	local speed = R_PointToDist2(0, 0, mo.momx - player.cmomx, mo.momy - player.cmomy)

	-- fix to scale
	speed = FixedDiv($, mo.scale)

	-- TODO: proper adjustment while having speed shoes or in water
	if speed > player.normalspeed then
		PoyoPennynickel.AfterimageEffect(mo)
	end
	player.normalspeed = max($, speed)
end)

local function angleDiff(ang1, ang2)
	local adiff = FixedAngle(
		AngleFixed(ang1) - AngleFixed(ang2)
	)
	if AngleFixed(adiff) > 180*FU
		adiff = InvAngle($)
	end
	return AngleFixed(adiff)
end

-- code somewhat inspired by mario bros since their wall cling works amazingly
PoyoPennynickel:addScript("PlayerBlocked", function(player, mobj, line)
	local mo = player.mo
	local class = player.mo.poyoChar

	if not class.skateboard then return end
	if P_IsObjectOnGround(mo) then return end

	local prevline = player.lastlinehit
	local prevside = player.lastsidehit
	

	player.lastlinehit = -1
	player.lastsidehit = -1

	local omomx = mo.momx
	local omomy = mo.momy
	P_SlideMove(mo)

	local line = lines[player.lastlinehit]
	local side = sides[player.lastsidehit]

	if canClimbLine(mo, line, side) and P_LineIsBlocking(mo, line) then
		local pointx, pointy = P_ClosestPointOnLine(mo.x, mo.y, line)
		player.drawangle = R_PointToAngle2(pointx, pointy, mo.x, mo.y)

		if mo.state ~= S_PLAY_POYO_SKATEBOARD_CLING then
			local angle = class:getLineAngle(line)
			local magnitude = R_PointToDist2(0, 0, omomx, omomy)
			local speedAngle = R_PointToAngle2(0, 0, omomx, omomy)

			-- check against the default assumption (angle - 90) first
			local moving_towards = angle - ANGLE_90
			local moving_behind = FixedMul(magnitude, cos(speedAngle - moving_towards)) < 0

			if moving_behind then
				moving_towards = angle + ANGLE_90
			end

			local speed = FixedMul(magnitude, cos(speedAngle - moving_towards))

			class.clingSpeed = abs(speed)
			mo.state = S_PLAY_POYO_SKATEBOARD_CLING
			P_SetObjectMomZ(mo, 5 * FU, true)
			player.pflags = $ & ~PF_STARTJUMP

			S_StartSound(mo, sfx_s3k4a)
		end

		player.powers[pw_pushing] = 5
		class.clingTime = 5
	else
		player.lastlinehit = prevline
		player.lastsidehit = prevside
	end

	return true
end)