local steps = {}
local sfx_py_rns = freeslot("sfx_py_rns")

local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

-- yea
Class.lastFrame = INT32_MAX
Class.lastPanim = INT32_MAX

for i = 1, 8 do
	steps[i] = freeslot("sfx_py_sp"..i)
	sfxinfo[steps[i]].caption = "Step"
end

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	local panim = class.lastPanim
	class.lastPanim = player.panim

	if player.panim == PA_RUN
	and panim == PA_WALK then
		S_StartSound(mo, sfx_py_rns)
	end

	if (player.panim ~= PA_WALK and player.panim ~= PA_RUN) or class.skateboard then
		class.lastFrame = Class.lastFrame
		return
	end

	local frame = mo.frame & FF_FRAMEMASK
	local skin = skins[player.skin]
	local sprites = skin.sprites
	local frames = sprites[mo.sprite2 & FF_FRAMEMASK].numframes

	if class.lastFrame ~= frame
	and (frame == 0 or frame == frames/2) then
		S_StartSound(mo, steps[P_RandomRange(1, #steps)])
	end

	class.lastFrame = frame
end, 1)