freeslot(
	"MT_POYOZE2_BASEBALLBAT",
	"S_POYOZE2_BASEBALLBAT",
	"SPR_POYOZE2_BAT"
)

local poyo_batattack = freeslot("sfx_py_bsw")
local poyo_bathit = freeslot("sfx_py_bat")

sfxinfo[poyo_batattack].caption = "Swing"
sfxinfo[poyo_bathit].caption = "Hit"

local ZE2_LOADED = false
local GUTIL_LOADED = false

local function onZE2Load()
	if not ZE2 then return end
	if ZE2_LOADED then return end

	ZE2_LOADED = true

	// ===========
	// == ITEMS ==
	// ===========

	// Baseball Bat behavior
	// Poyo's only reliable weapon. Packs quite a punch, yet can't be used ranged.

	mobjinfo[MT_POYOZE2_BASEBALLBAT] = {
		doomednum = -1,
		spawnhealth = 1,
		spawnstate = S_POYOZE2_BASEBALLBAT,
		radius = 64*FRACUNIT,
		height = 24*FRACUNIT,
		flags = MF_NOGRAVITY|MF_NOCLIPHEIGHT,
		dispoffset = 3,
	}

	states[S_POYOZE2_BASEBALLBAT] = {
		sprite = SPR_POYOZE2_BAT,
		frame = A|FF_FULLBRIGHT|FF_FLOORSPRITE,
		tics = 12, // duration
	}

	local function updBaseballBat(instaburst)
		local t = instaburst.target
		local div = FixedDiv(instaburst.tics, states[instaburst.state].tics)
		local ang = 45*FU
		local twn = ease.incubic(div, ang, -ang)
		
		instaburst.renderflags = $|RF_NOSPLATBILLBOARD
		if t and t.valid then
			local offset = 48 * t.scale
			local angle = FixedAngle(AngleFixed(t.angle) + twn)
			local x = P_ReturnThrustX(nil, angle, offset)
			local y = P_ReturnThrustY(nil, angle, offset)

			P_MoveOrigin(instaburst, t.x + x, t.y + y, t.z + t.height / 2)
			instaburst.angle = angle
		end
	end

	xSlinger.registerItem("poyo_baseball_bat", {
		-- HUD
		displayname = "Baseball Bat",
		icon = "ZMISHIND",
		color = SKINCOLOR_RED,
		
		-- Item properties
		delay = 35,
		damage = 45,
		droppable = false,
		sounds = {
			use = {poyo_batattack},
			hurt = {poyo_bathit},
		},
		usefunc = function(self, mo)
			local instaburst = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_POYOZE2_BASEBALLBAT)

			instaburst.target = mo
			instaburst.team = mo.team
			instaburst.forcedamage = self.damage
			instaburst.iteminfo = self
			instaburst.ib_hitlist = {}
			updBaseballBat(instaburst)
		end,
	})

	// Thinker
	addHook("MobjMoveCollide", function(instaburst, mobj)
		if (mobj.valid and (mobj.flags & MF_SHOOTABLE) or mobj.player) and instaburst.ib_hitlist then
			local range = instaburst.radius
			local alreadyhit = false

			if not ZE2.ZCollide(mobj, instaburst) then
				return
			end

			if instaburst.target == mobj then
				return
			end

			-- Just pretend we can see the fences
			-- Check if you hit this individual before in another frame
			for i,v in ipairs(instaburst.ib_hitlist) do
				if v and v.valid and v == mobj then
					alreadyhit = true
				end
			end

			local dist = R_PointToDist2(mobj.x, mobj.y, instaburst.x, instaburst.y)

			if ((mobj.type == MT_PROPWOOD and dist <= 200*FU) --only extend the range for fences
			or dist < range) and not alreadyhit then
				xSlinger.ShouldDamage(mobj, instaburst, instaburst.target, instaburst.forcedamage)
				table.insert(instaburst.ib_hitlist, mobj)
	
				if (mobj.type == MT_PLAYER) and mobj.team ~= instaburst.target.team then
					-- if we just grappled someone, increase knockback
					local knockback = 200 * instaburst.target.scale
					if instaburst.target.poyo_grappledelay then
						for i = #xSlinger.Knockback.list, 1, -1 do
							local mo = xSlinger.Knockback.list[i]

							if mo == mobj then
								table.remove(xSlinger.Knockback.list, i)
							end
						end
						knockback = $*4
					end

					xSlinger.Knockback.addKnockback(
						mobj,
						6,
						R_PointToAngle2(instaburst.target.x, instaburst.target.y, mobj.x, mobj.y),
						knockback
					)
					mobj.momx = $/3
					mobj.momy = $/3
				end
			end
		end
	end, MT_POYOZE2_BASEBALLBAT)

	addHook("MobjThinker", updBaseballBat, MT_POYOZE2_BASEBALLBAT)

	// ====================
	// == GRAPPLING HOOK ==
	// ====================

	// Poyo is able to assist players by grappling them towards him.
	// Grapple happens until the player releases Fire

	// xSlinger.Knockback.addKnockback(mo, tics, angle, thrust)

	freeslot(
		"MT_POYOZE2_GRAPPLINGHOOK",
		"S_POYOZE2_GRAPPLINGHOOK_START",
		"S_POYOZE2_GRAPPLINGHOOK_HOOKED"
	)

	local function manageGrappleLines(hook, target)
		local lines = hook.chains
		local hookZ = hook.z + hook.height / 2
		local targetZ = target.z + target.height / 2
	
		local distanceXY = R_PointToDist2(hook.x, hook.y, target.x, target.y)
		local distanceXYZ = R_PointToDist2(0, hookZ, distanceXY, targetZ)
		local lineDistance = 38 * target.scale
		local linesBetween = distanceXYZ / lineDistance

		-- every link points the same way, so work that out once
		local angle = R_PointToAngle2(target.x, target.y, hook.x, hook.y)
		local roll = R_PointToAngle2(0, 0, distanceXY, hookZ - targetZ)
		if P_MobjFlip(hook) == -1 then
			roll = InvAngle($)
		end

		-- how far apart the links are
		local stepx, stepy, stepz = 0, 0, 0
		if linesBetween > 0 then
			stepx = (hook.x - target.x) / linesBetween
			stepy = (hook.y - target.y) / linesBetween
			stepz = (hookZ - targetZ) / linesBetween
		end

		for i = 1, linesBetween do
			local line = lines[i]
			local x = target.x + stepx * (i - 1)
			local y = target.y + stepy * (i - 1)
			local z = targetZ + stepz * (i - 1)

			if not line or not line.valid then
				line = P_SpawnMobjFromMobj(target, 0, 0, 0, MT_POYO_GRAPPLECHAIN)
				P_SetOrigin(line, x, y, z)
				lines[i] = line
			else
				P_MoveOrigin(line, x, y, z)
			end

			line.flags2 = $ & ~MF2_DONTDRAW
			line.angle = angle
			line.spriteroll = roll
			line.tics = 2
		end

		-- hide the links the rope is too short for right now
		for i = linesBetween + 1, #lines do
			local line = lines[i]

			if line and line.valid then
				lines[i] = nil
				P_RemoveMobj(line)
			end
		end
	end

	mobjinfo[MT_POYOZE2_GRAPPLINGHOOK] = {
		radius = 8*FU,
		height = 16*FU,
		spawnstate = S_POYOZE2_GRAPPLINGHOOK_START,
		flags = MF_NOGRAVITY
	}

	states[S_POYOZE2_GRAPPLINGHOOK_START] = {
		sprite = SPR_POYO_GRAPPLEHOOK,
		frame = A,
		tics = 40
	}

	states[S_POYOZE2_GRAPPLINGHOOK_HOOKED] = {
		sprite = SPR_POYO_GRAPPLEHOOK,
		frame = A,
		tics = 15 -- not -1, we'll keep it that way as long as target is valid in MobjThinker
	}

	xSlinger.registerItem("poyo_grappling_hook", {
		-- HUD
		displayname = "Grappling Hook",
		icon = "ZMISHIND",
		color = SKINCOLOR_RED,
		
		-- Item properties
		delay = 35,
		damage = 45,
		droppable = false,
		sounds = {
			use = {sfx_py_hk2},
			hurt = {sfx_zbatk1, sfx_zbatk2, sfx_zbatk3},
		},
		usefunc = function(self, mo)
			local hook = P_SpawnMobjFromMobj(mo,
				0,
				0,
				(41 * mo.height / 48)
					- FixedMul(mobjinfo[MT_POYOZE2_GRAPPLINGHOOK].height/2, mo.scale),
				MT_POYOZE2_GRAPPLINGHOOK
			)

			hook.target = mo
			hook.team = mo.team
			hook.forcedamage = 0
			hook.iteminfo = self
			hook.playerhit = nil
			hook.chains = {}
			hook.angle = mo.angle

			local speed = 86 * mo.scale
			local angle = mo.angle
			local aiming = mo.player.aiming
	
			local speedXY = FixedMul(speed, cos(aiming))
			local speedZ = FixedMul(speed, sin(aiming))

			P_InstaThrust(hook, angle, speedXY)
			hook.momz = speedZ
		end,
	})

	addHook("MobjThinker", function(mo)
		if not mo.valid then return end
	
		if not mo.target or not mo.target.valid or not mo.target.health then
			P_RemoveMobj(mo)
			return
		end

		if mo.state == S_POYOZE2_GRAPPLINGHOOK_HOOKED then
			if not mo.playerhit
			or not mo.playerhit.valid
			-- or mo.playerhit.team ~= mo.target.team
			or not mo.playerhit.health then
				P_RemoveMobj(mo)
				return
			end

			local x = mo.playerhit.x + P_ReturnThrustX(mo, mo.angle, -mo.radius)
			local y = mo.playerhit.y + P_ReturnThrustY(mo, mo.angle, -mo.radius)
			local z = mo.playerhit.z + mo.hitoffset

			P_MoveOrigin(mo, x, y, z)
		end

		manageGrappleLines(mo, mo.target)
	end, MT_POYOZE2_GRAPPLINGHOOK)

	addHook("MobjMoveCollide", function(mo, pmo)
		if not mo then return end
		if not mo.valid then return end
		if mo.state == S_POYOZE2_GRAPPLINGHOOK_HOOKED then return end
		if mo.playerhit then return end
		if not pmo then return end
		if not pmo.valid then return end

		if pmo.type ~= MT_PLAYER then return end
		if not pmo.health then return end
		if pmo == mo.target then return end

		if not ZE2.ZCollide(mo, pmo) then
			return
		end

		mo.momx = 0
		mo.momy = 0
		mo.momz = 0
		mo.state = S_POYOZE2_GRAPPLINGHOOK_HOOKED
		mo.playerhit = pmo
		mo.hitoffset = mo.z - pmo.z

		// to simulate a grapple
		xSlinger.Knockback.addKnockback(
			pmo,
			15,
			R_PointToAngle2(pmo.x, pmo.y, mo.target.x, mo.target.y),
			R_PointToDist2(pmo.x, pmo.y, mo.target.x, mo.target.y)/4
		)
	
		if mo.target.team ~= pmo.team then
			mo.target.player.xSlinger.delay = 0
			mo.target.poyo_grappledelay = 15
		end
		S_StopSoundByID(mo.target, sfx_py_hk2)
		S_StartSound(mo, sfx_py_hk1)
	end, MT_POYOZE2_GRAPPLINGHOOK)

	-- script to manage the grappledelay ticker
	PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
		local mo = player.mo
		local class = mo.poyoChar

		if mo.poyo_grappledelay then
			mo.poyo_grappledelay = $ - 1

			if not mo.poyo_grappledelay then
				mo.poyo_grappledelay = nil
			end
		end
	end)

	// ==============
	// == SURVIVOR ==
	// ==============
	ZE2.AddSurvivor("poyo", {
		weight = 8;
		description = {
			"Straight from Fuckadork City.";
			"Has High HP, and Low Speed.";
			"A character for good defenders."
		};
		items = {
			"red_ring";
			"poyo_baseball_bat";
			"poyo_grappling_hook";
		};
	})

	// =========
	// == LMS ==
	// =========
	local POYO_LMS = false

	addHook("MapChange", function()
		POYO_LMS = false
	end)

	addHook("PostThinkFrame", function()
		if not ZE2 or not ZE2.isGametype() then return end
		if not ZE2.Game.active then return end
		if ZE2.Game.ended then return end
		if GUTIL_LOADED then return end

		local survivors = ZE2.CountPlayers("survivors")

		if survivors > 1 then return end -- not lms

		-- check if its poyo
		local poyo = false

		for player in players.iterate do
			if not player.mo then continue end
			if not player.mo.valid then continue end
			if not player.mo.poyoChar then continue end
			if not player.mo.health then continue end
			if player.mo.team == 2 then continue end -- 2 == zombie team

			poyo = true
			break
		end
	
		if not poyo then
			return
		end

		if POYO_LMS then
			return
		end

		-- enable lms
		if mapmusname ~= "PY_ZE2" then
			mapmusname = "PY_ZE2"
		end

		S_ChangeMusic("PY_ZE2")
		POYO_LMS = true
	end)

	addHook("NetVars", function(net)
		POYO_LMS = net($)
	end)

	addHook("MusicChange", function(old, new)
		if not ZE2 then return end
		if not ZE2:isGametype() then return end
		if not ZE2.Game.active then return end
		if ZE2.Game.ended then return end
		if not POYO_LMS then return end

		if new == "PY_ZE2" then
			if old == "PY_ZE2" then
				return true
			end
		end

		if new ~= "PY_ZE2" then
			if old == "PY_ZE2" then
				return true
			end

			return "PY_ZE2"
		end
	end)
end

local function onGUtilLoad()
	if not ze2_lms_songs then return end
	if GUTIL_LOADED then return end

	ze2_lms_songs["poyo"] = "PY_ZE2" -- hi green
	GUTIL_LOADED = true
end

onZE2Load()
onGUtilLoad()

if not ZE2_LOADED then
	addHook("AddonLoaded", onZE2Load)
end
if not GUTIL_LOADED then
	addHook("AddonLoaded", onGUtilLoad)
end