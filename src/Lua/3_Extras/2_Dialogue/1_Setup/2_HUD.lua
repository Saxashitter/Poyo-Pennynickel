function PoyoPennynickel.drawWordWrapString(v, x, y, string, flags, font, width)
	-- fallback font
	font = font or "thin"
	width = width or 0

	-- raw font
	local realFont
	if font:find("thin") then
		realFont = "thin"
	end
	if font:find("small") then
		realFont = "small"
	end

	local spaceWidth = 4 * FU

	local currentX = x
	local currentY = y

	for line in string:gmatch("[^\n]+") do
		for word in line:gmatch("%S+") do
			local wordWidth = v.stringWidth(word, flags, realFont) * FU

			if currentX + wordWidth + spaceWidth >= width then
				currentX = x
				currentY = $ + 8 * FU -- TODO: get string height
			end

			v.drawString(currentX, currentY, word, flags, font)

			currentX = $ + wordWidth + spaceWidth
		end

		-- newline
		currentX = x
		currentY = $ + 8 * FU
	end
end