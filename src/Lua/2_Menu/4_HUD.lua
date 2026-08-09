addHook("HUD", function(v)
	if not PoyoPennynickel.Menu.Active then return end

	local player = consoleplayer

	local screenWidth = v.width() / v.dupx()
	local screenHeight = v.height() / v.dupy()

	local background = v.cachePatch("~031")
	local scaleX = FixedDiv(screenWidth, background.width)
	local scaleY = FixedDiv(screenHeight, background.height)

	v.drawStretched(0, 0, scaleX, scaleY, background, V_SNAPTOLEFT|V_SNAPTOTOP|V_40TRANS)

	-- draw background
	local banner = v.cachePatch("LTZIGRED")
	local tics = 180
	local t = FixedDiv(leveltime % tics, tics)
	local offsetY = FixedMul(banner.height*FU, t)

	for i = -banner.height*FU, screenHeight*FU, banner.height*FU do
		v.drawScaled(0, i + offsetY, FU, banner, V_SNAPTOLEFT|V_SNAPTOTOP)
	end

	-- bing chillin
	local poyo = v.cachePatch("POYO_BINGCHILLING_1")
	local visor = v.cachePatch("POYO_BINGCHILLING_2")
	local poyomap = nil
	local translatemap = nil

	if player and player.valid then
		poyomap = v.getColormap(player.skin, player.skincolor)

		if player.poyo_secondcolor then
			translatemap = v.getColormap(player.skin, player.skincolor, PoyoPennynickel.SecondColors[player.poyo_secondcolor].color)
		end
	end

	v.drawScaled(220*FU, 70*FU, FU/8, poyo, V_SNAPTORIGHT|V_SNAPTOBOTTOM, poyomap)
	v.drawScaled(220*FU, 70*FU, FU/8, visor, V_SNAPTORIGHT|V_SNAPTOBOTTOM, translatemap)

	-- draw all entries
	local entries = PoyoPennynickel.Menu.Current.Entries
	local stringHeight = 8
	local y = 100 - (stringHeight * #entries / 2)
	for i, entry in ipairs(entries) do
		if entry == true then continue end

		local color = 0

		if i == PoyoPennynickel.Menu.Selection then
			color = V_YELLOWMAP
		end

		if entry.Options then
			local sep = 60
			local option = entry.Options[entry.CurrentOption].value

			option = string.char(28).." "..$.." "..string.char(29)

			v.drawString(160 - sep, y + stringHeight * (i-1), entry.Name, V_ALLOWLOWERCASE|color, "thin-right")
			v.drawString(160 + sep, y + stringHeight * (i-1), option, V_ALLOWLOWERCASE|color, "thin")
			continue
		end

		v.drawString(160, y + stringHeight * (i-1), entry.Name, V_ALLOWLOWERCASE|color, "thin-center")
	end

	-- draw description of entry
	-- if the entry has options, draw the current options description under it

	local selection = PoyoPennynickel.Menu.Selection
	local entry = entries[selection]

	local y = 200 - 8
	if entry.Options and entry.Options[entry.CurrentOption].desc then
		y = $ - 8
	end

	v.drawString(160, y, entry.Desc, V_SNAPTOBOTTOM|V_ALLOWLOWERCASE|V_REDMAP, "thin-center")
	if entry.Options and entry.Options[entry.CurrentOption].desc then
		v.drawString(160, y + 8, entry.Options[entry.CurrentOption].desc, V_SNAPTOBOTTOM|V_ALLOWLOWERCASE|V_REDMAP, "thin-center")
	end
end)