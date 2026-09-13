local S_POYO_WINDLINE = freeslot("S_POYO_WINDLINE")
local SPR_POYO_WINDLINE = freeslot("SPR_POYO_WINDLINE")

local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

states[S_POYO_WINDLINE] = {
	sprite = SPR_POYO_WINDLINE,
	frame = FF_ANIMATE|FF_PAPERSPRITE|FF_ADD,
	tics = 12,
	action = nil,
	var1 = 5,
	var2 = 2
}

local function random(minimum, maximum)
	return minimum + FixedMul(maximum - minimum, P_RandomFixed())
end

function Class:windline(amount, stretch)
	-- placeholder
	local mo = self.mo
	if stretch == nil then stretch = FU end
	local angle = R_PointToAngle2(0,0,mo.momx - mo.player.cmomx, mo.momy - mo.player.cmomy)
	for i = 1, amount do
		local radius = mo.radius*2
		local minimum_range = mo.radius
		local side = random(-radius, radius)
		local forward = 0

		-- capping this so it doesnt look odd
		if abs(side) < minimum_range then
			local sign = 1
			if side < 0 then
				sign = -1
			end

			side = minimum_range * side
		end

		local thok = P_SpawnMobjFromMobj(mo,
			mo.momx*3/2 + P_ReturnThrustX(nil, angle - ANGLE_90, side) + P_ReturnThrustX(nil, angle, forward),
			mo.momy*3/2 + P_ReturnThrustY(nil, angle - ANGLE_90, side) + P_ReturnThrustY(nil, angle, forward),
			random(0, mo.height),
		MT_THOK)

		local mult = FixedDiv(side, radius)

		thok.tics = -1
		thok.fuse = -1
		thok.state = S_POYO_WINDLINE
		thok.angle = angle + FixedAngle(20 * mult)
		thok.rollangle = R_PointToAngle2(0, 0, R_PointToDist2(0,0,mo.momx - mo.player.cmomx, mo.momy - mo.player.cmomy), mo.momz)
		thok.spritexscale = stretch

		if mo.player.poyo_secondcolor then
			thok.color = mo.player.poyo_secondcolor
		else
			thok.color = SKINCOLOR_RED
		end
	end
end