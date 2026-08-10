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

refreshColorEntries()
ColorOption.Callbacks.SelectionOption = function()
	COM_BufInsertText(consoleplayer, "poyo_secondcolor "..ColorOption.CurrentOption)
end
PoyoPennynickel.Menu:AddEntry(ColorOption)