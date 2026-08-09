addHook("HUD", function(v, player)
	local result, match, side = PoyoPennynickel.FNF:PlayerIsInRapBattle(player)
	if not result then return end

	local chart = match.notes[side]
-- 	if player == consoleplayer then
-- 		chart = PoyoPennynickel.FNF.Chart
-- 	end

	local x = 140
	local patch = v.cachePatch("EMBLICON")

	for i = 1, #chart do
		local x = x + patch.width * i-1
		local lane = chart[i]

		v.draw(x, 16, patch, V_SNAPTOTOP|V_SNAPTORIGHT)

		for i = 1, #lane do
			local note = lane[i]

			v.draw(x, 16 + note.timing - match.tics, patch, V_SNAPTOTOP|V_SNAPTORIGHT, v.getColormap(TC_BLINK, SKINCOLOR_RED))
		end
	end
end)