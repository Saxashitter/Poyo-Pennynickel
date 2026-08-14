-- SUB-ENTRIES

local keys = {
	{Name = "Emote Key", Variable = "EmoteKey"},
	{Name = "Emote Confirm Key", Variable = "EmoteConfirmKey"},
	{Name = "Emote Back Key", Variable = "EmoteLeaveKey"},
	{Name = "Emote Variants Key", Variable = "EmoteAltKey"}
}
for _, key in ipairs(keys) do
	local EmoteKeyOption = {
		Name = key.Name,
		Desc = "",
		Callbacks = {},
		Value = PoyoPennynickel[key.Variable]
	}

	local function keyRebind(variable)
		return function()
			PoyoPennynickel.Menu.AnyKey = function(keyevent)
				if keyevent.name == "backspace" then return end
				PoyoPennynickel[variable] = keyevent.name
				S_StartSound(nil, sfx_s3k63)
				EmoteKeyOption.Value = keyevent.name
			end
		end
	end
	EmoteKeyOption.Callbacks.Selected = keyRebind(key.Variable)
	PoyoPennynickel.Menu:AddEntry(EmoteKeyOption)
end