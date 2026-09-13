local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local PERFECT_TICS = 30
local PERFECT_RISE_TICS = 6

-- ouuuu
Class.perfectTics = 0

function Class:perfectHUD()
	local mo = self.mo
	local class = mo.poyoChar

	class.perfectTics = PERFECT_TICS
end

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if class.perfectTics then
		class.perfectTics = $-1
	end
end)

addHook("HUD", function(v, player, cam)
	if not player then return end
	if not player.mo then return end
	if not player.mo.valid then return end
	if player.mo.skin ~= "poyo" then return end
	if not player.mo.poyoChar then return end

	if not player.mo.poyoChar.perfectTics then return end

	local tics = PERFECT_TICS - player.mo.poyoChar.perfectTics
	local t = FixedDiv(tics, PERFECT_TICS)
	local rise_t = FixedDiv(min(tics, PERFECT_RISE_TICS), PERFECT_RISE_TICS)
	local alpha = (10 - min(player.mo.poyoChar.perfectTics, 10))

	if alpha == 10 then return end

	local x = player.mo.x
	local y = player.mo.y
	local z = player.mo.z + player.mo.height
	if P_MobjFlip(player.mo) == -1 then
		z = player.mo.z - 16*player.mo.scale
	end

	local result = PoyoPennynickel.WorldToScreen(v, player, cam, {x=x,y=y,z=z})
	if not result.onscreen then return end

	local sx = result.x
	local sy = result.y

	sy = $ + ease.outcubic(rise_t, 16*FU, 0)

	local perfect = v.cachePatch("POYO_PERFECT")

	if v.interpolate then
		v.interpolate(true, perfect)
	end
	v.drawScaled(sx, sy, FU, perfect, alpha * V_10TRANS)
end)