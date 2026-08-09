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