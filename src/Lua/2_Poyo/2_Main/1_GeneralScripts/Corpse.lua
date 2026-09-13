local corpse_sprite = rawget(_G, "SPR2_OOF_")
if not corpse_sprite then
	corpse_sprite = freeslot("SPR2_OOF_")
end

local MT_POYO_CORPSE = freeslot("MT_POYO_CORPSE")

mobjinfo[MT_POYO_CORPSE] = {
	radius = 16*FU,
	height = 48*FU,
	flags = 0,
	spawnstate = S_THOK
}

addHook("MobjThinker", function(mo)
	if not mo.valid then return end

	local sprite = SPR2_PAIN

	if P_IsObjectOnGround(mo) and mo.momz * P_MobjFlip(mo) <= 0 then
		mo.momx = 0
		mo.momy = 0
		sprite = corpse_sprite
	end

	mo.sprite2 = sprite
	mo.tics = -1
end, MT_POYO_CORPSE)

PoyoPennynickel:addScript("PlayerDied", function(player)
	if MM and MM:isMM() then return end
	if ZE2 and gametype == GT_ZE2 then return end

	local mo = player.mo
	local class = mo.poyoChar

	local corpse = P_SpawnMobjFromMobj(mo, 0,0,0, MT_POYO_CORPSE)
	class.corpse = corpse

	corpse.state = S_THOK
	corpse.flags = 0
	corpse.fuse = -1
	corpse.tics = -1
	corpse.angle = player.drawangle
	corpse.translation = mo.translation
	if multiplayer then
		corpse.fuse = (60 * TICRATE) * 5
	end
	corpse.skin = mo.skin
	corpse.sprite = SPR_PLAY
	corpse.sprite2 = SPR2_PAIN
	corpse.frame = mo.frame & ~FF_FRAMEMASK
	corpse.shadowscale = mo.shadowscale
	corpse.color = mo.color
	corpse.scale = mo.scale

	P_InstaThrust(corpse, player.drawangle, -5*mo.scale)
	P_SetObjectMomZ(corpse, 5*mo.scale)

	mo.alpha = 0
end)

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if mo.health then return end

	if class.corpse and not class.corpse.valid then
		class.corpse = nil
	end

	if class.corpse then
		P_MoveOrigin(mo, class.corpse.x, class.corpse.y, class.corpse.z)
		mo.shadowscale = 0
		mo.momx = class.corpse.momx
		mo.momy = class.corpse.momy
		mo.momz = class.corpse.momz
	end
end)