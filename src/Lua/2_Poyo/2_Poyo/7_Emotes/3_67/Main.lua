local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local emote = {}

local S_PLAY_POYO_SIXSEVEN = freeslot("S_PLAY_POYO_SIXSEVEN")

local sfx_py_em2 = freeslot("sfx_py_em2")
sfxinfo[sfx_py_em2].caption = "67!!!"

freeslot("SPR_SOAP_POYO_GFX")
freeslot("S_SOAP_POYO_WALLBUMP")
states[S_SOAP_POYO_WALLBUMP] = {
    sprite = SPR_SOAP_POYO_GFX,
    frame = A|FF_ADD|FF_FULLBRIGHT,
	tics = -1,
}

freeslot("MT_SOAP_POYO_WALLBUMP")
mobjinfo[MT_SOAP_POYO_WALLBUMP] = {
	doomednum = -1,
	spawnstate = S_SOAP_POYO_WALLBUMP,
	radius = 5*FRACUNIT,
	height = 10*FRACUNIT,
	flags = MF_NOCLIPTHING|MF_NOCLIPHEIGHT|MF_NOCLIP
}

freeslot("MT_SOAP_POYO_DUST")
mobjinfo[MT_SOAP_POYO_DUST] = {
	doomednum = -1,
	spawnstate = S_SPINDUST1,
	radius = 4*FRACUNIT,
	height = 4*FRACUNIT,
	flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIP
}

local dust_mul = FU*19/22
addHook("MobjThinker",function(mo)
	if not mo.extravalue1
		mo.tics = $ + P_RandomKey(7)
		mo.extravalue1 = 1
	end
	mo.momx,mo.momy,mo.momz = FixedMul($1,dust_mul),FixedMul($2,dust_mul),FixedMul($3,dust_mul)
end,MT_SOAP_POYO_DUST)

addHook("MobjThinker",function(bump)
	if not (bump and bump.valid) then return end
	
	-- this is just much better
	if (bump.fusefade ~= nil) and bump.fuse < bump.fusefade
		bump.alpha = $ - (FU / bump.fusefade)
	end
	if (bump.fusesquish ~= nil)
	and bump.fuse <= bump.fusesquish
		local frac = FU - FixedDiv(bump.fuse*FU, bump.fusesquish*FU)
		bump.spriteyscale = ease.outquad(frac, FU, 0)
	end
	if (bump.movefactor ~= FU)
		bump.momx = FixedMul($, bump.movefactor)
		bump.momy = FixedMul($, bump.movefactor)
	end
	-- lol
-- 	if CV.rotations.value
-- 		bump.rollangle = $ + (bump.random or 0)
-- 	end
	
	if bump.sixseveneffect
		local frame = (bump.frame & FF_FRAMEMASK)
		if bump.fuse <= 20
		and frame ~= 40
			bump.alpha = $ - (FU/20)
			bump.momx = $ * 9/10
			bump.momy = $ * 9/10
			if (frame == 34)
				bump.spriteyscale = ease.outquad(FU - ((FU/20)*bump.fuse), FU, 0)
			end
		elseif frame == 40
			local frac = FU - FixedDiv(bump.fuse*FU, 12*FU)
			bump.alpha = ease.inoutsine(frac, FU, 0)
			bump.spritexscale = ease.inoutquad(frac, FU, FU*5/2)
			bump.spriteyscale = bump.spritexscale
			if CV.rotations.value
				bump.rollangle = $ + ANG2*2
			end
		end
		return
	end
	
	if bump.nothink then return end -- ...?
	
	local me = bump.target
	if (me and me.valid)
		if me.hitlag
			return true
		end
	end
	
	if bump.startfuse ~= nil
	and bump.fuse == bump.startfuse * 3/8
		bump.destscale = 0
		bump.scalespeed = FixedDiv(bump.scale, bump.fuse*FU)
	end
	
	if not (bump.flags & MF_NOGRAVITY)
		bump.momz = $ + P_GetMobjGravity(bump)
	end
	bump.lifetime = (bump.lifetime ~= nil and $+1 or 0)
	
	if bump.shoemode
		bump.angle = $ + ANG15
	end
	if bump.sweat
		local squish = 0
		if bump.lifetime & 1 then --nothing
		else
			if (bump.lifetime/2) & 1
				squish = FU/4
			else
				squish = -FU/4
			end
		end
		bump.spritexscale = FU + squish
		bump.spriteyscale = FU - squish
	end
end,MT_SOAP_POYO_WALLBUMP)

-- straight copied from takis LOL
local function dust_type(me)
	return (me.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER)) and P_RandomRange(MT_SMALLBUBBLE,MT_MEDIUMBUBBLE) or MT_SOAP_POYO_DUST
end
local function Soap_StartQuake(intensity, time, epicenter, radius)
	--Accept mobjs as epicenter points (is this ever used?)
	if type(epicenter) == "userdata" and userdataType(epicenter) == "mobj_t"
		local temp = epicenter
		epicenter = {temp.x,temp.y,temp.z}
	end
	P_StartQuake(intensity,time,epicenter,radius)
end
local function Soap_RandomFixedRange(a, b)
	return a + FixedMul((b - a), P_RandomFixed())
end
local sixseven_callback = function(spark)
	spark.tics = 25
	spark.fuse = 25
	spark.type = MT_SOAP_POYO_WALLBUMP
	spark.sixseveneffect = true
	spark.frame = A
	spark.sprite = SPR_SOAP_POYO_GFX
	spark.frame = 34|FF_PAPERSPRITE|FF_ADD
	spark.momz = 0
	spark.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT|(P_RandomChance(FU/2) and RF_HORIZONTALFLIP or 0)
	P_ThrustEvenIn2D(spark, spark.angle - ANGLE_90, 8*FU)
end
local function Soap_DustRing(src,
	type,
	amount,
	pos,
	radius, speed,
	initscale, scale,
	threeaxis,
	callback,
	angle,aim -- for threeaxis
)
	radius = $ or 0
	speed = $ or 0
	initscale = $ or FU/2
	scale = $ or FU
	
	-- this block is chrispychars code
	if threeaxis
		local momz = src.momz
		if alwaysabove
			momz = -P_MobjFlip(src)*abs($)
		end
		if abs(momz) < src.scale
			momz = $ < 0 and -src.scale or src.scale
		end
		
		local forwardangle = angle
		local sideangle = forwardangle + ANGLE_90
		local vangle = aim
		
		local cosine = cos(vangle)
		local sine = sin(vangle)
		
		local radius = FixedDiv(src.height, src.scale) >> 1
		local xspawn = -FixedMul(FixedMul(cos(forwardangle), cosine), radius)
		local yspawn = -FixedMul(FixedMul(sin(forwardangle), cosine), radius)
		local zspawn = -FixedMul(sine, radius)
		
		local hthrust = 0
		local vthrust = 0
		if thrust
			hthrust = FixedMul(thrust, cosine)
			vthrust = FixedMul(thrust, sine)
		end
		
		cosine = FixedMul($, speed)
		sine = FixedMul($, speed)
		
		local angstep = FixedDiv(360*FU, amount*FU)
		for i = 0, amount
			local dust = P_SpawnMobjFromMobj(src, xspawn, yspawn, radius, type)
			local a = FixedAngle(i*angstep) + forwardangle
			local forwardthrust = FixedMul(cos(a), sine)
			local sidethrust = FixedMul(sin(a), speed)
			local zthrust = FixedMul(cosine, cos(a))
			
			dust.z = $ + zspawn
			
			P_ThrustEvenIn2D(dust, forwardangle, forwardthrust - hthrust)
			P_ThrustEvenIn2D(dust, sideangle, sidethrust)
			dust.momz = -zthrust - vthrust
			
			dust.angle = a + ANGLE_90
			P_SetScale(dust, initscale, true)
			dust.destscale = scale + P_RandomFixed()
			dust.scalespeed = scale / 24
			
			--remove interp
			P_SetOrigin(dust, dust.x,dust.y,dust.z)
			--Sure
			dust.alpha = src.alpha
			
			if callback ~= nil
				callback(dust)
			end
		end
		return
	end
	
	local flip = P_MobjFlip(src) == -1
	if flip
		pos[3] = $ + src.height
	end
	
	local ang = FixedDiv(360*FU, amount*FU)
	for i = 1, amount
		local fa = FixedAngle(ang * i)
		local dust = P_SpawnMobj(
			pos[1] + P_ReturnThrustX(nil, fa, radius),
			pos[2] + P_ReturnThrustY(nil, fa, radius),
			pos[3],
			type
		)
		if not (dust and dust.valid) then continue end
		
		dust.angle = fa + ANGLE_90
		P_SetScale(dust, initscale, true)
		dust.destscale = scale + P_RandomFixed()
		dust.scalespeed = scale / 24
		P_ThrustEvenIn2D(dust, fa, speed + FixedMul(P_RandomFixed(), scale))
		dust.momz = P_SignedRandom() * scale / 64
		
		if flip
			dust.z = $ - dust.height
			dust.flags2 = $|MF2_OBJECTFLIP
		end
		
		--remove interp
		P_SetOrigin(dust, dust.x,dust.y,dust.z)
		--Sure
		dust.alpha = src.alpha
		dust.tracer = src
		
		if callback ~= nil
			callback(dust, src)
		end
	end
end

states[S_PLAY_POYO_SIXSEVEN] = {
	sprite = SPR_PLAY,
	frame = SPR2_TAL2,
	tics = 7,
	action = PoyoPennynickel.EmoteAction,
	nextstate = S_PLAY_POYO_SIXSEVEN
}

table.insert(Class.emotes, emote)

-- LOGIC
emote.name = "67"
emote.use = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	mo.state = S_PLAY_POYO_SIXSEVEN

	class.sixSevenAdjust = 0
	class.sixSevenSuper = 0

-- 	S_StartSound(mo, sfx_py_omg)
end
emote.update = function(player, active)
	local mo = player.mo
	local class = mo.poyoChar

	if not active then return end

	local jump = (player.cmd.buttons & ~player.lastbuttons) & BT_JUMP
	if jump then
		class.sixSevenAdjust = min(20, $ + 10)
	end

	if class.sixSevenAdjust >= 10 then
		-- the six is sevening...
		P_SpawnGhostMobj(mo)
		class.sixSevenSuper = $ + 1
		mo.tics = min($, 4)

		if (class.sixSevenSuper == TICRATE)
		or (class.sixSevenSuper == 3*TICRATE)
		or (class.sixSevenSuper == 6*TICRATE)
			S_StartSoundAtVolume(mo,sfx_s3ka2,192)
		end
		if (class.sixSevenSuper == 3*TICRATE)
			S_StartSound(mo,sfx_cdfm40)
			S_StartSound(mo,sfx_py_em2)
		elseif (class.sixSevenSuper == 6*TICRATE)
			S_StartSoundAtVolume(mo,sfx_s3k9c,192)
		end
	else
		class.sixSevenSuper = max(0, min($ - 2, TICRATE))
	end

	if class.sixSevenSuper >= TICRATE
		if class.sixSevenSuper >= 3*TICRATE then
			mo.tics = min($, 1)
		else
			mo.tics = min($, 2)
		end
		if (leveltime % 4 == 0)
			local function dust_noviewmobj(dust)
				dust.dontdrawforviewmobj = me
			end
			Soap_DustRing(mo,
				dust_type(mo),
				P_RandomRange(6, 10),
				{mo.x,mo.y,mo.z},
				16*mo.scale + (class.sixSevenSuper - TICRATE) * 783,
				mo.scale*7,
				mo.scale,
				mo.scale/2,
				false, dust_noviewmobj
			)
			if class.sixSevenSuper >= 3*TICRATE then
				Soap_DustRing(mo,
					MT_PARTICLE, 16,
					{mo.x,mo.y,mo.z},
					8*FU, 8*FU,
					mo.scale / 10,
					mo.scale * 4,
					false, sixseven_callback
				)
			end
		end
		
		local range = 20*FU
		local z = P_SpawnMobjFromMobj(mo,
			Soap_RandomFixedRange(-range, range),
			Soap_RandomFixedRange(-range, range),
			Soap_RandomFixedRange(0, 30*FU),
			MT_WATERZAP
		)
		z.renderflags = $|RF_NOCOLORMAPS|RF_FULLBRIGHT
		if class.sixSevenSuper >= 6*TICRATE
			local range = 4*mo.scale
			local g = P_SpawnGhostMobj(mo)
			g.colorized = true
			g.blendmode = AST_ADD
			g.destscale = 0
			g.dispoffset = -600
			P_SetObjectMomZ(g, 12*FU)
			
			P_SetOrigin(g,
				g.x + Soap_RandomFixedRange(-range, range),
				g.y + Soap_RandomFixedRange(-range, range),
				g.z + Soap_RandomFixedRange(-range, range)
			)
		end
		if class.sixSevenSuper >= 6*TICRATE
			Soap_StartQuake(FU + (class.sixSevenSuper - 6*TICRATE) * 2400, 2,
				{mo.x,mo.y,mo.z}, 256*FU
			)
-- 			mo.colorized = (leveltime % 2 == 0)
		else
-- 			mo.colorized = false
		end
	else
-- 		mo.colorized = false
	end

	class.sixSevenAdjust = max(0, $ - 1)
end
emote.active = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	return mo.state == S_PLAY_POYO_SIXSEVEN
end
emote.finish = function(player) end

PoyoPennynickel:addScript("PlayerJump", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if emote.active(player) then
		return true
	end
end)