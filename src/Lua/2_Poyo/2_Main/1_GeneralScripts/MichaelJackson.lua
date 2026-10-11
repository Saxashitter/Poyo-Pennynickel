local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local sounds = {}

local S_PLAY_POYO_MICHAEL_JACKSON = freeslot("S_PLAY_POYO_MICHAEL_JACKSON")
states[S_PLAY_POYO_MICHAEL_JACKSON] = {
	sprite = SPR_PLAY,
	frame = SPR2_TAL7,
	tics = -1,
	action = function(mo)
		if not mo then return end
		if not mo.valid then return end
		if not mo.player then return end
		if not mo.player.valid then return end

		mo.player.panim = PA_EDGE
		S_StartSound(mo, sounds[P_RandomRange(1, #sounds)])
	end
}

for i = 1, 2 do
	local sound = freeslot("sfx_py_mj"..i)

	sfxinfo[sound].caption = "OW!!"
	sounds[i] = sound
end

local function P_DoTeeter(player)
    local mo = player.mo
    if not mo then return end

    local teeter = false
    local roverfloor = false
    local tiptop = FixedMul(MAXSTEPMOVE, mo.scale)

	if mo.state ~= S_PLAY_EDGE and mo.state ~= S_PLAY_POYO_MICHAEL_JACKSON then return end

    if mo.standingslope and mo.standingslope.zdelta >= (FRACUNIT/2) then
        return
    else
		local tx = P_ReturnThrustX(nil, player.drawangle, -mo.scale*12)
		local ty = P_ReturnThrustY(nil, player.drawangle, -mo.scale*12)
		local floorz = P_FloorzAtPos(mo.x + tx, mo.y + ty, mo.z + mo.scale, mo.height)
		local ceilz = P_CeilingzAtPos(mo.x + tx, mo.y + ty, mo.z + mo.scale, mo.height)

		local ftx = P_ReturnThrustX(nil, player.drawangle, mo.scale*20)
		local fty = P_ReturnThrustY(nil, player.drawangle, mo.scale*20)
		local frontfloorz = P_FloorzAtPos(mo.x + ftx, mo.y + fty, mo.z + mo.scale, mo.height)
		local frontceilz = P_CeilingzAtPos(mo.x + ftx, mo.y + fty, mo.z + mo.scale, mo.height)

		for i = 0, 1 do
			local sign = (i == 0) and -1 or 1
			local stx = P_ReturnThrustX(nil, player.drawangle - ANGLE_90, mo.scale*30) * sign
			local sty = P_ReturnThrustY(nil, player.drawangle - ANGLE_90, mo.scale*30) * sign

			local newfloorz = P_FloorzAtPos(mo.x + ftx + stx, mo.y + fty + sty, mo.z + mo.scale, mo.height)
			local newceilz = P_CeilingzAtPos(mo.x + ftx + stx, mo.y + fty + sty, mo.z + mo.scale, mo.height)

			frontfloorz = max($, newfloorz)
			frontceilz = min($, newceilz)
		end

		if P_MobjFlip(mo) == 1 then
			-- if we arent over the ledge
			if (mo.z - floorz) < tiptop then
				teeter = false

			-- if we are but our front floorz is over (or equal) to ours
			elseif mo.z <= frontfloorz then
				teeter = false

			-- set to #true
			else
				teeter = true
			end
		else
			local z = mo.z + mo.height

			if (ceilz - z) < tiptop then
				teeter = false

			elseif z >= frontceilz then
				teeter = false

			else
				teeter = true
			end
		end
    end

    if teeter then
        if player.panim == PA_IDLE or player.mo.state == S_PLAY_EDGE then
			player.mo.state = S_PLAY_POYO_MICHAEL_JACKSON
		end
    elseif player.mo.state == S_PLAY_POYO_MICHAEL_JACKSON then
		player.mo.state = S_PLAY_EDGE
	end
end

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if not mo.health then return end

	P_DoTeeter(player)
end)