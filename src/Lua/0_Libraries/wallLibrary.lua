-- library made by saxa

if SAXA_CheckCollisionOnAngle ~= nil then
	print("wallLibrary already loaded...")
	return
end

local MT_SAXA_RAY = freeslot("MT_SAXA_RAY")
local _RAY -- mobj_t

mobjinfo[MT_SAXA_RAY].radius = FU
mobjinfo[MT_SAXA_RAY].height = FU
mobjinfo[MT_SAXA_RAY].flags = 0
mobjinfo[MT_SAXA_RAY].spawnstate = S_INVISIBLE

local function reset_ray_mobj(ray)
	ray.hit = nil
	ray.hitangle = nil
end

addHook("MapChange", function()
	_RAY = nil
end)

addHook("NetVars", function(sync)
	_RAY = sync($)
end)

addHook("MobjMoveBlocked", function(ray, mobj, line)
	if not line then return end
	if not line.valid then return end

	local lx, ly = P_ClosestPointOnLine(ray.x, ray.y, line)
	local angle = R_PointToAngle2(ray.x, ray.y, lx, ly)

	ray.hit = true
	ray.hitangle = angle
end, MT_SAXA_RAY)

addHook("MobjMoveCollide", function(ray, mobj)
	if ray._dontrun then return end

	if not mobj then return end
	if not mobj.valid then return end
	if not mobj.health then return end
	if mobj.flags & MF_SOLID == 0 then return end
	if ray.tracer == mobj then return end
	if ray.z > mobj.z + mobj.height then return end
	if mobj.z > ray.z + ray.height then return end

	ray.hit = true
	ray.hitangle = R_PointToAngle2(ray.x, ray.y, mobj.x, mobj.y)
	ray.target = mobj
end, MT_SAXA_RAY)

local function checkForCollisionOnMomentum(mo, x, y, z, steps)
	if steps == nil then steps = 320 end
	if z == nil then z = 0 end

	local collider = _RAY

	if not collider or not collider.valid then
		_RAY = P_SpawnMobj(mo.x, mo.y, mo.z, MT_SAXA_RAY)
		collider = _RAY
	end

	reset_ray_mobj(collider)

	collider._dontrun = true
	collider.flags = MF_NOCLIP|MF_NOCLIPHEIGHT
	collider.radius = mo.radius
	collider.height = mo.height
	P_SetOrigin(collider, mo.x, mo.y, mo.z)
	collider.flags = 0

	collider.target = nil

	if type(mo) == "userdata" then
		collider.tracer = mo
	elseif mo.tracer then
		collider.tracer = mo.tracer
	else
		collider.tracer = nil
	end

	collider._dontrun = nil

	-- move collider
	collider.momx = x / steps
	collider.momy = y / steps
	collider.momz = z / steps

	for i = 1, steps do
		collider.flags = 0
		collider.radius = mo.radius
		collider.height = mo.height
		P_RingZMovement(collider)
		P_XYMovement(collider)

		if not collider or not collider.valid then
			return false
		end

		if collider.hit then
			return true, collider.hitangle, collider.x, collider.y, collider.z, collider.target, i
		end
		collider.momx = x / steps
		collider.momy = y / steps
		collider.momz = z / steps
	end

	return false
end

local function checkForCollisionOnAngle(mo, angle, thrust, steps)
	if step == nil then
		step = FU * 5
	end

	local x = P_ReturnThrustX(nil, angle, thrust)
	local y = P_ReturnThrustY(nil, angle, thrust)

	return checkForCollisionOnMomentum(mo, x, y, 0, steps)
end

local function checkForCollisionOnPosition(mo, target, steps)
	local x = target.x - mo.x
	local y = target.y - mo.y
	local z = target.z - mo.z

	return checkForCollisionOnMomentum(mo, x, y, z, steps)
end

rawset(_G, "SAXA_CheckCollisionOnAngle", checkForCollisionOnAngle)
rawset(_G, "SAXA_CheckCollisionOnMomentum", checkForCollisionOnMomentum)
rawset(_G, "SAXA_CheckCollisionOnPosition", checkForCollisionOnPosition)