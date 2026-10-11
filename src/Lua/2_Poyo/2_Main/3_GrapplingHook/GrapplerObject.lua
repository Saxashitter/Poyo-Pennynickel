-- when you lwk copy the skateboard ray lua

local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local MT_POYO_GRAPPLER = freeslot("MT_POYO_GRAPPLER")

mobjinfo[MT_POYO_GRAPPLER] = {
	spawnstate = S_THOK,
	radius = 10 * FU,
	height = 20 * FU,
	flags = MF_NOGRAVITY
}

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

addHook("MobjSpawn", function(cast)
	cast.hit = false
	cast.inited = false
end, MT_POYO_GRAPPLER)

addHook("MobjMoveBlocked", function(cast, mobj, line)
	if not cast.inited then return end

	cast.hit = true

	if line and line.valid then
		P_SlideMove(cast)
		cast.hitline = line
		cast.hittics = 5
	end
end, MT_POYO_GRAPPLER)

addHook("MobjThinker", function(cast)
	local mo = cast.target

	if mo and mo.valid then
		P_MoveOrigin(cast, mo.x + cast.ox, mo.y + cast.oy, mo.z + cast.oz)
	elseif cast.hit and cast.hitline and cast.hittics and cast.hitline.special == 500 then
		local line = cast.hitline

		local x = -line.args[1] * FU
		local y = line.args[2] * FU
		local cx, cy = P_ClosestPointOnLine(cast.x, cast.y, line)
		local angle = R_PointToAngle2(cast.x, cast.y, cx, cy)

		-- TODO: correct this if line sloped (could lines even be sloped???)
		cast.momz = y
		cast.momx = P_ReturnThrustX(nil, line.angle, x)
		cast.momy = P_ReturnThrustY(nil, line.angle, x)

		P_Thrust(cast, angle, FU)
		cast.hittics = $ - 1
	end
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