local LOADED = false
local function onLoad()
	if not ZE2 then return end
	if LOADED then return end

	LOADED = true
	ZE2.AddSurvivor("poyo", {
		weight = 8;
		description = {
			"Straight from Fuckadork City.";
			"Has High HP, and Low Speed.";
			"A character for good defenders."
		};
		items = {
			"scatter_ring";
			"explosion_ring";
			"grenade_ring";
		};
	})
end

onLoad()
if LOADED then return end

addHook("AddonLoaded", onLoad)