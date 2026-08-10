-- SUB-ENTRIES
local CustomizationMenu = {
	Name = "Customization",
	Desc = "",
	Entries = {},
	Callbacks = {}
}
local ColorOption = {
	Name = "Color",
	Desc = "",
	Options = {},
	Callbacks = {}
}

local function refreshColorEntries()
	ColorOption.Options = {
		{value = "None", desc = "", color = 0}
	}
	for i = 1, #skincolors-1 do
		if not skincolors[i].accessible then continue end
		ColorOption.Options[#ColorOption.Options+1] = {value = skincolors[i].name, desc = "", color = i}
	end
end

refreshColorEntries()
ColorOption.Callbacks.SelectionOption = function()
	COM_BufInsertText(consoleplayer, "poyo_secondcolor "..ColorOption.Options[ColorOption.CurrentOption].color)
end
CustomizationMenu.Callbacks.Enter = function()
	refreshColorEntries()
end


PoyoPennynickel.Menu:AddEntry(ColorOption, CustomizationMenu)
PoyoPennynickel.Menu:AddEntry(CustomizationMenu)