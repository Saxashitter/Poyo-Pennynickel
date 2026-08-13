local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local S_PLAY_POYO_GRAPPLE = freeslot("S_PLAY_POYO_GRAPPLE")
local S_PLAY_POYO_GRAPPLED = freeslot("S_PLAY_POYO_GRAPPLED")
local S_PLAY_POYO_QUICK_GRAPPLE = freeslot("S_PLAY_POYO_QUICK_GRAPPLE")

local GRAPPLE_SPEED = 40 * FU
local FORWARD_THRUST = 300 * FU
local UPWARDS_THRUST = 300 * FU
local GRAVITY = FU * 3
local GRAPPLE_HOP = 15 * FU
local GRAPPLE_TICS = 18
local GRAPPLE_LINE_DISTANCE = 2 * FU
local GRAPPLE_TIMES = 3

local GRPL_DIAGONAL = 0

local start_hook = freeslot("sfx_py_hk2")
local cling_hook = freeslot("sfx_py_hk1")

local SPR_POYO_GRAPPLEHOOK = freeslot("SPR_POYO_GRAPPLEHOOK")
local HOOK_FRAME = A
local CHAIN_FRAME = B

states[S_PLAY_POYO_GRAPPLE] = {
	sprite = SPR_PLAY,
	frame = SPR2_GASP,
	tics = GRAPPLE_TICS,
	nextstate = S_PLAY_FALL
}

states[S_PLAY_POYO_GRAPPLED] = {
	sprite = SPR_PLAY,
	frame = SPR2_RIDE,
	tics = -1,
	nextstate = S_PLAY_FALL
}

states[S_PLAY_POYO_QUICK_GRAPPLE] = {
	sprite = SPR_PLAY,
	frame = SPR2_ROLL,
	tics = 2,
	nextstate = S_PLAY_POYO_QUICK_GRAPPLE,
	action = function(mo)
		if not mo then return end
		if not mo.valid then return end
		if not mo.player then return end

		mo.player.panim = PA_ROLL
	end
}

Class.grappleMobj = nil
Class.ropeLength = 0
Class.grappleState = GRPL_DIAGONAL
Class.grappleTimes = 0
Class.grappleHeldTics = 0
Class.successfulGrapple = false
-- DONT INIT HERE!!! it wont be a copied- over table
--Class.grappleLines = {}

local function manageGrappleLines(player)
	local mo = player.mo
	local class = mo.poyoChar
	local mobj = class.grappleMobj

	local moZ = mo.z + mo.height / 2
	local mobjZ = mobj.z + mobj.height / 2

	local distanceXY = R_PointToDist2(mo.x, mo.y, mobj.x, mobj.y)
	local distanceXYZ = R_PointToDist2(0, moZ, distanceXY, mobjZ)
	local lineDistance = FixedMul(GRAPPLE_LINE_DISTANCE, mo.scale)

	local linesBetween = distanceXYZ / lineDistance
	for i = 1, linesBetween do
		local t = FixedDiv(i, linesBetween)

		local line = class.grappleLines[i]
		local x = ease.linear(t, mo.x, mobj.x)
		local y = ease.linear(t, mo.y, mobj.y)
		local z = ease.linear(t, moZ, mobjZ)

		if not line or not line.valid then
			-- create line
			line = P_SpawnMobjFromMobj(mo, x - mo.x, y - mo.y, z - mo.z, MT_THOK)
			line.fuse = -1
			line.scale = mo.scale / 2
			line.sprite = SPR_POYO_GRAPPLEHOOK
			line.frame = ($ & ~(FF_FRAMEMASK|FF_TRANSMASK))|CHAIN_FRAME
			line.radius = FU
			line.height = FU
			class.grappleLines[i] = line
		else
			P_MoveOrigin(line, x, y, z)
		end

		line.fuse = -1
		line.tics = 2
	end

	if #class.grappleLines >= linesBetween then
		for i = linesBetween, #class.grappleLines do
			local line = class.grappleLines[i]

			if line and line.valid then
				P_RemoveMobj(line)
			end
			class.grappleLines[i] = nil
		end
	end
end

local function manageGrapple(player)
	local mo = player.mo
	local class = mo.poyoChar
	local mobj = class.grappleMobj

	class.grappleLines = $ or {}

	if not mobj or not mobj.valid then
		if mo.state == S_PLAY_POYO_GRAPPLED then
			mo.state = S_PLAY_FALL
			return
		end

		mobj = P_SpawnMobjFromMobj(mo, 0,0,0, MT_POYO_GRAPPLER)
		mobj.fuse = -1 -- dont die
		mobj.tics = -1 -- seriously
		mobj.tracer = mo
		mobj.color = mo.color
		mobj.inited = true
		mobj.sprite = SPR_POYO_GRAPPLEHOOK
		mobj.frame = ($ & ~(FF_FRAMEMASK|FF_TRANSMASK))|HOOK_FRAME

		class.grappleMobj = mobj
	end

	local up = FixedMul(UPWARDS_THRUST, mo.scale)
	local forward = FixedMul(FORWARD_THRUST, mo.scale)

	local targetX = mo.x + P_ReturnThrustX(nil, mo.angle, forward)
	local targetY = mo.y + P_ReturnThrustY(nil, mo.angle, forward)
	local targetZ = mo.z + mo.height / 2 + up

	if P_MobjFlip(mo) < 0 then
		targetZ = (mo.z + (mo.height / 2) - mobj.height) - up
	end

	if mo.state == S_PLAY_POYO_GRAPPLED then
		local enemy = mobj.target
		if enemy and not enemy.valid then
			enemy = nil
		end

		local player_speed = R_PointToDist2(0, 0, R_PointToDist2(0,0,mo.momx,mo.momy), mo.momz)

		local dx = mo.x - mobj.x
		local dy = mo.y - mobj.y
		local dz = (mo.z + mo.height/2) - (mobj.z + mobj.height/2)

		local horiz = R_PointToDist2(0, 0, dx, dy)
		local dist = R_PointToDist2(0, 0, horiz, dz)

		local ux = FixedDiv(dx, dist)
		local uy = FixedDiv(dy, dist)
		local uz = FixedDiv(dz, dist)

		if player.cmd.buttons & BT_JUMP == 0 then
			mo.state = S_PLAY_FALL
			player.powers[pw_flashing] = 20

			if class.grappleHeldTics <= 2 then
				mo.momz = 0
				return
			end

			-- lets cap the players momentum
			local speed = abs(mo.momz) -- R_PointToDist2(0, 0, R_PointToDist2(0, 0, mo.momx, mo.momy), mo.momz)
			local cap = 17*mo.scale
			local mult = FU

			if speed >= cap then
				local div = FixedDiv(cap, speed)
				div = FixedMul($, mult)
				print(string.format("%.2f", div))
	
				mo.momx = FixedMul($, div)
				mo.momy = FixedMul($, div)
				mo.momz = FixedMul($, div)
			end
			return
		end

		if player.cmd.buttons & BT_SPIN
		and player.lastbuttons & BT_SPIN == 0 then
			local grapple_toss = dist / 12
	
			mo.momx = ($/2) + FixedMul(-ux, grapple_toss)
			mo.momy = ($/2) + FixedMul(-uy, grapple_toss)
			mo.momz = ($/2) + FixedMul(-uz, grapple_toss)

			mo.state = S_PLAY_FALL
			player.powers[pw_flashing] = 20
			return
		end

		if player.cmd.buttons & BT_CUSTOM1 then
			local maximum = R_PointToDist2(0, 0, FORWARD_THRUST, UPWARDS_THRUST)
			class.ropeLength = min(maximum, $ + FU)
		end

		class.grappleHeldTics = $ + 1

-- 		if enemy and enemy.flags & MF_ENEMY|MF_BOSS and enemy.type ~= MT_PLAYER then
-- 			local speed = max(player_speed, 25 * FU)
	
-- 			mo.momx = ease.linear(FU/4, $, FixedMul(-ux, speed))
-- 			mo.momy = ease.linear(FU/4, $, FixedMul(-uy, speed))
-- 			mo.momz = ease.linear(FU/4, $, FixedMul(-uz, speed))

-- 			if dist <= mo.radius + mobj.target.radius * 3 then
-- 				P_DamageMobj(mobj.target, mobj, player.mo)

-- 				P_SetObjectMomZ(mo, 15 * FU, true)
-- 				mo.state = S_PLAY_FALL
-- 				player.powers[pw_flashing] = 20
-- 				return
-- 			end
-- 		end

		if dist > 0 and dist > class.ropeLength then
			local overshoot = dist - class.ropeLength

			local x = mo.x - FixedMul(ux, overshoot)
			local y = mo.y - FixedMul(uy, overshoot)
			local z = mo.z - FixedMul(uz, overshoot)

			-- P_MoveOrigin(mo, x, y, z)
			-- instead of moving the player directly... use XYMovement and ZMovement so we dont have collision issues
			local omomx = mo.momx
			local omomy = mo.momy
			local omomz = mo.momz

			mo.momx = x - mo.x
			mo.momy = y - mo.y
			mo.momz = z - mo.z

			P_XYMovement(mo)
			P_ZMovement(mo)

			mo.momx = omomx
			mo.momy = omomy
			mo.momz = omomz

			local vDotU = FixedMul(mo.momx, ux) + FixedMul(mo.momy, uy) + FixedMul(mo.momz, uz)
			if vDotU > 0 then
				mo.momx = $ - FixedMul(vDotU, ux)
				mo.momy = $ - FixedMul(vDotU, uy)
				mo.momz = $ - FixedMul(vDotU, uz)
			end
		end

		manageGrappleLines(player)
		return
	end

	mobj.momx = ease.linear(FU/3, $, targetX - mobj.x)
	mobj.momy = ease.linear(FU/3, $, targetY - mobj.y)
	mobj.momz = ease.linear(FU/3, $, targetZ - mobj.z)
	mobj.angle = R_PointToAngle2(0, 0, mobj.momx, mobj.momy)

	-- snap z before xy
	P_ZMovement(mobj)
	P_XYMovement(mobj)

	if not mobj or not mobj.valid then
		mo.state = S_PLAY_FALL
		return
	end

	-- lets check if theres a collision between the player and the thing
	local col = {
		x = mo.x,
		y = mo.y,
		z = mo.z,
		radius = mobj.radius,
		height = mobj.height,
		tracer = mo
	}
	local result, result_angle, result_x, result_y, result_z, result_target = SAXA_CheckCollisionOnPosition(col, mobj, 128)
	if result then
		mobj.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
		P_SetOrigin(mobj, result_x, result_y, result_z)
		mobj.hit = true
		if result_target then
			mobj.ox = result_x - result_target.x
			mobj.oy = result_y - result_target.y
			mobj.oz = result_z - result_target.z

			mobj.target = result_target
		end
	end

	-- BEFORE WE DO that check... lets check if it hits the floor or ceiling
	if mobj.z <= mobj.floorz or mobj.z + mobj.height >= mobj.ceilingz then
		mobj.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
		mobj.hit = true
	end

	if mobj.hit then
		S_StopSoundByID(mo, start_hook)

		if mobj.hitline and (mobj.hitline.flags & ML_NOCLIMB or P_CheckSkyHit(mobj, mobj.hitline)) then
-- 			player.drawangle = R_PointToAngle2(mo.x, mo.y, mobj.x, mobj.y)
			P_DoPlayerPain(player, mobj, mobj)
			return
		end

		S_StartSound(mo, cling_hook)
		class.successfulGrapple = true
		mo.state = S_PLAY_POYO_GRAPPLED
-- 		mo.momz = $/3
		player.pflags = $ & ~PF_STARTJUMP

		-- lock in the rope length at the moment of attach
		local dz = (mo.z + mo.height/2) - (mobj.z + mobj.height/2)
		local horiz = R_PointToDist2(mo.x, mo.y, mobj.x, mobj.y)

		class.ropeLength = R_PointToDist2(0, 0, horiz, dz)

		local dx = mo.x - mobj.x
		local dy = mo.y - mobj.y
		local dz = (mo.z + mo.height/2) - (mobj.z + mobj.height/2)

		local horiz = R_PointToDist2(0, 0, dx, dy)
		local dist = R_PointToDist2(0, 0, horiz, dz)

		local ux = FixedDiv(dx, dist)
		local uy = FixedDiv(dy, dist)
		local uz = FixedDiv(dz, dist)

		if dist > 0 and player.cmd.buttons & BT_JUMP then
			local dx = mo.x - mobj.x
			local dy = mo.y - mobj.y

			local ux = FixedDiv(dx, dist)
			local uy = FixedDiv(dy, dist)
			local uz = FixedDiv(dz, dist)

			-- strip the radial part of momentum (toward/away from hook),
			-- keep only the tangential part -> instant orbit, no forced pull
			local vDotU = FixedMul(mo.momx, ux) + FixedMul(mo.momy, uy) + FixedMul(mo.momz, uz)

			mo.momx = $ - FixedMul(vDotU, ux)
			mo.momy = $ - FixedMul(vDotU, uy)
			mo.momz = $ - FixedMul(vDotU, uz)

			-- thanks ai... now lets multiply the speed
			local mult = FU*5/4
			mo.momx = FixedMul($, mult)
			mo.momy = FixedMul($, mult)
			mo.momz = FixedMul($, mult)
		end
	end

	manageGrappleLines(player)
	-- reset
	mobj.momx, mobj.momy, mobj.momz = 0,0,0
end

local function deinitGrapple(player)
	local mo = player.mo
	local class = mo.poyoChar

	if class.grappleMobj and class.grappleMobj.valid then
		P_RemoveMobj(class.grappleMobj)
	end

	class.grappleMobj = nil
	S_StopSoundByID(mo, start_hook)

	if not class.grappleLines or not #class.grappleLines then return end

	for i = #class.grappleLines, 1, -1 do
		local mobj = class.grappleLines[i]

		if mobj and mobj.valid then
			P_RemoveMobj(mobj)
		end
		class.grappleLines[i] = nil
	end
end

PoyoPennynickel:addScript("PlayerJump", function(player)
	if MM and MM:isMM() then return end
	if ZE2 and gametype == GT_ZE2 then return end
	if P_IsObjectOnGround(player.mo) then return end
	if player.pflags & PF_JUMPDOWN then return end
	if P_PlayerInPain(player) then return end
	if player.powers[pw_carry] then return end
	if not player.mo.health then return end
	if player.pflags & PF_JUMPED == 0 then return end

	local mo = player.mo
	local class = mo.poyoChar

	if class.skateboard then return end
	if mo.state == S_PLAY_POYO_GRAPPLE then return end
	if player.pflags & PF_THOKKED then
		if not class.grappleTimes and not class.skateboarded then return end
		if not class.successfulGrapple then
			if not class.skateboarded or class.grappleTimes then
				return
			end
		end
		if class.grappleTimes >= GRAPPLE_TIMES then return end
	end

	class.grappleState = GRPL_DIAGONAL

	class.skateboarded = false
	class.successfulGrapple = false
	class.grappleTimes = $ + 1
	class.grappleHeldTics = 0
	player.pflags = ($|PF_THOKKED) & ~PF_STARTJUMP
	P_SetObjectMomZ(mo, GRAPPLE_HOP, mo.momz * P_MobjFlip(mo) > 0)
	mo.state = S_PLAY_POYO_GRAPPLE
	S_StartSound(mo, start_hook)

	manageGrapple(player)
end)

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if P_IsObjectOnGround(mo) then
		class.grappleTimes = 0
		class.successfulGrapple = false
	end

	if mo.state == S_PLAY_POYO_QUICK_GRAPPLE then
		PoyoPennynickel.AfterimageEffect(mo)
	end

	if mo.state ~= S_PLAY_POYO_GRAPPLE and mo.state ~= S_PLAY_POYO_GRAPPLED then
		if class.grappleMobj then
			deinitGrapple(player)
		end
		return
	end

	if mo.state == S_PLAY_POYO_GRAPPLE then
		local gravity = P_GetMobjGravity(mo)

		mo.momz = $ - gravity + FixedMul(gravity, GRAVITY)
	end

	manageGrapple(player)
end)

PoyoPennynickel:addScript("PlayerShouldBeDamaged", function(player, inflictor, source)
	local mo = player.mo
	local class = mo.poyoChar

	if mo.state ~= S_PLAY_POYO_GRAPPLED then return end
	local mobj = class.grappleMobj

	if not mobj or not mobj.valid then return end
	if not mobj.target then return end
	if not mobj.target.valid then return end

	if mobj.target == source
	or mobj.target == inflictor then
		return false
	end
end)

PoyoPennynickel:addScript("PlayerBlocked", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if mo.state ~= S_PLAY_POYO_GRAPPLED then return end

	P_BounceMove(mo)
	return true
end)