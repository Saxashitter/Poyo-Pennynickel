PoyoPennynickel.SecondColors = {
	{name = "Classic", desc = "Nothing beats it...", color = nil},
	{name = "Golfing", desc = "Sporty look on you!", color = "Poyo_Visor_White"},
	{name = "Evil", desc = "Truly a menace. Absolutely.", color = "Poyo_Visor_Evil"},
	{name = "Pepper Field", desc = "Luckily, no cats are chasing you here.", color = "Poyo_Visor_Cat"},
	{name = "Swagger", desc = "...Seems overexaggerated.", color = "Poyo_Visor_Black"},
	{name = "Laneta", desc = "A memory of a old friend that you don't know.", color = "Poyo_Visor_Purple"},
	{name = "Twin", desc = "May's favorite color, now on her brother's head!", color = "Poyo_Visor_May"},
	{name = "Quinha", desc = "Sponsored by the creator of slop.", color = "Poyo_Visor_Samusquinha"},
	{name = "Human Skin", desc = "Ew.", color = "Poyo_Visor_Scoria"}
}

local ColorMenu = {
	Name = "Second Color",
	Desc = "Choose a color for your visor, bat and the logo on your shirt!",
	Entries = {},
	Callbacks = {}
}

PoyoPennynickel.Menu:AddEntry(ColorMenu)

-- SUB-ENTRIES
local ColorOption = {
	Name = "Color",
	Desc = "",
	Options = {},
	Callbacks = {}
}

local function refreshColorEntries()
	for i, color in ipairs(PoyoPennynickel.SecondColors) do
		ColorOption.Options[i] = {value = color.name, desc = color.desc}
	end
end

ColorMenu.Callbacks.Enter = refreshColorEntries
ColorOption.Callbacks.SelectionOption = function()
	COM_BufInsertText(consoleplayer, "poyo_secondcolor "..ColorOption.CurrentOption)
end
PoyoPennynickel.Menu:AddEntry(ColorOption, ColorMenu)