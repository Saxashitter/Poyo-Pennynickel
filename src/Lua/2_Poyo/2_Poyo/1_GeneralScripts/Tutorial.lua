local function isTutorial(map)
	if map == nil then map = gamemap end
	return mapheaderinfo[map].poyopennynickel_tutorial == "true"
end

addHook("MapLoad", function()
	if not isTutorial() then return end

	PoyoPennynickel.setTextset("tutorial_start")
end)

addHook("LinedefExecute", function(line, mobj, sector)
	if not isTutorial() then return end

	PoyoPennynickel.setTextset("tutorial_start")
end, "PYTUDSAT")

rawset(_G, "tutorial_dashattack", function() print("test") end)