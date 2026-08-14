local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

-- we are looking for poyo_secondcolor in player_t specifically.

Class.overlayMobj = nil

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	-- safety
	mo.eflags = $|MFE_FORCENOSUPER

	if not player.poyo_secondcolor or player.poyo_secondcolor > #skincolors or not mo.health then
		if class.overlayMobj and class.overlayMobj.valid then
			P_RemoveMobj(class.overlayMobj)
		end
		class.overlayMobj = nil
		return
	end

	if not class.overlayMobj or not class.overlayMobj.valid then
		class.overlayMobj = P_SpawnMobjFromMobj(mo, 0,0,0, MT_THOK)
	end

	class.overlayMobj.skin = mo.skin
	class.overlayMobj.state = S_INVISIBLE
	class.overlayMobj.sprite = SPR_PLAY
	class.overlayMobj.sprite2 = mo.sprite2|FF_SPR2SUPER
	class.overlayMobj.eflags = MFE_FORCESUPER
	class.overlayMobj.frame = mo.frame
	class.overlayMobj.angle = player.drawangle
	class.overlayMobj.color = player.poyo_secondcolor
	class.overlayMobj.colorized = mo.colorized
	class.overlayMobj.tics = 2
	class.overlayMobj.fuse = -1
-- 	class.overlayMobj.momx = mo.momx
-- 	class.overlayMobj.momy = mo.momy
-- 	class.overlayMobj.momz = mo.momz
	class.overlayMobj.scale = mo.scale
	P_MoveOrigin(class.overlayMobj, mo.x, mo.y, mo.z)
	class.overlayMobj.radius = mo.radius
	class.overlayMobj.height = mo.height
	class.overlayMobj.flags = $|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY
	class.overlayMobj.flags2 = ($ & ~MF2_OBJECTFLIP)|(mo.flags2 & MF2_OBJECTFLIP)
	class.overlayMobj.eflags = ($ & ~MFE_VERTICALFLIP)|(mo.eflags & MFE_VERTICALFLIP)
	class.overlayMobj.dispoffset = 1 -- beat that liberals
end, 1)

COM_AddCommand("poyo_secondcolor", function(player, i)
	i = tonumber($)

	if i == nil then i = 0 end
	if not i or i > #skincolors-1 then i = 0 end -- if its not valid we dont want a second color at all
	if i < 0 then i = 0 end

	if i and not skincolors[i].accessible then return end

	player.poyo_secondcolor = i

	if i then
		CONS_Printf(player, "Set second color to "..skincolors[i].name)
	end
end)