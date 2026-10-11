local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

// abilities
rawset(_G, "PAB_BAT", 1 << 0) // if poyo can use his bat
rawset(_G, "PAB_SKATEBOARD", 1 << 1) // if poyo can use his skateboard
rawset(_G, "PAB_GRAPPLINGHOOK", 1 << 2) // if poyo can use his grappling hook

// modifications
rawset(_G, "PAB_BATTLE", 1 << 3) // if poyo has his battle moveset (UNIMPLEMENTED)
rawset(_G, "PAB_NOSKATEBOARDMOMENTUM", 1 << 4) // if poyo is unable to keep momentum with the skateboard
rawset(_G, "PAB_ASSHOLE", 1 << 5) // if poyos moves can harm anyone

// apply them
Class.flags = PAB_BAT|PAB_SKATEBOARD|PAB_GRAPPLINGHOOK

Class.hasSetFlags = false

-- TODO: clean this up with a hook to do the job instead of a PlayerUpdate
PoyoPennynickel:addScript("PlayerUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if class.hasSetFlags then
		return
	end

	local murder_mystery = MM and MM:isMM()
	local zombie_escape = ZE2 and ZE2.isGametype()

	if murder_mystery or zombie_escape then
		// disable everything
		class.flags = 0
	end

	if class:asshole() then
		class.flags = $|PAB_ASSHOLE
	end

	class.hasSetFlags = true
end, -1)