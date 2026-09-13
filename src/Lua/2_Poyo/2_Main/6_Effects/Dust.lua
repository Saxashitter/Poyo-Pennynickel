addHook("MobjThinker", function(mo)
	if not mo.valid then return end
	if mo.__poyo_friction == nil then return end

	mo.momx = FixedMul($, mo.__poyo_friction)
	mo.momy = FixedMul($, mo.__poyo_friction)
end, MT_DUST)

-- usually used after hitting the ground or something
function PoyoPennynickel.DustEffect(mo, count, thrust, friction, tic_offset)
	local angle = mo.angle

	if mo == nil then return end
	if count == nil then count = 1 end
	if thrust == nil then thrust = FU end
	if friction == nil then friction = FU end

	for i = 1, count do
		local dust = P_SpawnMobjFromMobj(mo, 0,0,0, MT_DUST)
		if not dust.valid then continue end

		P_InstaThrust(dust, angle, FixedMul(thrust, mo.scale))
		dust.__poyo_friction = friction
		if tic_offset ~= nil then
			dust.tics = tic_offset
		end

		angle = FixedAngle(AngleFixed($) + (360 * FU / count))
	end
end