addHook("HUD", function(v, player)
	if not player then return end
	if not player.mo then return end
	if not player.mo.valid then return end
	if player.mo.skin ~= "poyo" then return end
	if not hud.enabled("lives") then return end

	v.drawString(16, 168, "Work in progress!", V_SNAPTOLEFT|V_SNAPTOBOTTOM|V_REDMAP|V_HUDTRANS, "thin")
end)