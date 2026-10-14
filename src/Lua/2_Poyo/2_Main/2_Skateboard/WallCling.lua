-- Wall cling: hit a wall in the air while skating and Poyo sticks to it, sliding along it
-- with the speed the wall was hit with. That speed is carried from wall to wall, so the
-- slide follows corners and walls that tilt inwards or outwards.
--
-- How it works, every tic while clinging:
--   1. pickClingWall decides which wall we're on (stay, hop onto a wall in our way, or
--      carry on around the corner at the end of the wall)
--   2. slideAlongWall moves us along it and keeps us pressed against it
-- The direction of travel is remembered (clingDir) instead of being guessed from
-- momentum each tic, since the engine's wall sliding scrambles momentum all the time.
local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

Class.clingTime = 0 -- tics left before we let go; refilled while we have a wall
Class.clingSpeed = 0 -- how fast we slide along the wall
Class.clingDir = 0 -- the angle we're sliding towards
Class.clingLine = nil -- the wall we're sliding on
Class.clingBlockedTics = 0 -- how many tics in a row something has stopped our slide

local CLING_GRACE = 3 -- tics we can go without a wall before letting go
local CLING_REACH = 16 * FU -- how far from a wall we can be and still hold onto it
local CLING_TOUCH = 4 * FU -- how close counts as touching a wall
local CLING_HOVER = FU -- how far off the wall we slide, see slideAlongWall
local CLING_SPEED_KEEP = FU - FU / 17 -- speed kept each tic
local CLING_HOP = 5 * FU -- little hop when grabbing the wall
local CLING_LEDGE_BELOW = 16 * FU -- how far under the top of a wall our feet can be to climb over it
local CLING_LEDGE_ABOVE = 24 * FU -- how far over the top of a wall our feet can be to still land on it

--
-- can this wall be clung to?
--

local function isSkyPic(pic)
	return pic:upper():find("F_SKY") ~= nil
end

local function sectorFloorZAt(sec, x, y)
	if sec.f_slope and sec.f_slope.valid then
		return P_GetZAt(sec.f_slope, x, y)
	end
	return sec.floorheight
end

local function sectorCeilingZAt(sec, x, y)
	if sec.c_slope and sec.c_slope.valid then
		return P_GetZAt(sec.c_slope, x, y)
	end
	return sec.ceilingheight
end

local function ffloorTopZAt(rover, x, y)
	if rover.t_slope and rover.t_slope.valid then
		return P_GetZAt(rover.t_slope, x, y)
	end
	return rover.topheight
end

local function ffloorBottomZAt(rover, x, y)
	if rover.b_slope and rover.b_slope.valid then
		return P_GetZAt(rover.b_slope, x, y)
	end
	return rover.bottomheight
end

-- port of the source's P_IsClimbingValid; checks what's on the other side of
-- the wall to see if there's actually something to cling to (a ledge, a fof, etc)
local function isClimbingValid(mo, line)
	-- the source finds the sector behind the wall by poking a point through it, which
	-- misses on diagonal walls. we already know the line, so just take its far side
	local glidesector = line.frontsector
	if P_PointOnLineSide(mo.x, mo.y, line) == 0 then
		glidesector = line.backsector
	end

	if glidesector == mo.subsector.sector then return false end

	local flip = mo.eflags & MFE_VERTICALFLIP ~= 0
	local floorz = sectorFloorZAt(glidesector, mo.x, mo.y)
	local ceilingz = sectorCeilingZAt(glidesector, mo.x, mo.y)
	local step = 16 * mo.scale
	local floorclimb = false

	for rover in glidesector.ffloors() do
		if rover.fofflags & FOF_EXISTS == 0 or rover.fofflags & FOF_BLOCKPLAYER == 0 then continue end

		local topheight = ffloorTopZAt(rover, mo.x, mo.y)
		local bottomheight = ffloorBottomZAt(rover, mo.x, mo.y)

		floorclimb = true

		if flip then
			if topheight < mo.z then floorclimb = false end
			if bottomheight > mo.z + mo.height - step then floorclimb = false end
		else
			if bottomheight > mo.z + mo.height then floorclimb = false end
			if topheight < mo.z + step then floorclimb = false end
		end

		if floorclimb then break end
	end

	if flip then
		if floorz <= mo.z + mo.height
		and mo.z + mo.height - mo.momz <= floorz then
			floorclimb = true
		end

		if floorz > mo.z and isSkyPic(glidesector.floorpic) then
			return false
		end

		if mo.z + mo.height - step > ceilingz
		or mo.z + mo.height <= floorz then
			floorclimb = true
		end
	else
		if ceilingz >= mo.z
		and mo.z - mo.momz >= ceilingz then
			floorclimb = true
		end

		if ceilingz < mo.z + mo.height and isSkyPic(glidesector.ceilingpic) then
			return false
		end

		if mo.z + step < floorz
		or mo.z >= ceilingz then
			floorclimb = true
		end
	end

	return floorclimb
end

-- the angle that faces straight into the wall from where mo is
local function facingAngle(mo, line)
	return mo.poyoChar:getLineAngle(line)
end

-- are we actually in the space on our side of the line? lines get found by how close
-- they are, and a line can be right next to us while belonging to a ledge way above
-- or below, where we couldn't possibly be touching it
local function isOnOurLevel(mo, line)
	local sector = line.frontsector
	if P_PointOnLineSide(mo.x, mo.y, line) == 1 then
		sector = line.backsector
	end

	local step = 24 * mo.scale -- what the engine lets us step up onto

	return sectorFloorZAt(sector, mo.x, mo.y) <= mo.z + step
		and sectorCeilingZAt(sector, mo.x, mo.y) >= mo.z + mo.height - step
end

-- mirrors the source's PTR_GlideClimbTraverse checks for whether a line can be climbed
local function canClimbLine(mo, line)
	if line.flags & ML_NOCLIMB ~= 0 then return false end
	if line.special == 41 then return false end -- horizon line
	if P_CheckSkyHit(mo, line) then return false end
	if not isOnOurLevel(mo, line) then return false end

	-- one-sided lines are always climbable
	if not line.backsector then return true end

	return isClimbingValid(mo, line)
end

-- justblocked should only be true right after the engine failed to move us (PlayerBlocked).
-- P_LineIsBlocking measures the gap in the wall with whatever spot the engine last tried to
-- move something to, so anywhere else it's measuring for some other object and can't be trusted
local function isClingable(mo, line, justblocked)
	if not line.valid then return false end

	-- nothing to cling to from behind a one-sided line
	if line.sidenum[P_PointOnLineSide(mo.x, mo.y, line)] < 0 then return false end

	if justblocked and not P_LineIsBlocking(mo, line) then return false end

	return canClimbLine(mo, line)
end

-- the sector on the other side of the line from us
local function sectorBehindWall(mo, line)
	if P_PointOnLineSide(mo.x, mo.y, line) == 0 then
		return line.backsector
	end
	return line.frontsector
end

-- if we've slid up to the top of the wall, returns the height of the ground up there
-- (the floor behind the wall, or the top of a solid fof). upside down, that's a ceiling
local function findLedgeOverWall(mo, line)
	if not line.backsector then return end

	local sector = sectorBehindWall(mo, line)
	local flip = P_MobjFlip(mo)
	local feet = mo.z
	if flip == -1 then
		feet = mo.z + mo.height
	end

	local ledge

	-- keeps the highest ground our feet have reached (lowest, when upside down)
	local function check(height)
		local above = (feet - height) * flip -- how far our feet are over it

		if above < -FixedMul(CLING_LEDGE_BELOW, mo.scale) then return end
		if above > FixedMul(CLING_LEDGE_ABOVE, mo.scale) then return end

		if not ledge or (height - ledge) * flip > 0 then
			ledge = height
		end
	end

	local floorz = sectorFloorZAt(sector, mo.x, mo.y)
	local ceilingz = sectorCeilingZAt(sector, mo.x, mo.y)

	check(flip == 1 and floorz or ceilingz)

	for rover in sector.ffloors() do
		if rover.fofflags & FOF_EXISTS == 0 or rover.fofflags & FOF_BLOCKPLAYER == 0 then continue end

		if flip == 1 then
			check(ffloorTopZAt(rover, mo.x, mo.y))
		else
			check(ffloorBottomZAt(rover, mo.x, mo.y))
		end
	end

	if not ledge then return end

	-- no good if we wouldn't fit up there
	local height = P_GetPlayerHeight(mo.player)
	if flip == 1 and ceilingz - ledge < height then return end
	if flip == -1 and ledge - floorz < height then return end

	return ledge
end

--
-- where are we compared to a wall?
--

local function lineAngle(line)
	return R_PointToAngle2(line.v1.x, line.v1.y, line.v2.x, line.v2.y)
end

-- how far the player's hitbox reaches along an angle (it's a square, not a circle,
-- so it reaches further diagonally)
local function hitboxReach(mo, angle)
	return FixedMul(mo.radius, abs(cos(angle)) + abs(sin(angle)))
end

-- how far along the wall the player is (starting from v1), and how long the wall is
local function positionAlongWall(mo, line)
	local angle = lineAngle(line)
	local along = FixedMul(mo.x - line.v1.x, cos(angle)) + FixedMul(mo.y - line.v1.y, sin(angle))
	local length = R_PointToDist2(line.v1.x, line.v1.y, line.v2.x, line.v2.y)

	return along, length
end

-- is the player beside the wall itself, and not off past one of its ends?
-- with hitboxtoo, it's enough for any part of our hitbox to be beside it
local function isAlongsideWall(mo, line, hitboxtoo)
	local along, length = positionAlongWall(mo, line)
	local slack = 0

	if hitboxtoo then
		slack = hitboxReach(mo, lineAngle(line))
	end

	return along >= -slack and along <= length + slack
end

-- space between the player's hitbox and the wall, as if the wall went on forever
local function gapToWallSurface(mo, line)
	local x, y = P_ClosestPointOnLine(mo.x, mo.y, line)

	return R_PointToDist2(mo.x, mo.y, x, y) - hitboxReach(mo, facingAngle(mo, line))
end

-- space between the player's hitbox and the wall, about zero when touching it
local function gapToWall(mo, line)
	local along, length = positionAlongWall(mo, line)

	if along >= 0 and along <= length then
		return gapToWallSurface(mo, line)
	end

	-- off the end of the wall, so measure to the corner
	local corner = along < 0 and line.v1 or line.v2
	return R_PointToDist2(mo.x, mo.y, corner.x, corner.y) - hitboxReach(mo, facingAngle(mo, line))
end

-- every clingable wall within reach of the player
local function nearbyClingWalls(mo, reach, justblocked)
	local walls = {}
	local range = mo.radius * 2 + reach

	searchBlockmap("lines", function(_, line)
		if isClingable(mo, line, justblocked) and gapToWall(mo, line) <= reach then
			table.insert(walls, line)
		end
	end, mo, mo.x - range, mo.x + range, mo.y - range, mo.y + range)

	return walls
end

-- moves the player by hand, a little at a time. returns false if something blocked us.
-- we can't leave fast moves to the engine: it breaks them up into steps of up to a whole
-- radius on each axis separately, so along a diagonal wall the first step cuts sideways
-- into the wall and the whole move gets thrown out. steps this small go in a straight line
local function moveInSteps(mo, movex, movey)
	local stepsize = mo.radius / 2
	local steps = max(abs(movex), abs(movey)) / stepsize + 1

	for i = 1, steps do
		if not P_TryMove(mo, mo.x + movex / steps, mo.y + movey / steps, true) then
			return false
		end
		if not mo.valid then return false end
	end

	return true
end

--
-- which way are we sliding?
--

local function sameSpot(vertex1, vertex2)
	return vertex1.x == vertex2.x and vertex1.y == vertex2.y
end

local function touchesVertex(line, vertex)
	return sameSpot(line.v1, vertex) or sameSpot(line.v2, vertex)
end

-- the end of the wall we're sliding towards
local function wallEndAhead(line, dir)
	if cos(dir - lineAngle(line)) >= 0 then
		return line.v2
	end
	return line.v1
end

-- have we slid completely off the end of the wall?
local function isPastWallEnd(mo, line, dir)
	local corner = wallEndAhead(line, dir)
	local distleft = FixedMul(corner.x - mo.x, cos(dir)) + FixedMul(corner.y - mo.y, sin(dir))

	-- wait for the whole hitbox to clear the corner, or we'd snag on it going around
	return distleft < -hitboxReach(mo, dir)
end

-- the angle to slide along a wall with.
-- coming from another wall that it shares a corner with, we keep going away from that corner.
-- otherwise we go whichever way is closest to where we were already heading.
local function slideAngle(line, heading, fromline)
	local angle = lineAngle(line)

	if fromline then
		if touchesVertex(fromline, line.v1) then return angle end
		if touchesVertex(fromline, line.v2) then return angle + ANGLE_180 end
	end

	if cos(heading - angle) < 0 then
		angle = $ + ANGLE_180
	end
	return angle
end

-- is this a wall we'd slam into this tic if we kept sliding? (what an inwards corner looks like)
-- blocked is whether our slide just got stopped by something. then we know there's a wall
-- in the way, so the corner of our hitbox clipping the end of it is enough to count
local function isWallInOurWay(mo, line, dir, speed, blocked)
	-- how much of our sliding is heading into this wall
	local into = cos(dir - facingAngle(mo, line))
	if into <= 0 then return false end

	local reach = FixedMul(CLING_TOUCH, mo.scale) + FixedMul(speed, into)

	return isAlongsideWall(mo, line, blocked) and gapToWall(mo, line) <= reach
end

-- the wall that carries on from the end of the one we just slid off (an outwards corner),
-- picking the one that turns us the least if there's several
local function findWallAroundCorner(walls, current, dir)
	local corner = wallEndAhead(current, dir)
	local best, bestturn

	for _, wall in ipairs(walls) do
		if wall == current then continue end
		if not touchesVertex(wall, corner) then continue end

		local turn = cos(dir - slideAngle(wall, dir, current))

		if not best or turn > bestturn then
			best = wall
			bestturn = turn
		end
	end

	return best
end

-- the closest wall we're beside, other than the one we're on. for when we slid off the end
-- of our wall so fast that we skipped right past the wall joined to it
local function findNearestWall(mo, walls, current)
	local best, bestgap

	for _, wall in ipairs(walls) do
		if wall == current then continue end
		if not isAlongsideWall(mo, wall) then continue end

		local gap = gapToWall(mo, wall)

		if not best or gap < bestgap then
			best = wall
			bestgap = gap
		end
	end

	return best
end

--
-- debugging: type "poyo_clingdebug on" in the console to print what the cling is doing
--

-- local cv_debug = CV_RegisterVar({
-- 	name = "poyo_clingdebug",
-- 	defaultvalue = "Off",
-- 	PossibleValue = CV_OnOff
-- })

local function debugging()
	return false -- cv_debug.value ~= 0
end

local function debugPrint(mo, text)
	if not debugging() then return end

	print(string.format("[cling %d] %s | x %d y %d z %d momz %d",
		leveltime, text, mo.x / FU, mo.y / FU, mo.z / FU, mo.momz / FU))
end

-- why a wall can't be clung to right now, or nil if it can
local function whyNotClingable(mo, line, justblocked)
	if not line.valid then return "line is gone" end
	if line.sidenum[P_PointOnLineSide(mo.x, mo.y, line)] < 0 then return "we're behind it" end
	if line.flags & ML_NOCLIMB ~= 0 then return "it's marked not climbable" end
	if line.special == 41 then return "it's a horizon line" end
	if P_CheckSkyHit(mo, line) then return "it's a sky wall" end
	if not isOnOurLevel(mo, line) then return "it belongs to a floor above or below us" end
	if line.backsector and not isClimbingValid(mo, line) then return "nothing behind it to hold at this height" end
	if justblocked and not P_LineIsBlocking(mo, line) then return "it doesn't block us (we fit through or over it)" end
end

-- prints every line around us and whether we could grab it, for when a grab fails
local function debugNearbyLines(mo, heading, grabreach)
	if not debugging() then return end

	local reach = max(grabreach, FixedMul(CLING_REACH, mo.scale))
	local range = mo.radius * 2 + reach

	searchBlockmap("lines", function(_, line)
		local gap = gapToWall(mo, line)
		if gap > reach then return end

		local why = whyNotClingable(mo, line, true)

		if not why and gap > grabreach then
			why = "too far to grab"
		elseif not why and not isAlongsideWall(mo, line) then
			why = "we're past the end of it"
		elseif not why and cos(heading - facingAngle(mo, line)) <= 0 then
			why = "we weren't moving into it"
		end

		print(string.format("    line %d: %s (gap %d)", #line, why or "could grab", gap / FU))
	end, mo, mo.x - range, mo.x + range, mo.y - range, mo.y + range)
end

--
-- the cling itself
--

function Class:isClinging()
	return self.mo.state == S_PLAY_POYO_SKATEBOARD_CLING
end

-- decides which wall we slide on this tic. returns nil if we've run out of wall
function Class:pickClingWall()
	local mo = self.mo
	local current = self.clingLine
	local dir = self.clingDir
	local speed = self.clingSpeed

	-- we can be a whole tic of sliding away from the wall we want, so look that far
	local walls = nearbyClingWalls(mo, FixedMul(CLING_REACH, mo.scale) + speed)
	local stillthere = false
	local blocked = self.clingBlockedTics > 0
	local inway, inwaygap

	for _, wall in ipairs(walls) do
		if wall == current then
			stillthere = true
		elseif isWallInOurWay(mo, wall, dir, speed, blocked) then
			local gap = gapToWall(mo, wall)

			if not inway or gap < inwaygap then
				inway = wall
				inwaygap = gap
			end
		end
	end

	-- inwards corner: hop onto the wall we're about to run into
	if inway then return inway end

	if not stillthere then return end

	-- outwards corner: carry on around it
	if isPastWallEnd(mo, current, dir) then
		return findWallAroundCorner(walls, current, dir)
			or findNearestWall(mo, walls, current)
	end

	return current
end

-- explains why pickClingWall came up empty, for debugging
function Class:whyNoClingWall()
	local mo = self.mo
	local current = self.clingLine
	local why = whyNotClingable(mo, current)

	if why then
		return "can't hold line " .. #current .. ": " .. why
	end

	local gap = gapToWall(mo, current)

	if gap > FixedMul(CLING_REACH, mo.scale) + self.clingSpeed then
		return "too far from line " .. #current .. " (gap " .. gap / FU .. ")"
	end

	return "slid off the end of line " .. #current .. " and found no wall to carry on with"
end

-- we move by hand while clinging (see slideAlongWall), so our real momentum is zero.
-- this hands our sliding speed back as momentum, for whatever comes after the cling
function Class:restoreClingMomentum()
	P_InstaThrust(self.mo, self.clingDir, self.clingSpeed)
	self:refreshPlayerSpeed()
end

-- the engine only works out how fast the player is going once a tic, before we get to run.
-- if we give ourselves momentum after that, it still thinks we're standing still, and on
-- the ground it stops players who are standing still. so tell it our new speed ourselves
function Class:refreshPlayerSpeed()
	local mo = self.mo
	local player = mo.player

	player.rmomx = mo.momx - player.cmomx
	player.rmomy = mo.momy - player.cmomy
	player.speed = R_PointToDist2(0, 0, player.rmomx, player.rmomy)
end

-- moves us along the wall at our cling speed, keeping us right beside it
function Class:slideAlongWall(line)
	local mo = self.mo
	local player = mo.player
	local facing = facingAngle(mo, line)

	player.drawangle = facing
	player.powers[pw_pushing] = 5

	-- move in (or out) to sit a hair off the wall, which keeps us on walls that tilt away
	local push = gapToWallSurface(mo, line) - FixedMul(CLING_HOVER, mo.scale)
	local speed = self.clingSpeed
	local dir = self.clingDir

	local movex = FixedMul(speed, cos(dir)) + FixedMul(push, cos(facing))
	local movey = FixedMul(speed, sin(dir)) + FixedMul(push, sin(facing))

	-- no momentum, or the engine would move us a second time
	mo.momx = 0
	mo.momy = 0

	if moveInSteps(mo, movex, movey) then
		self.clingBlockedTics = 0
	else
		self.clingBlockedTics = $ + 1
	end

	if not S_SoundPlaying(mo, sfx_s3k55) then
		S_StartSoundAtVolume(mo, sfx_s3k55, 50)
	end
end

-- grabs onto a wall we just ran into, if there is one, and returns whether we did.
-- momx and momy are what we hit it with. only call this from PlayerBlocked (see isClingable)
function Class:tryStartCling(momx, momy)
	local mo = self.mo
	local player = mo.player
	local heading = R_PointToAngle2(0, 0, momx, momy)
	local speed = R_PointToDist2(0, 0, momx, momy)

	-- when a fast move gets blocked, the engine doesn't always carry us all the way up to
	-- the wall. so instead of only walls we're touching, take any wall we'd have reached this tic
	local grabreach = FixedMul(CLING_TOUCH, mo.scale) + speed

	-- out of those walls, take the one we ran into the most head on
	local line, linehit

	for _, wall in ipairs(nearbyClingWalls(mo, grabreach, true)) do
		local hit = cos(heading - facingAngle(mo, wall))

		if hit > 0 and isAlongsideWall(mo, wall)
		and (not line or hit > linehit) then
			line = wall
			linehit = hit
		end
	end

	if not line then
		debugPrint(mo, "hit something, but found no wall to grab:")
		debugNearbyLines(mo, heading, grabreach)
		return false
	end

	-- only the speed going along the wall is kept
	self.clingLine = line
	self.clingDir = slideAngle(line, heading)
	self.clingSpeed = FixedMul(speed, cos(heading - self.clingDir))
	self.clingTime = CLING_GRACE
	self.clingBlockedTics = 0

	mo.state = S_PLAY_POYO_SKATEBOARD_CLING
	P_SetObjectMomZ(mo, CLING_HOP, true)
	player.pflags = $ & ~PF_STARTJUMP
	player.drawangle = facingAngle(mo, line)

	S_StartSound(mo, sfx_s3k4a)

	debugPrint(mo, "grabbed line " .. #line .. " at speed " .. self.clingSpeed / FU)

	-- the move that got blocked never happened, so start sliding right now instead of
	-- hanging in the air for a tic
	self:slideAlongWall(line)

	return true
end

function Class:stopCling()
	local mo = self.mo

	if self:isClinging() then
		mo.state = S_PLAY_FALL
		self:restoreClingMomentum()
	end

	self.clingLine = nil
	self.clingTime = 0
end

-- climbs over the top of the wall onto the ledge behind it, turning whatever speed we had
-- going up into speed going forwards. returns false if something's in the way up there
function Class:climbOverWall(line, ledge)
	local mo = self.mo
	local player = mo.player
	local facing = facingAngle(mo, line)
	local flip = P_MobjFlip(mo)
	local rising = max(0, mo.momz * flip)

	-- stand at the height of the ledge, then step forwards until we're over the edge of it
	local oldz = mo.z
	local step = max(0, gapToWallSurface(mo, line)) + mo.radius

	mo.z = ledge
	if flip == -1 then
		mo.z = ledge - mo.height
	end

	if not P_TryMove(mo, mo.x + FixedMul(step, cos(facing)), mo.y + FixedMul(step, sin(facing)), true) then
		mo.z = oldz
		return false
	end

	debugPrint(mo, "climbed over line " .. #line .. ", turning " .. rising / FU .. " speed upwards into speed forwards")

	-- we're on the ground now, so act like it
	mo.momz = 0
	mo.state = S_PLAY_WALK
	player.pflags = $ & ~(PF_JUMPED|PF_STARTJUMP|PF_THOKKED|PF_SPINNING)

	self:restoreClingMomentum()
	P_Thrust(mo, facing, rising)
	self:refreshPlayerSpeed()

	self.clingLine = nil
	self.clingTime = 0

	return true
end

function Class:updateCling()
	local mo = self.mo

	-- something else took us off the wall (jumping, getting hurt, landing...)
	if not self:isClinging() then
		if self.clingLine and P_IsObjectOnGround(mo) then
			debugPrint(mo, "let go: landed")
			self:restoreClingMomentum()
		elseif self.clingLine then
			debugPrint(mo, "let go: something else changed our state to " .. mo.state)
		end

		self.clingLine = nil
		self.clingTime = 0
		return
	end

	if P_IsObjectOnGround(mo) or not (self.clingLine and self.clingLine.valid) then
		debugPrint(mo, "let go: landed")
		self:stopCling()
		return
	end

	-- made it to the top of the wall?
	local ledge = findLedgeOverWall(mo, self.clingLine)

	if ledge and self:climbOverWall(self.clingLine, ledge) then
		return
	end

	local line = self:pickClingWall()

	if line then
		if line ~= self.clingLine then
			debugPrint(mo, "moved from line " .. #self.clingLine .. " to line " .. #line)
			self.clingDir = slideAngle(line, $, self.clingLine)
			self.clingLine = line
			self.clingBlockedTics = 0
		end

		-- stuck against something we can't cling to. let go, don't just hang there
		if self.clingBlockedTics >= CLING_GRACE then
			debugPrint(mo, "let go: something we can't cling to is in the way")
			self:stopCling()
			return
		end

		self.clingTime = CLING_GRACE
		self:slideAlongWall(line)
	else
		-- no wall this tic. keep going the same way for a moment before letting go,
		-- so a tiny gap in the wall doesn't make us drop and grab it again
		self.clingTime = $ - 1

		if debugging() then
			debugPrint(mo, self:whyNoClingWall() .. " (letting go in " .. self.clingTime .. ")")
		end

		if self.clingTime <= 0 then
			debugPrint(mo, "let go: ran out of wall")
			self:stopCling()
			return
		end

		P_InstaThrust(mo, self.clingDir, self.clingSpeed)
	end

	self.clingSpeed = FixedMul($, CLING_SPEED_KEEP)
end

PoyoPennynickel:addScript("PlayerMobjUpdate", function(player)
	local class = player.mo.poyoChar

	if not class.skateboard then return end

	class:updateCling()
end)

-- code somewhat inspired by mario bros since their wall cling works amazingly
PoyoPennynickel:addScript("PlayerBlocked", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if not class.skateboard then return end
	if P_IsObjectOnGround(mo) then return end

	-- while clinging we move ourselves along the wall (see slideAlongWall), so this is only
	-- the few tics of coasting after running out of wall. nothing to do but wait those out
	if class:isClinging() then return true end

	if not class:tryStartCling(mo.momx, mo.momy) then
		P_SlideMove(mo)
	end

	return true
end)
