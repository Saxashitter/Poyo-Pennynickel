addHook("HUD", function(v, player, x, y, scale, skin, sprite2, frame, rotation, color, ticker, paused)
	if skin ~= "poyo" then return end
	y = ($/FU) - 64 -- you aint slick srb2

	local width = 74
	local height = 84

-- 	v.drawFill(160 - width / 2, y, width, height, 31)
	v.draw((x/FU) - width / 2, y, v.cachePatch("POYO_PLAYERSETUP"), 0, v.getColormap(skin, color))

	return true
end, "playersetup")