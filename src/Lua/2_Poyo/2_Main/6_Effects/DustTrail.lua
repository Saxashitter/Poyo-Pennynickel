local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

-- how long the trail should trail behind
Class.dustTrailTics = 0

local function random(minimum, maximum)
	return minimum + FixedMul(maximum - minimum, P_RandomFixed())
end

local function makeDust(mo)
	return P_SpawnMobjFromMobj(mo,
		random(-mo.radius, mo.radius),
		random(-mo.radius, mo.radius),
		0,
	MT_DUST)
end

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if class.dustTrailTics then
		class.dustTrailTics = $ - 1

		makeDust(mo)
	end
end)

function Class:dustTrail(tics)
	if tics == nil or tics == 0 then return end

	local mo = self.mo

	self.dustTrailTics = tics
	makeDust(mo)
end

function Class:makeDust() return makeDust(self.mo) end -- wrapper