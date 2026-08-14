addHook("MobjDamage", function(target, _, _)
	if not target then return end
	if not target.valid then return end

	if mapheaderinfo[gamemap].bonustype ~= 1 then return end
	if target.flags & MF_BOSS == 0 then return end
	if target.health-1 > target.info.spawnhealth / 2 then return end
	if mapmusname == "PY_WIN" then return end

	if not consoleplayer then return end
	if not consoleplayer.valid then return end
	if not consoleplayer.mo then return end
	if not consoleplayer.mo.valid then return end
	if not consoleplayer.mo.poyoChar then return end

	S_ChangeMusic("PY_WIN", true)
	mapmusname = "PY_WIN"
end)