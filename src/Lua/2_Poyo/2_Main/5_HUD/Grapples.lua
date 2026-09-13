addHook("HUD", function(v, player)
	if not player then return end
	if not player.mo then return end
	if not player.mo.valid then return end
	if player.mo.skin ~= "poyo" then return end
	if not player.mo.poyoChar then return end

	v.drawString(16, 56, "Grapples: "..tostring(3-player.mo.poyoChar.grappleTimes), V_SNAPTOLEFT|V_SNAPTOTOP|V_HUDTRANS, "thin")
end)