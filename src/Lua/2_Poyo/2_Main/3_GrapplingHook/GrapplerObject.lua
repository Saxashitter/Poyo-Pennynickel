-- when you lwk copy the skateboard ray lua

local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local MT_POYO_GRAPPLER = freeslot("MT_POYO_GRAPPLER")
local MT_POYO_GRAPPLECHAIN = freeslot("MT_POYO_GRAPPLECHAIN")
local S_POYO_GRAPPLEHOOK = freeslot("S_POYO_GRAPPLEHOOK")
local S_POYO_GRAPPLECHAIN = freeslot("S_POYO_GRAPPLECHAIN")
local SPR_POYO_GRAPPLEHOOK = freeslot("SPR_POYO_GRAPPLEHOOK")

local HOOK_FRAME = A
local CHAIN_FRAME = B

-- how long a chain link lasts without the grapple code keeping it alive. if whoever owns
-- the chain stops updating it for any reason, the links clean themselves up
PoyoPennynickel.GRAPPLE_CHAIN_TICS = 2

states[S_POYO_GRAPPLEHOOK] = {
	sprite = SPR_POYO_GRAPPLEHOOK,
	frame = HOOK_FRAME,
	tics = -1,
	nextstate = S_POYO_GRAPPLEHOOK
}

states[S_POYO_GRAPPLECHAIN] = {
	sprite = SPR_POYO_GRAPPLEHOOK,
	frame = CHAIN_FRAME|FF_PAPERSPRITE,
	tics = PoyoPennynickel.GRAPPLE_CHAIN_TICS,
	nextstate = S_NULL
}

mobjinfo[MT_POYO_GRAPPLER] = {
	spawnstate = S_POYO_GRAPPLEHOOK,
	radius = 10 * FU,
	height = 20 * FU,
	flags = MF_NOGRAVITY
}

-- one link of the chain. purely for looks, so it's kept out of everything collision
-- related from the moment it spawns
mobjinfo[MT_POYO_GRAPPLECHAIN] = {
	spawnstate = S_POYO_GRAPPLECHAIN,
	radius = FU,
	height = FU,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING|MF_NOGRAVITY|MF_NOBLOCKMAP|MF_SCENERY
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

--
-- anchoring: when the hook sticks to the level it remembers what it's stuck to, so that
-- it can go along for the ride when that thing moves. these are the same cases the source
-- handles for knuckles climbing (P_DoClimbing), plus polyobjects.
--   anchorLine           a polyobject's line. the hook keeps its spot compared to that
--                        line, which follows the polyobject sliding around and spinning
--   anchorSector/Rover   a floor, ceiling or fof. the hook goes up and down with it,
--                        whether it's stuck on top of it, under it, or to the side of it
--   anchorSide           a wall with a scrolling texture (conveyor walls, waterfalls...).
--                        the hook gets carried along by however much the texture moved
--

local function heightAt(slope, flatheight, x, y)
	if slope and slope.valid then
		return P_GetZAt(slope, x, y)
	end
	return flatheight
end

local function floorAt(sector, x, y)
	return heightAt(sector.f_slope, sector.floorheight, x, y)
end

local function ceilingAt(sector, x, y)
	return heightAt(sector.c_slope, sector.ceilingheight, x, y)
end

local function fofTopAt(rover, x, y)
	return heightAt(rover.t_slope, rover.topheight, x, y)
end

local function fofBottomAt(rover, x, y)
	return heightAt(rover.b_slope, rover.bottomheight, x, y)
end

local function isSolidFOF(rover)
	return rover.fofflags & FOF_EXISTS ~= 0
		and rover.fofflags & (FOF_BLOCKPLAYER|FOF_BLOCKOTHERS) ~= 0
end

-- where a spot is compared to a line: how far along it (from v1) and how far out from it
local function positionFromLine(line, x, y)
	local dx, dy = line.v2.x - line.v1.x, line.v2.y - line.v1.y
	local length = R_PointToDist2(0, 0, dx, dy)
	local ux, uy = FixedDiv(dx, length), FixedDiv(dy, length)
	local rx, ry = x - line.v1.x, y - line.v1.y

	return FixedMul(rx, ux) + FixedMul(ry, uy), FixedMul(ry, ux) - FixedMul(rx, uy)
end

-- the opposite of positionFromLine, to find that same spot again after the line's moved
local function positionToLine(line, along, out)
	local dx, dy = line.v2.x - line.v1.x, line.v2.y - line.v1.y
	local length = R_PointToDist2(0, 0, dx, dy)
	local ux, uy = FixedDiv(dx, length), FixedDiv(dy, length)

	return line.v1.x + FixedMul(along, ux) - FixedMul(out, uy),
		line.v1.y + FixedMul(along, uy) + FixedMul(out, ux)
end

-- is this spot still beside the line, and not off past one of its ends?
local function isBesideLine(line, x, y)
	local along = positionFromLine(line, x, y)

	return along >= 0 and along <= R_PointToDist2(line.v1.x, line.v1.y, line.v2.x, line.v2.y)
end

--
-- deciding what to anchor to
--

local function anchorToLine(cast, line)
	cast.anchorLine = line
	cast.anchorAlong, cast.anchorOut = positionFromLine(line, cast.x, cast.y)

	-- so we can tell when the line moves
	cast.anchorV1X, cast.anchorV1Y = line.v1.x, line.v1.y
	cast.anchorV2X, cast.anchorV2Y = line.v2.x, line.v2.y
end

-- how high the plane we're anchored to is right now, at the hook
local function anchorPlaneHeight(cast)
	local rover = cast.anchorRover
	local sector = cast.anchorSector

	if rover then
		if cast.anchorPlane == "floor" then
			return fofTopAt(rover, cast.x, cast.y)
		end
		return fofBottomAt(rover, cast.x, cast.y)
	end

	if cast.anchorPlane == "floor" then
		return floorAt(sector, cast.x, cast.y)
	end
	return ceilingAt(sector, cast.x, cast.y)
end

-- crumbling fofs start to crumble when something grabs onto them, same as with knuckles
local function startCrumbling(cast, rover)
	if rover.fofflags & FOF_CRUMBLE == 0 then return end

	local player
	if cast.tracer and cast.tracer.valid then
		player = cast.tracer.player
	end

	EV_StartCrumble(rover.master.frontsector, rover,
		rover.fofflags & FOF_FLOATBOB ~= 0, player, rover.alpha,
		rover.fofflags & FOF_NORETURN == 0)
end

-- plane is which plane of the sector (or of the fof, if rover is given) to go up and
-- down with: "floor" for a floor or the top of a fof, "ceiling" for a ceiling or the
-- underside of a fof
local function anchorToPlane(cast, plane, sector, rover)
	cast.anchorPlane = plane
	cast.anchorSector = sector
	cast.anchorRover = rover
	cast.anchorHeight = anchorPlaneHeight(cast)

	if rover then
		startCrumbling(cast, rover)
	end
end

-- watches a wall's texture, to get carried along when it scrolls
local function anchorToWallTexture(cast, line, side)
	if not (side and side.valid) then return end

	cast.anchorSide = side
	cast.anchorSideLine = line
	cast.anchorSideX = side.textureoffset
	cast.anchorSideY = side.rowoffset
end

-- the polyobject the hook is on top of ("floor") or stuck under ("ceiling"), if any
local function findPolyobjectUnderHook(cast, plane, height)
	for i = 0, #polyobjects - 1 do
		local po = polyobjects[i]

		-- broken polyobjects have no lines, and asking one of those for its sector
		-- crashes the game
		if not po.lines.valid or #po.lines == 0 then continue end

		local sector = po.sector
		if not sector then continue end

		-- polyobjects are inside out: their top is their sector's ceiling
		local poheight = sector.floorheight
		if plane == "floor" then
			poheight = sector.ceilingheight
		end

		if poheight == height and po:pointInside(cast.x, cast.y) then
			return po
		end
	end
end

-- the sector whose floor or ceiling is at this height, out of the ones the hook is
-- touching. the hook can be over the edge of a few sectors at once, so the one its
-- middle is in isn't always the one it actually hit
local function findSectorUnderHook(cast, plane, height)
	local function matches(sector)
		if plane == "floor" then
			return floorAt(sector, cast.x, cast.y) == height
		end
		return ceilingAt(sector, cast.x, cast.y) == height
	end

	local middle = cast.subsector.sector
	if matches(middle) then return middle end

	local found
	local radius = cast.radius

	searchBlockmap("lines", function(_, line)
		-- only lines that actually cross the hook
		local x, y = P_ClosestPointOnLine(cast.x, cast.y, line)
		if abs(x - cast.x) > radius or abs(y - cast.y) > radius then return end
		if not isBesideLine(line, cast.x, cast.y) then return end

		if matches(line.frontsector) then
			found = line.frontsector
		elseif line.backsector and matches(line.backsector) then
			found = line.backsector
		end

		if found then return true end
	end, cast, cast.x - radius, cast.x + radius, cast.y - radius, cast.y + radius)

	return found or middle
end

-- the hook hit a floor or a ceiling
local function anchorToHitPlane(cast)
	local plane = "ceiling"
	local height = cast.ceilingz
	local rover = cast.ceilingrover

	if cast.z <= cast.floorz then
		plane = "floor"
		height = cast.floorz
		rover = cast.floorrover
	end

	local po = findPolyobjectUnderHook(cast, plane, height)

	if po then
		-- every line of a polyobject moves together, so any one of them will do
		anchorToLine(cast, po.lines[0])

		-- inside out, see findPolyobjectUnderHook
		if plane == "floor" then
			anchorToPlane(cast, "ceiling", po.sector)
		else
			anchorToPlane(cast, "floor", po.sector)
		end
		return
	end

	if rover then
		anchorToPlane(cast, plane, rover.target, rover)
	else
		anchorToPlane(cast, plane, findSectorUnderHook(cast, plane, height))
	end
end

-- the hook hit a wall. the wall itself can't go anywhere, but what it's the side of
-- can: a fof, or the edge of a floor or ceiling that goes up and down. its texture
-- can scroll, too
local function anchorToHitWall(cast, line)
	local front, back = line.frontsector, line.backsector
	local bottom, top = cast.z, cast.z + cast.height

	-- the side of a fof?
	for _, sector in ipairs({front, back}) do
		for rover in sector.ffloors() do
			if not isSolidFOF(rover) then continue end

			if bottom < fofTopAt(rover, cast.x, cast.y)
			and top > fofBottomAt(rover, cast.x, cast.y) then
				anchorToPlane(cast, "floor", sector, rover)
				-- the sides of a fof are drawn with its control line's texture
				anchorToWallTexture(cast, line, sides[rover.master.sidenum[0]])
				return
			end
		end
	end

	-- the side of the wall facing the hook
	anchorToWallTexture(cast, line, sides[line.sidenum[P_PointOnLineSide(cast.x, cast.y, line)]])

	if not back then return end

	-- the lower part of the wall, under the higher of the two floors
	local frontfloor = floorAt(front, cast.x, cast.y)
	local backfloor = floorAt(back, cast.x, cast.y)

	if bottom < max(frontfloor, backfloor) then
		anchorToPlane(cast, "floor", frontfloor > backfloor and front or back)
		return
	end

	-- the upper part of the wall, over the lower of the two ceilings
	local frontceiling = ceilingAt(front, cast.x, cast.y)
	local backceiling = ceilingAt(back, cast.x, cast.y)

	if top > min(frontceiling, backceiling) then
		anchorToPlane(cast, "ceiling", frontceiling < backceiling and front or back)
	end
end

-- call this once the hook has stuck to the level
function PoyoPennynickel.AnchorGrappleHook(cast)
	-- stuck to an object, it follows that already
	if cast.target and cast.target.valid then return end

	local line = cast.hitline
	if line and not line.valid then
		line = nil
	end

	if cast.hitsector then
		anchorToHitPlane(cast)
	elseif line and not line.polyobj then
		anchorToHitWall(cast, line)
	end

	if line and line.polyobj and not cast.anchorLine then
		anchorToLine(cast, line)
	end
end

--
-- following what we're anchored to
--

-- lets go of whatever we're anchored to, which makes the player let go of the hook too
local function loseAnchor(cast)
	cast.anchorLine = nil
	cast.anchorSector = nil
	cast.anchorRover = nil
	cast.anchorSide = nil
	cast.hitsector = false
	cast.hittics = 0
end

-- has a scrolling wall carried the hook off the end of the wall, or off the top or
-- bottom of it?
local function isOffTheWall(cast, x, y, z)
	if not isBesideLine(cast.anchorSideLine, x, y) then return true end

	local rover = cast.anchorRover

	if rover then
		return z >= fofTopAt(rover, x, y) or z + cast.height <= fofBottomAt(rover, x, y)
	end

	local sector = R_PointInSubsector(x, y).sector

	return z < floorAt(sector, x, y) or z + cast.height > ceilingAt(sector, x, y)
end

-- moves the hook along with whatever it's anchored to
local function followAnchor(cast)
	local x, y, z = cast.x, cast.y, cast.z
	local moved = false

	-- polyobjects
	local line = cast.anchorLine

	if line and line.valid
	and (line.v1.x ~= cast.anchorV1X or line.v1.y ~= cast.anchorV1Y
	or line.v2.x ~= cast.anchorV2X or line.v2.y ~= cast.anchorV2Y) then
		x, y = positionToLine(line, cast.anchorAlong, cast.anchorOut)
		moved = true

		cast.anchorV1X, cast.anchorV1Y = line.v1.x, line.v1.y
		cast.anchorV2X, cast.anchorV2Y = line.v2.x, line.v2.y
	end

	-- floors, ceilings and fofs
	if cast.anchorSector then
		local rover = cast.anchorRover

		-- the fof we were on is gone (crumbled, got turned off...)
		if rover and not (rover.valid and rover.fofflags & FOF_EXISTS ~= 0) then
			loseAnchor(cast)
			return
		end

		local height = anchorPlaneHeight(cast)

		if height ~= cast.anchorHeight then
			z = $ + height - cast.anchorHeight
			moved = true

			cast.anchorHeight = height
		end
	end

	-- scrolling walls
	local side = cast.anchorSide

	if side and side.valid
	and (side.textureoffset ~= cast.anchorSideX or side.rowoffset ~= cast.anchorSideY) then
		local wall = cast.anchorSideLine

		-- the same way the source carries knuckles: sideways towards the line's first
		-- vertex, and straight up
		local sideways = side.textureoffset - cast.anchorSideX
		local angle = R_PointToAngle2(wall.v2.x, wall.v2.y, wall.v1.x, wall.v1.y)

		x = $ + FixedMul(sideways, cos(angle))
		y = $ + FixedMul(sideways, sin(angle))
		z = $ + side.rowoffset - cast.anchorSideY
		moved = true

		cast.anchorSideX = side.textureoffset
		cast.anchorSideY = side.rowoffset

		if isOffTheWall(cast, x, y, z) then
			loseAnchor(cast)
			return
		end
	end

	if moved then
		P_MoveOrigin(cast, x, y, z)
	end
end

addHook("MobjThinker", function(cast)
	-- the player who shot us is gone (left the game, etc), so nobody's left to remove us
	if cast.inited and not (cast.tracer and cast.tracer.valid) then
		P_RemoveMobj(cast)
		return
	end

	local mo = cast.target

	if mo and mo.valid then
		P_MoveOrigin(cast, mo.x + cast.ox, mo.y + cast.oy, mo.z + cast.oz)
	elseif cast.anchorLine or cast.anchorSector or cast.anchorSide then
		followAnchor(cast)
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