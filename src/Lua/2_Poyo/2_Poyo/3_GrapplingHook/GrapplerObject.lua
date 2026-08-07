-- when you lwk copy the skateboard ray lua

local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local MT_POYO_GRAPPLER = freeslot("MT_POYO_GRAPPLER")

mobjinfo[MT_POYO_GRAPPLER] = {
	spawnstate = S_THOK,
	radius = 10 * FU,
	height = 36 * FU,
	flags = MF_NOGRAVITY
}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function resolveMobjAgainstLine(mobj, line)
	local halfX = mobj.radius
	local halfY = mobj.radius

	-- where the mobj was trying to go this tic
	local intendedX = mobj.x + mobj.momx
	local intendedY = mobj.y + mobj.momy

	-- line direction and its normal (perpendicular)
	local ldx, ldy = line.dx, line.dy
	local llen = FixedHypot(ldx, ldy)
	if llen == 0 then return mobj.x, mobj.y end -- degenerate zero-length line, bail safely

	local nx = FixedDiv(-ldy, llen)
	local ny = FixedDiv(ldx, llen)

	-- reference point on the line to measure from
	local v1x, v1y = line.v1.x, line.v1.y

	-- signed distance of the mobj's CURRENT (pre-move, still-valid) position
	-- from the line -- this can never have tunneled through, so its sign
	-- reliably tells us which side of the wall we're actually on
	local curRelX = mobj.x - v1x
	local curRelY = mobj.y - v1y
	local curD = FixedMul(curRelX, nx) + FixedMul(curRelY, ny)
	local sign = (curD < 0) and -1 or 1

	-- signed distance of the INTENDED position from the line
	local relx = intendedX - v1x
	local rely = intendedY - v1y
	local d = FixedMul(relx, nx) + FixedMul(rely, ny)

	-- effective half-extent of the AABB projected onto this normal direction
	local r = FixedMul(halfX, abs(nx)) + FixedMul(halfY, abs(ny))

	local desiredD = sign * r
	local delta = desiredD - d

	-- shift intended position along the normal by delta so it ends up
	-- exactly `r` away from the line, on the side we know we started on
	local newX = intendedX + FixedMul(delta, nx)
	local newY = intendedY + FixedMul(delta, ny)

	return newX, newY
end

addHook("MobjSpawn", function(cast)
	cast.hit = false
	cast.inited = false
end, MT_POYO_GRAPPLER)

addHook("MobjMoveBlocked", function(cast, mobj, line)
	if not cast.inited then return end

	cast.hit = true

	if line and line.valid then
		local z = cast.z
		local lx, ly = P_ClosestPointOnLine(cast.x, cast.y, line)
		local x, y = resolveMobjAgainstLine(cast, line)

		cast.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
		P_SetOrigin(cast, x, y, z)

		cast.momx = 0
		cast.momy = 0
		cast.hitline = line
	end
end, MT_POYO_GRAPPLER)

addHook("MobjThinker", function(cast)
	local mo = cast.target

	if not mo then return end
	if not mo.valid then return end

	P_MoveOrigin(cast, mo.x + cast.ox, mo.y + cast.oy, mo.z + cast.oz)
end, MT_POYO_GRAPPLER)

local function onCollision(cast, mo)
	if not cast then return end
	if not cast.valid then return end

	if not mo then return end
	if not mo.valid then return end
	if not cast.tracer then return end
	if not cast.tracer.valid then return end
	if mo.flags & (MF_ENEMY|MF_SOLID|MF_BOSS) == 0 then return end
	if cast.tracer == mo then return end
	if not cast.inited then return end -- strange hack... collisions happen if your going too fast and the mobj spawns
	if cast.hit then return end

	-- do our checks...
	if mo.z > cast.z + cast.height then return end
	if cast.z > mo.z + mo.height then return end

	local hit_angle = R_PointToAngle2(cast.x, cast.y, mo.x, mo.y)
	local radius = mo.radius + cast.radius

	cast.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT
	P_MoveOrigin(cast,
		mo.x + P_ReturnThrustX(nil, hit_angle, -radius),
		mo.y + P_ReturnThrustY(nil, hit_angle, -radius),
		cast.z)

	-- FORCE A COLLISION!!
	cast.hit = true
	cast.target = mo
	cast.ox = cast.x - mo.x
	cast.oy = cast.y - mo.y
	cast.oz = cast.z - mo.z
	return true
end

-- addHook("MobjCollide", onCollision, MT_POYO_GRAPPLER)
addHook("MobjMoveCollide", onCollision, MT_POYO_GRAPPLER)