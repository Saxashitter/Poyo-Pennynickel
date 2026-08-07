-- genuinely just a hack to detect anything in front of us easily, LOL
local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local MT_POYO_HITCAST = freeslot("MT_POYO_HITCAST")

local function getLineAngle(mo, line)
	local whichside = P_PointOnLineSide(mo.x, mo.y, line)
	local angle = R_PointToAngle2(line.v1.x, line.v1.y, line.v2.x, line.v2.y)

	angle = $ + (ANGLE_90 * (whichside and -1 or 1))

	return angle
end

-- generalize for use outside of here
function Class:getLineAngle(line)
	local mo = self.mo

	return getLineAngle(mo, line)
end

mobjinfo[MT_POYO_HITCAST] = {
	spawnstate = S_INVISIBLE,
	radius = 48 * FU,
	height = 64 * FU,
	flags = MF_NOGRAVITY,
	flags2 = MF2_DONTDRAW
}

addHook("MobjSpawn", function(cast)
	cast.hitwall = false
	cast.hitmobj = false
	cast.hit = false

	cast.angleofhit = 0
end, MT_POYO_HITCAST)

addHook("MobjMoveBlocked", function(cast, mobj, line)
	cast.hit = true
	
	if line and line.valid then
-- 		local whichside = P_PointOnLineSide(cast.x, cast.y, line)
-- 		local angle = R_PointToAngle2(line.v1.x, line.v1.y, line.v2.x, line.v2.y)

-- 		angle = $ + (ANGLE_90 * (whichside and -1 or 1))

-- 		local lx, ly = P_ClosestPointOnLine(cast.x, cast.y, line)
-- 		local angle = R_PointToAngle2(cast.x, cast.y, lx, ly)

		cast.hitwall = true
		cast.angleofhit = getLineAngle(cast, line)
	end
end, MT_POYO_HITCAST)

function PoyoPennynickel.CheckLine(mo, line, allownoclimb)	
	-- really easy one, dont cling to noclimb walls
	if not (allownoclimb)
		if (line.flags & ML_NOCLIMB) then return false end
	end
	
	-- horizon line
	if (line.special == 41) then return end
	
	-- sector checks
	if not (line.backsector) then return true end	-- apparently in these situations source always returns true?
	local sec = (line.backsector and not P_PointOnLineSide(mo.x, mo.y, line)) and line.backsector or line.frontsector
	
	local canclimb = false
	local checkz = {mo.z, mo.z + mo.height}
	if (mo.eflags & MFE_VERTICALFLIP) then checkz = {mo.z + mo.height, mo.z} end

	local floorheight = sec.floorheight
	local ceilingheight = sec.ceilingheight

	if sec.f_slope and sec.f_slope.valid then
		floorheight = P_GetZAt(sec.f_slope, mo.x, mo.y)
	end
	if sec.c_slope and sec.c_slope.valid then
		ceilingheight = P_GetZAt(sec.c_slope, mo.x, mo.y)
	end

	-- floor check
	if (checkz[1] < floorheight)
		canclimb = true 
	end
	
	-- ceiling checks
	local thokbarrier = (sec.ceilingpic:upper():find("F_SKY"))	-- walls above this ceiling arent rendered, shouldnt be able to climb?
	if ((checkz[2] >= ceilingheight) and not thokbarrier) 
		canclimb = true
	end
	
	-- FOF checks
	for rover in sec.ffloors()
		if not (rover.flags & FF_EXISTS and rover.flags & FF_BLOCKPLAYER) then continue end
		
		if (checkz[2] > rover.bottomheight)
		and (checkz[1] < rover.topheight)
			canclimb = true
			break
		end
	end
	
	-- if we're here, line checks went right
	return canclimb
end

addHook("MobjLineCollide", function(cast, line)
	if line and line.valid and PoyoPennynickel.CheckLine(cast, line) then
		cast.hit = true

		local lx, ly = P_ClosestPointOnLine(cast.x, cast.y, line)
		local angle = R_PointToAngle2(cast.x, cast.y, lx, ly)

		cast.hitwall = true
		cast.angleofhit = angle
	end
end, MT_POYO_HITCAST)

local function onCollision(cast, mo)
	if not cast then return end
	if not cast.valid then return end

	if not mo then return end
	if not mo.valid then return end
	if mo.flags & MF_SOLID == 0 then return end
	if mo.type == MT_PLAYER then return end
	if cast.tracer == mo then return end

	-- do our checks...
	if mo.z > cast.z + cast.height then return end
	if cast.z > mo.z + mo.height then return end

	-- FORCE A COLLISION!!
	cast.hitmobj = true
	cast.angleofhit = R_PointToAngle2(cast.x, cast.y, mo.x, mo.y)
	cast.hit = true
	return true
end

addHook("MobjCollide", onCollision, MT_POYO_HITCAST)
addHook("MobjMoveCollide", onCollision, MT_POYO_HITCAST)

function Class:isPlayerBlocked(momx, momy)
	local mo = self.mo
	local ray = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_POYO_HITCAST)
	if not ray or not ray.valid then return false end

	ray.radius = mo.radius
	ray.height = mo.height
	ray.tracer = mo

	-- step toward the wall in small increments until blocked
	local steps = 16
	local stepx = momx / steps
	local stepy = momy / steps
	local x = ray.x
	local y = ray.y
	local z = ray.z
	local hit = false
	local angleofhit = 0
	local hitwall = false
	local hitmobj = false

	for i = 1, steps do
		ray.hit = false
		ray.hitwall = false
		ray.hitmobj = false
		ray.angleofhit = 0

		local success = P_TryMove(ray, ray.x + stepx, ray.y + stepy, true)

		if not ray or not ray.valid then
			return false
		end

		if ray.hit then
		hit = true
		angleofhit = ray.angleofhit
		hitwall = ray.hitwall
		hitmobj = ray.hitmobj
		x = ray.x
		y = ray.y
		z = ray.z
		end

		if not success then
			break
		end
	end

	P_RemoveMobj(ray)

	if not hit then return false end
	return true, angleofhit, hitwall, hitmobj, x, y, z
end