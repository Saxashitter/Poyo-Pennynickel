local MENU_TWEEN = 0
local MENU_TICS = 8

local function menu(v)
	if not PoyoPennynickel.Menu.Active then
		MENU_TWEEN = max(0, $ - FU / MENU_TICS)
	else
		MENU_TWEEN = min(FU, $ + FU / MENU_TICS)
	end
	if MENU_TWEEN == 0 then return end

	local player = consoleplayer

	local screenWidth = v.width() / v.dupx()
	local screenHeight = v.height() / v.dupy()

	local background = v.cachePatch("~031")
	local scaleX = FixedDiv(screenWidth, background.width)
	local scaleY = FixedDiv(screenHeight, background.height)

	local trans = 10 - FixedMul(10, MENU_TWEEN)
	if trans < 10 then
		v.drawStretched(0, 0, scaleX, scaleY, background, V_SNAPTOLEFT|V_SNAPTOTOP|(max(trans, 4) * V_10TRANS))
	end

	-- draw background
	local banner = v.cachePatch("LTZIGRED")
	local tics = 180
	local t = FixedDiv(leveltime % tics, tics)
	local offsetY = FixedMul(banner.height*FU, t)
	local bannerX = ease.linear(MENU_TWEEN, -banner.width*FU, 0)

	for i = -banner.height*FU, screenHeight*FU, banner.height*FU do
		v.drawScaled(bannerX, i + offsetY, FU, banner, V_SNAPTOLEFT|V_SNAPTOTOP)
	end

	-- bing chillin
	local poyo = v.cachePatch("POYO_BINGCHILLING_1")
	local visor = v.cachePatch("POYO_BINGCHILLING_2")
	local poyomap = nil
	local translatemap = nil

	if player and player.valid then
		poyomap = v.getColormap(player.skin, player.skincolor)

		if player.poyo_secondcolor then
			visor = v.cachePatch("POYO_BINGCHILLING_3")
			translatemap = v.getColormap(nil, player.poyo_secondcolor)
		end
	end

	local poyo_x = ease.linear(MENU_TWEEN, 320*FU, 220*FU)

	v.drawScaled(poyo_x, 70*FU, FU/8, poyo, V_SNAPTORIGHT|V_SNAPTOBOTTOM, poyomap)
	v.drawScaled(poyo_x, 70*FU, FU/8, visor, V_SNAPTORIGHT|V_SNAPTOBOTTOM, translatemap)

	-- draw all entries
	if trans == 10 then return end

	local entries = PoyoPennynickel.Menu.Current.Entries
	local stringHeight = 12
	local trueStringHeight = 8
	local y = 100 - (stringHeight * max(0, #entries - 2) / 2) - (trueStringHeight * min(#entries, 2) / 2)
	for i, entry in ipairs(entries) do
		if entry == true then continue end

		local color = 0

		if i == PoyoPennynickel.Menu.Selection then
			color = V_YELLOWMAP
		end

		if entry.Options or entry.Value then
			local sep = 60
			local option = entry.Value

			if entry.Options then
				option = entry.Options[entry.CurrentOption].value
				option = string.char(28).." "..$.." "..string.char(29)
			end

			v.drawString(160 - sep, y + stringHeight * (i-1), entry.Name, V_ALLOWLOWERCASE|(trans * V_10TRANS)|color, "thin-right")
			v.drawString(160 + sep, y + stringHeight * (i-1), option, V_ALLOWLOWERCASE|(trans * V_10TRANS)|color, "thin")

			-- need this specifically for coloring
			if entry.DrawOption then
				entry.DrawOption(v, 160 + sep, y + stringHeight * (i-1), trans)
			end
			continue
		end

		v.drawString(160, y + stringHeight * (i-1), entry.Name, V_ALLOWLOWERCASE|(trans * V_10TRANS)|color, "thin-center")
	end

	-- draw description of entry
	-- if the entry has options, draw the current options description under it

	local selection = PoyoPennynickel.Menu.Selection
	local entry = entries[selection]

	local y = 200 - 8
	if entry.Options and entry.Options[entry.CurrentOption].desc then
		y = $ - 8
	end

	v.drawString(160, y, entry.Desc, V_SNAPTOBOTTOM|V_ALLOWLOWERCASE|V_REDMAP|(trans * V_10TRANS), "thin-center")
	if entry.Options and entry.Options[entry.CurrentOption].desc then
		v.drawString(160, y + 8, entry.Options[entry.CurrentOption].desc, V_SNAPTOBOTTOM|V_ALLOWLOWERCASE|V_REDMAP|(trans * V_10TRANS), "thin-center")
	end
end

local function anyKey(v)
	if not PoyoPennynickel.Menu.Active then return end
	if not PoyoPennynickel.Menu.AnyKey then return end

	local screenWidth = v.width() / v.dupx()
	local screenHeight = v.height() / v.dupy()

	local background = v.cachePatch("~031")
	local scaleX = FixedDiv(screenWidth, background.width)
	local scaleY = FixedDiv(screenHeight, background.height)

	v.drawStretched(0, 0, scaleX, scaleY, background, V_SNAPTOLEFT|V_SNAPTOTOP|(4 * V_10TRANS))

	-- we will be unhardcoding this later down the line
	local str = {"Hit the new key for this button", "Press Backspace to cancel"}
	local width = 0
	local height = 10 * #str

	for _, str in ipairs(str)
		width = max($, v.stringWidth(str, V_ALLOWLOWERCASE))
	end

	v.drawFill(160 - width / 2 - 4, 100 - height / 2 - 4, width + 8, height + 8, 159)
	for i, str in ipairs(str) do
		v.drawString(160, 100 - height / 2 + 10 * (i-1), str, V_ALLOWLOWERCASE, "center")
	end
end

local function drawer(v)
	menu(v)
	anyKey(v)
end

addHook("HUD", drawer)