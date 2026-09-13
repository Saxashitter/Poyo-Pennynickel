local LOADED = false
local function onLoad()
	if not MH then return end
	if LOADED then return end

	LOADED = true
	MH:addHook("PostUI", function(v)
		if not MHN.lastManStanding then return end
		if MHN.lastManStandingTime < 0 then return end

		local runnerSkin = MHN.lastManStandingSkin
		local runnerPlayer = MHN.lastManStandingPlayer

		if runnerSkin ~= "poyo" then return end
		if not runnerPlayer then return end
		if not runnerPlayer.valid then return end
		if not runnerPlayer.poyo_secondcolor then return end
		

		local tics = leveltime - MHN.lastManStandingTime

		local screenWidth = v.width()*FU/v.dupx()
		local screenHeight = v.height()*FU/v.dupy()
		
		local length = 5*TICRATE
		local fadeIn = 15
		local fadeOut = 35

		-- LTFNT is ?x16

		if tics > length then return end

		local inT = FixedDiv(min(tics, fadeIn), fadeIn)
		local outT = FixedDiv(max(0, tics - (length - fadeOut)), fadeOut)

		local t = inT
		if tics >= length - fadeOut then
			t = FU - outT
		end

		local runnerColor = MHN.lastManStandingColor
		local runnerScale = FU
		local runnerX = 0
		local runnerY = ease.outcubic(t, 100*FU, 0)
		local runnerFlags = V_SNAPTOBOTTOM 
		local runnerColormap = v.getColormap(runnerSkin, runnerPlayer.poyo_secondcolor)
		local runnerPatch = v.cachePatch("MH_LMS_POYO_2")

		v.drawScaled(runnerX, runnerY, runnerScale, runnerPatch, runnerFlags, runnerColormap)
	end, "lastManStanding")

	MH:addHook("LastManStanding", function(player, skin, color)
		if skin == "poyo" then
			return nil, nil, nil, nil, "PY_LMS"
		end
	end)
end

onLoad()
if LOADED then return end

addHook("AddonLoaded", onLoad)