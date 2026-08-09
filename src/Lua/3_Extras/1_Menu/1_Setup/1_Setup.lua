PoyoPennynickel.Menu = {
	Active = false,
	Selection = 1,
	Entries = {},
	Callbacks = {},
	BoolOption = {{value = "Off"}, {value = "On"}},
}

local _NULL = function() end
PoyoPennynickel.Menu.Callbacks.Enter = $ or _NULL
PoyoPennynickel.Menu.Callbacks.Selected = $ or _NULL
PoyoPennynickel.Menu.Callbacks.SelectionChanged = $ or _NULL
PoyoPennynickel.Menu.Callbacks.SelectionOption = $ or _NULL