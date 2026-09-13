local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

function Class:canDashAggressiveAttack()
	-- are we over the speed?
	local speed = R_PointToDist2(0, 0, self.mo.momx - self.mo.player.cmomx, self.mo.momy - self.mo.player.cmomy)

	if speed < 7 * self.mo.scale then
		return
	end

	-- check if player is moving (or facing in manual) in the way their character is moving
	local momAngle = R_PointToAngle2(0, 0, self.mo.momx - self.mo.player.cmomx, self.mo.momy - self.mo.player.cmomy)
	local inputAngle = self.mo.angle

	return abs(momAngle - inputAngle) <= ANGLE_90
end