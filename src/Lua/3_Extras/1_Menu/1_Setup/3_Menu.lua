-- entries is a folder you can go in and out
function PoyoPennynickel.Menu:AddEntry(data, parent)
	if not parent then
		parent = self
	end

	if not parent.Entries then
		return
	end

	data = $ or {}
	data.Name = $ or "Option"
	data.Desc = $
	data.Admin = $ or false
	if data.Selectable == nil then
		data.Selectable = true
	end
	data.Callbacks = $ or {}
	data.Parent = parent

	local _NULL = function() end
	data.Callbacks.Enter = $ or _NULL
	data.Callbacks.Selected = $ or _NULL
	data.Callbacks.SelectionChanged = $ or _NULL
	data.Callbacks.SelectionOption = $ or _NULL

	if data.Options and not data.CurrentOption then
		data.CurrentOption = 1
	end

	parent.Entries[#parent.Entries + 1] = data
end

function PoyoPennynickel.Menu:AddWhitespace(parent)
	if not parent then
		parent = self
	end

	if not parent.Entries then
		return
	end

	parent.Entries[#parent.Entries + 1] = true
end


function PoyoPennynickel.Menu:OpenMenu(entry)
	if not entry then
		entry = self
	end

	self.Active = true
	self.Current = self
	self.Selection = 1

	S_ChangeMusic("PY_MNU", true)
end

function PoyoPennynickel.Menu:CloseMenu()
	self.Active = false
	S_ChangeMusic(mapmusname, true)
end

function PoyoPennynickel.Menu:StepSelection(i)
	self.Selection = $ + i

	if self.Selection > #self.Current.Entries then
		self.Selection = 1
	end

	if self.Selection < 1 then
		self.Selection = #self.Current.Entries
	end

	if self.Current.Entries[self.Selection] == true then
		PoyoPennynickel.Menu:StepSelection(i) -- repeat...
		return
	end

	S_StartSound(nil, sfx_menu1)
	self.Current.Callbacks.SelectionChanged()
end

function PoyoPennynickel.Menu:SelectSelection()
	local selection = self.Current.Entries[self.Selection]

	selection.Callbacks.Selected()

	if selection.Entries then
		self.Selection = 1
		self.Current = selection
		self.Current.Callbacks.Enter()
		S_StartSound(nil, sfx_menu1)
	end
end

function PoyoPennynickel.Menu:StepSelectionValue(step)
	local selection = self.Current.Entries[self.Selection]
	if not selection.Options then return end

	selection.CurrentOption = $ + step

	if selection.CurrentOption > #selection.Options then
		selection.CurrentOption = 1
	end

	if selection.CurrentOption < 1 then
		selection.CurrentOption = #selection.Options
	end

	selection.Callbacks.SelectionOption()
	S_StartSound(nil, sfx_menu1)
end

function PoyoPennynickel.Menu:StepBack()
	if not self.Current.Parent then
		self:CloseMenu()
		return
	end

	self.Current = self.Current.Parent
	self.Selection = 1
	S_StartSound(nil, sfx_menu1)
end

COM_AddCommand("poyo_menu", function()
	if isdedicatedserver then return end
	if gamestate ~= GS_LEVEL then return end
	if chatactive then return end
	if PoyoPennynickel.EmoteWheel then return end
	PoyoPennynickel.Menu:OpenMenu()
end, COM_LOCAL)

addHook("KeyDown", function(keyevent)
	if isdedicatedserver then return end
	if keyevent.repeated then return end
	if gamestate ~= GS_LEVEL then return end
	if chatactive then return end
	if PoyoPennynickel.EmoteWheel then return end

	if keyevent.name == "f1" then
		if not PoyoPennynickel.Menu.Active then
			PoyoPennynickel.Menu:OpenMenu()
			return true
		end

		PoyoPennynickel.Menu:CloseMenu()
		return true
	end

	if not PoyoPennynickel.Menu.Active then return end
	if input.keyNameToNum(keyevent.name) == input.gameControlToKeyNum(GC_CONSOLE) then return end
	if keyevent.repeated then return end

	local control = PoyoPennynickel.Menu:GetInput(keyevent)
	if not control then return end

	if control == "up" or control == "down" then
		local dir = -1
		if control == "down" then
			dir = 1
		end

		PoyoPennynickel.Menu:StepSelection(dir)
	end

	if control == "left" or control == "right" then
		local dir = -1
		if control == "right" then
			dir = 1
		end

		PoyoPennynickel.Menu:StepSelectionValue(dir)
	end

	if control == "accept" then
		PoyoPennynickel.Menu:SelectSelection()
	end

	if control == "back" then
		PoyoPennynickel.Menu:StepBack()
	end
end)