addHook("HUD", function(v, player, camera)
	if not PoyoPennynickel.Dialogue.CurrentText then return end

	local currentSet = PoyoPennynickel.Dialogue.Textsets[PoyoPennynickel.Dialogue.CurrentText]
	local currentLine = currentSet.text[PoyoPennynickel.Dialogue.LineIndex]

	local boxHeight = 60
	local portraitHeight = 60

	-- PORTRAITS
	local portraitY = 200 * FU - boxHeight

	for name, portrait in pairs(currentSet.characters) do
		local offsetY = 0

		local character = PoyoPennynickel.Dialogue.Characters[name]
		local expression = character.expressions.default
		local patch, flip = v.getSprite2Patch(character.skin, expression.sprite, false, A, portrait.rotation, 0)
		local flags = V_SNAPTOBOTTOM|portrait.flags
		local color = nil

		if currentLine.character ~= name then
			color = v.getColormap(TC_RAINBOW, SKINCOLOR_GREY)
			offsetY = $ + 10 * FU
		elseif character.setColorBasedOnPlayer and displayplayer and displayplayer.valid then
			color = v.getColormap(character.skin, displayplayer.skincolor)
		else
			color = v.getColormap(character.skin, character.color)
		end

		if flip then
			if flags & V_FLIP then
				flags = $ & ~V_FLIP
			else
				flags = $|V_FLIP
			end
		end
		if portrait.flip then
			if flags & V_FLIP then
				flags = $ & ~V_FLIP
			else
				flags = $|V_FLIP
			end
		end

		v.drawScaled(
			portrait.position*FU + character.x_offset*FU,
			200 * FU - portraitHeight*FU - character.y_offset*character.scale + offsetY,
			character.scale,
			patch, 
			flags,
			color
		)
	end

	-- BOX
	local box = v.cachePatch("~031")
	local screenWidth = v.width() / v.dupx()
	local screenHeight = v.height() / v.dupy()

	local scaleX = FixedDiv(screenWidth, box.width)
	local scaleY = FixedDiv(boxHeight, box.height)

	v.drawStretched(0, 200 * FU - boxHeight * FU, scaleX, scaleY, box, V_SNAPTOLEFT|V_SNAPTOBOTTOM|V_30TRANS)

	-- TEXT
	local textX = 6
	local textY = 6

	PoyoPennynickel.drawWordWrapString(v,
		textX*FU,
		200*FU - boxHeight*FU + textY*FU,
		currentLine.text:sub(1, PoyoPennynickel.Dialogue.LinePosition),
		V_SNAPTOLEFT|V_SNAPTOBOTTOM|V_ALLOWLOWERCASE,
		"thin-fixed",
		screenWidth * FU - (textX * 2) * FU
	)
end)