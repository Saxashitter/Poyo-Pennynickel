local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

-- we are looking for poyo_secondcolor in player_t specifically.

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if mo.translation == nil and player.poyo_secondcolor then
		mo.translation = PoyoPennynickel.SecondColors[player.poyo_secondcolor].color
	end

	if not (player.poyo_secondcolor and PoyoPennynickel.SecondColors[player.poyo_secondcolor].color) and mo.translation and mo.translation:find("Poyo_Visor") then
		mo.translation = nil
	end
end)

addHook("ThinkFrame", function()
	for player in players.iterate do
		if not player.mo then continue end
		if not player.mo.valid then continue end
		if player.mo.poyoChar then continue end

		if player.mo.translation and player.mo.translation:find("Poyo_Visor") then
			player.mo.translation = nil
		end
	end
end)

COM_AddCommand("poyo_secondcolor", function(player, i)
	i = tonumber($)

	if i == nil then i = 1 end
	if not i or PoyoPennynickel.SecondColors[i] == nil then i = 1 end -- if its not valid we dont want a second color at all

	player.poyo_secondcolor = i

	if i then
		if player.mo and player.mo.valid and player.mo.poyoChar and (not player.mo.translation or player.mo.translation:find("Poyo_Visor")) then
			player.mo.translation = PoyoPennynickel.SecondColors[player.poyo_secondcolor].color
		end
		CONS_Printf(player, "Set second color to "..PoyoPennynickel.SecondColors[player.poyo_secondcolor].name)
	end
end)