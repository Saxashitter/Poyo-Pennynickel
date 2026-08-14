PoyoPennynickel.Menu = {
	Active = false,
	AnyKey = nil, -- if this is a function, we are on the anykey screen
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