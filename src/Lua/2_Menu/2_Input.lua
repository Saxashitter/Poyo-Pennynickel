local function keyTbl(...)
	local tbl = {}
	for i = 1, select("#", ...) do
		tbl[select(i, ...)] = true
	end

	return tbl
end

PoyoPennynickel.Menu.Controls = {
	left = keyTbl("left arrow"),
	down = keyTbl("down arrow"),
	up = keyTbl("up arrow"),
	right = keyTbl("right arrow"),
	accept = keyTbl("enter"),
	back = keyTbl("escape")
}

function PoyoPennynickel.Menu:GetInput(keyevent)
	for name, input in pairs(self.Controls) do
		if input[keyevent.name] then
			return name
		end
	end
end

addHook("KeyDown", function(keyevent)
	if not PoyoPennynickel.Menu.Active then return end
	if input.keyNameToNum(keyevent.name) == input.gameControlToKeyNum(GC_CONSOLE) then return end
	if isdedicatedserver then return end
	if gamestate ~= GS_LEVEL then return end
	if chatactive then return end
	return true
end)

-- inputs are handled in 3_Menu... i dont feel like making a hook system