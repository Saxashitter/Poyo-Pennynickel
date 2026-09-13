local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local emote = {}
table.insert(Class.emotes, emote)

-- LOGIC
emote.name = "High Five"
emote.use = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	HighFiveLib.Look(player)
	if class.overlayMobj and class.overlayMobj.valid then
		class.overlayMobj.state = mo.state
	end
end
emote.update = function(player, active) end
emote.playerupdate = function(player, active)
	if not active then return end

	HighFiveLib.Tick(player)
end
emote.active = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	return HighFiveLib.IsHighFiving(player)
end
emote.finish = function(player) end