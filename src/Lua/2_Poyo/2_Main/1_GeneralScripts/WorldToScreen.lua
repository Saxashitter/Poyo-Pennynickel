-- GetScreenCoords.lua
-- World -> screen projection for SRB2 2.2.x HUD hooks.
--
-- Mirrors what the renderers do in R_SetupFrame / R_InterpolateView /
-- R_SetupFreelook / R_ProjectSprite / R_CheckViewMorph (Software) and
-- HWR_SetupView / SetTransform / GLPerspective (OpenGL), so it handles:
--   * Software (y-shearing, clamped aiming) and OpenGL (true pitch, or
--     gr_shearing on / third-person)
--   * the fov cvar, player.fovadd, and the splitscreen FOV adjustments
--     (which are different in each renderer)
--   * chasecam, first person and awayviewmobj viewpoints
--   * player.viewrollangle (Software view morph incl. its zoom, OpenGL roll)
--   * the upside-down screen from reverse gravity (first person / flipcam)
--   * splitscreen (half-height views, second view offset)
--   * any resolution / aspect ratio (green or non-green)
--
-- Usage:
--   addHook("HUD", function(v, player, camera)
--       local pos = GetScreenCoords(v, player, camera, target)
--       if not pos.visible then return end
--       v.drawScaled(pos.x, pos.y, pos.scale, patch)
--   end)
--
-- target is a mobj_t, a player_t (uses its mobj), or any table with x, y, z
-- in fixed-point map units.
--
-- opts (optional table):
--   zoffset     = fixed_t added to the target z (e.g. mo.height/2)
--   margin      = pixels to inset edgex/edgey from the view border (default 0)
--
-- Returned table:
--   visible   in front of the view AND inside the view's rectangle
--   front     in front of the view plane (false = behind you)
--   onscreen  inside the view's rectangle (only meaningful if front)
--   x, y      fixed-point 320x200 HUD coordinates. Use with v.drawScaled and
--             NO V_SNAPTO* / V_PERPLAYER flags; for the integer functions
--             (v.draw, v.drawString, ...) use x/FRACUNIT, y/FRACUNIT.
--   px, py    the same point in real screen pixels (fixed-point), for
--             V_NOSCALESTART drawing.
--   scale     fixed-point scale that makes a patch drawn with v.drawScaled
--             the size a scale-1 sprite would be at that spot. Multiply by
--             the mobj's scale to match its sprite.
--   depth     distance along the view axis (what sprites sort by)
--   distance  true 3D distance from the viewpoint
--   edgex, edgey   x/y clamped onto the border of the view (for off-screen
--             indicators); equal to x/y while visible. edgepx/edgepy are the
--             pixel versions.
--   dir       angle_t on the screen from the view centre towards the target
--             (0 = right, ANGLE_90 = up), valid even when it is behind you
--   flipped   the view is drawn upside-down (reverse gravity)
--   roll      the view roll that was applied (angle_t)
--   viewx, viewy, viewz, viewangle, viewaiming   the viewpoint that was used
--
-- What Lua cannot see, and therefore cannot account for:
--   * P_StartQuake / earthquake shake (random per frame, not exposed)
--   * the underwater / heat-haze wobble in Software (a few pixels sideways)
--   * skybox and portal views (it always projects for the main view)
-- With uncapped framerate the view is not interpolated, so results are
-- tic-rate positions and may lag the rendered frame slightly.
-- The C version (r_worldtoscreen.c) reads the renderer's own view, so it
-- covers all of these except portals.

local FU = FRACUNIT
local BASEVIDWIDTH, BASEVIDHEIGHT = 320, 200
local AIMLIMIT = ANGLE_90 - ANG10 -- G_SoftwareClipAimingPitch
local MINFOV, MAXFOV = 60*FU, 179*FU
local MINZ = 4*FU      -- Software sprite near plane
local GLNEARZ = FU     -- OpenGL near plane is 0.9
local MAXRELPIXELS = 8000 -- keeps everything inside 32-bit fixed-point

-- cvars ---------------------------------------------------------------------

local cvcache = {}
local function cvarvalue(name, default)
	local cv = cvcache[name]
	if cv == nil then
		cv = CV_FindVar(name) or false
		cvcache[name] = cv
	end
	if cv then return cv.value end
	return default
end

-- local look angles -----------------------------------------------------------
-- First person renders with localangle/localaiming rather than the (possibly
-- lagged) player angles. PlayerCmd sees the same values, 16 bits coarser.

local locallook = {{angle = 0, aiming = 0}, {angle = 0, aiming = 0}}

addHook("PlayerCmd", function(player, cmd)
	local l = locallook[1]

	if splitscreen and player == secondarydisplayplayer then
		l = locallook[2]
	end

	l.angle = cmd.angleturn << 16
	l.aiming = cmd.aiming << 16
end)

--- viewpoint (R_SetupFrame)
--- Returns the current-tic viewpoint as {x, y, z, angle, aim}, or nil.
local function getView(player, cam)
	local mo = player.mo
	local away = player.awayviewmobj

	if player.awayviewtics and away and away.valid then
		return {
			x = away.x,
			y = away.y,
			z = away.z + 20*FU,
			angle = away.angle,
			aim = player.awayviewaiming
		}

	elseif cam.chase and not player.spectator then
		return {
			x = cam.x,
			y = cam.y,
			z = cam.z + cam.height/2,
			angle = cam.angle,
			aim = cam.aiming
		}
	end

	if not (mo and mo.valid) then return nil end

	local st = {
		x = mo.x,
		y = mo.y,
		z = player.viewz,
		angle = mo.angle,
		aim = player.aiming
	}

	local l = locallook[1]
	if splitscreen and player == secondarydisplayplayer then
		l = locallook[2]
	end

	if l and player.playerstate ~= PST_DEAD
	and (player == consoleplayer or player == secondarydisplayplayer)
	and abs(l.angle - mo.angle) < ANGLE_45 then
		st.angle, st.aim = l.angle, l.aiming
	end

	return st
end

-- projection ------------------------------------------------------------------

local function clampaim(aim)
	if aim > AIMLIMIT then return AIMLIMIT end
	if aim < -AIMLIMIT then return -AIMLIMIT end

	return aim
end

local function isflipped(player, cam)
	local mo = player.mo

	if not (mo and mo.valid) or (mo.eflags & MFE_VERTICALFLIP) == 0 then
		return false
	end

	if cam.chase then -- P_CalcChasePostImg
		return (player.pflags & PF_FLIPCAM) ~= 0
			and player.powers[pw_carry] ~= CR_NIGHTSMODE
	end

	return true -- P_CalcPostImg
end

local function GetScreenCoords(v, player, cam, target, opts)
	if not (player and player.valid) then return end
	cam = $ or camera

	local view = getView(player, cam)
	local wx, wy, wz = target.x, target.y, target.z

	if not view or wx == nil then return end

	if opts and opts.zoffset then wz = $ + opts.zoffset end

	local opengl = (v.renderer() == "opengl")
	local w, h = v.width(), v.height()
	local dup = v.dupx()
	local split = splitscreen and true or false
	local second = split and player == secondarydisplayplayer

	-- R_ExecuteSetViewSize
	local viewh = split and h/2 or h
	local viewtop = second and h/2 or 0
	local centerxfrac = (w/2)*FU
	local centeryfrac = (viewh/2)*FU

	local fov = cvarvalue("fov", 90*FU) + player.fovadd -- R_GetPlayerFov
	fov = max(MINFOV, min($, MAXFOV))
	local tanfov = tan(FixedAngle(fov/2))

	local flipped = isflipped(player, cam)
	local aim = view.aim

	-- world -> view space
	local dx, dy, dz = wx - view.x, wy - view.y, wz - view.z
	local vcos, vsin = cos(view.angle), sin(view.angle)
	local tz = FixedMul(dx, vcos) + FixedMul(dy, vsin) -- forwards
	local tx = FixedMul(dx, vsin) - FixedMul(dy, vcos) -- right
	local ty = dz                                      -- up

	local fovtan, proj, zoom, nearz
	local roll, rollcos, rollsin = 0, FU, 0
	-- y-shearing, in tan units. Software shears the image before the roll and
	-- flip post-processing; in OpenGL it is a projection-matrix translate, so
	-- it lands after them.
	local shear

	if opengl then
		local shearing = cvarvalue("gr_shearing", 0)

		if shearing == 1 or (shearing == 2 and cam.chase) then
			shear = tan(clampaim(aim))
		else
			-- real pitch rotation
			local pcos, psin = cos(aim), sin(aim)
			ty, tz = FixedMul(pcos, ty) - FixedMul(psin, tz),
				FixedMul(psin, ty) + FixedMul(pcos, tz)
			shear = 0
		end

		-- SetTransform: splitscreen is tan(fov/2)*0.8 at a 2:1 aspect
		fovtan = split and (tanfov*8)/5 or tanfov
		centerxfrac = (w*FU)/2
		centeryfrac = (viewh*FU)/2
		zoom = FU
		nearz = GLNEARZ
		roll = player.viewrollangle

	else
		shear = tan(clampaim(aim))
		zoom = FU

		if not split then
			-- R_CheckViewMorph: roll is quantised, and the view zooms in
			-- far enough that the rotated image still covers the screen
			roll = (player.viewrollangle + 0x100000) & ~0x1FFFFF

			if roll ~= 0 then
				local c, s = abs(cos(roll)), abs(sin(roll))
				zoom = max(c + (s*h)/w, c + (s*w)/h)
				if zoom < FU then zoom = FU else zoom = $ | 0x3FFF end
			end
		end

		fovtan = FixedMul(tanfov, zoom) -- R_SetFov
		if split then fovtan = 17*$/10 end

		nearz = MINZ
	end

	if roll ~= 0 then
		rollcos, rollsin = cos(roll), sin(roll)
	end

	proj = FixedDiv(centerxfrac, fovtan) -- pixels per unit of tx/tz

	-- relx/rely: pixels right/down of the view centre, before roll and flip
	local relx, rely
	local front = tz >= nearz
	local wild = not front

	if front then
		if (abs(tx) >> 14) >= tz or (abs(ty) >> 14) >= tz then
			wild = true
		else
			local limit = FixedDiv(MAXRELPIXELS*FU, proj)
			local rx, ry = FixedDiv(tx, tz), -FixedDiv(ty, tz)
		
			if not opengl then
				ry = $ + shear
			end
	
			if abs(rx) > limit or abs(ry) > limit then
				wild = true
			else
				relx, rely = FixedMul(rx, proj), FixedMul(ry, proj)
			end
		end
	end

	if wild then
		-- Behind the view or absurdly far off to the side: there is no
		-- sensible projection, so just point firmly in its direction.
		local a = R_PointToAngle2(0, 0, tx, ty)
		local far = (w + h)*FU

		relx, rely = FixedMul(cos(a), far), -FixedMul(sin(a), far)
	end

	if roll ~= 0 then
		relx, rely = FixedMul(rollcos, relx) + FixedMul(rollsin, rely),
			FixedMul(rollcos, rely) - FixedMul(rollsin, relx)
		if zoom ~= FU then
			relx, rely = FixedMul(relx, zoom), FixedMul(rely, zoom)
		end
	end

	local px = centerxfrac + relx
	local py

	if opengl then
		if flipped then
			rely = -$
		end

		if not wild then
			rely = $ + FixedMul(flipped and -shear or shear, proj)
		end

		py = viewtop*FU + centeryfrac + rely
	else
		py = viewtop*FU + centeryfrac + rely

		if flipped then -- V_DoPostProcessor mirrors the rows of the view
			py = (2*viewtop + viewh - 1)*FU - $
		end
	end

	local onscreen = px >= 0 and px < w*FU
		and py >= viewtop*FU and py < (viewtop + viewh)*FU
	local visible = front and not wild and onscreen

	-- clamp to the border of the view for off-screen indicators
	local margin = ((opts and opts.margin) or 0)*FU
	local midx, midy = (w*FU)/2, viewtop*FU + (viewh*FU)/2
	local ex, ey = px - midx, py - midy
	local edgepx, edgepy = px, py

	if not visible then
		local halfw = max(FU, (w*FU)/2 - margin)
		local halfh = max(FU, (viewh*FU)/2 - margin)
		local t = FU

		if abs(ex) > halfw then
			t = FixedDiv(halfw, abs(ex))
		end

		if abs(ey) > halfh then
			t = min($, FixedDiv(halfh, abs(ey)))
		end

		edgepx, edgepy = midx + FixedMul(ex, t), midy + FixedMul(ey, t)
	end

	-- pixels -> 320x200 HUD coordinates (the inverse of V_DrawStretchyFixedPatch)
	local basex = ((w - BASEVIDWIDTH*dup)/2)*FU
	local basey = ((h - BASEVIDHEIGHT*dup)/2)*FU

	local depth = tz
	local scale = 0

	if front and not wild then
		scale = FixedMul(FixedDiv(proj, depth), zoom)/dup
	end

	return {
		visible = visible,
		front = front,
		onscreen = onscreen,
		x = (px - basex)/dup,
		y = (py - basey)/dup,
		px = px,
		py = py,
		scale = scale,
		depth = depth,
		distance = FixedHypot(FixedHypot(dx, dy), dz),
		edgex = (edgepx - basex)/dup,
		edgey = (edgepy - basey)/dup,
		edgepx = edgepx,
		edgepy = edgepy,
		dir = R_PointToAngle2(0, 0, ex, -ey),
		flipped = flipped,
		roll = roll,
		viewx = view.x,
		viewy = view.y,
		viewz = view.z,
		viewangle = view.angle,
		viewaiming = aim,
	}
end

PoyoPennynickel.WorldToScreen = GetScreenCoords