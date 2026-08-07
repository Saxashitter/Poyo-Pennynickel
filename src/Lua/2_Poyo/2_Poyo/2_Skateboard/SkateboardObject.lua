local MT_POYO_SKATEBOARD = freeslot("MT_POYO_SKATEBOARD")
local S_POYO_SKATEBOARD = freeslot("S_POYO_SKATEBOARD")

mobjinfo[MT_POYO_SKATEBOARD] = {
	spawnstate = S_POYO_SKATEBOARD,
	radius = 16 * FU,
	height = 32 * FU,
	flags = 0
}

states[S_POYO_SKATEBOARD] = {
	sprite = SPR_RING,
	frame = 0,
	tics = -1,
}

local function distance3D(x1, y1, z1, x2, y2, z2)
	local distXY = R_PointToDist2(x1, y1, x2, y2)
	return R_PointToDist2(0, 0, distXY, z2 - z1)
end

local function returnMomentumToTarget(mo, target, speed)
	local dx = target.x - mo.x
	local dy = target.y - mo.y
	local dz = target.z - mo.z

	local distXY = R_PointToDist2(0, 0, dx, dy)
	local dist3D = R_PointToDist2(0, 0, distXY, dz)
	local snapped = false

	if dist3D == 0 then
		return 0, 0, 0
	end

	speed = min(speed, dist3D)

	if speed == dist3D then
		snapped = true
	end

	local angle = R_PointToAngle2(0, 0, dx, dy)
	local pitch = R_PointToAngle2(0, 0, distXY, dz)

	local momx = P_ReturnThrustX(nil, angle, FixedMul(speed, cos(pitch)))
	local momy = P_ReturnThrustY(nil, angle, FixedMul(speed, cos(pitch)))
	local momz = FixedMul(speed, sin(pitch))

	return momx, momy, momz, snapped
end

addHook("MobjSpawn", function(board)
	if not board.valid then return end

	board.color = SKINCOLOR_RED
	board.colorized = true
	board.hitenemy = false
end, MT_POYO_SKATEBOARD)

addHook("MobjThinker", function(board)
	if not board.valid then return end

	if P_IsObjectOnGround(board) then
		P_RemoveMobj(board)
		return
	end
end, MT_POYO_SKATEBOARD)

local function mobjCollide(board, target)
	if not board.valid then return end

	if board.z > target.z + target.height then return end
	if target.z > board.z + board.height then return end

	if target.flags & (MF_ENEMY|MF_BOSS|MF_MONITOR) == 0 then return end
	if not target.health then return end

	local source = board.tracer
	if not (source and source.valid) then
		source = nil
	end

	if not P_DamageMobj(target, board, source) then return end

	local speed = distance3D(0,0,0,board.momx,board.momy,board.momz)
	local angle = R_PointToAngle2(target.x, target.y, board.x, board.y)
	local aiming = R_PointToAngle2(0, target.z + target.height / 2, R_PointToDist2(target.x, target.y, board.x, board.y), board.z + board.height / 2)

	board.hitenemy = true
	if source then
		board.momz = abs($ * 2)
		return
	end

	-- reflect
	P_InstaThrust(board, angle, FixedMul(speed, cos(aiming)))
	board.momz = FixedMul(speed, sin(aiming))
end

local function playerCollide(board, target)
	if not board.valid then return end

	if board.z > target.z + target.height then return end
	if target.z > board.z + board.height then return end
	if board.hitenemy == false then return end

	if target.type ~= MT_PLAYER then return end
	if not target.health then return end

	if not target.poyoChar then return end
	if target ~= board.tracer then return end
	if target.state == S_PLAY_POYO_SKATEBOARD_STUN then return end

	target.poyoChar:doSkateboardStun(board)
end

addHook("MobjCollide", mobjCollide, MT_POYO_SKATEBOARD)
addHook("MobjMoveCollide", mobjCollide, MT_POYO_SKATEBOARD)

addHook("MobjCollide", playerCollide, MT_POYO_SKATEBOARD)
addHook("MobjMoveCollide", playerCollide, MT_POYO_SKATEBOARD)