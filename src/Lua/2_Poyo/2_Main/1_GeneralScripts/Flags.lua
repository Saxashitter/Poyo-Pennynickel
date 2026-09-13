local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

// abilities
rawset(_G, "PAB_BAT", 1 << 0) // if poyo can use his bat
rawset(_G, "PAB_SKATEBOARD", 1 << 1) // if poyo can use his skateboard
rawset(_G, "PAB_GRAPPLINGHOOK", 1 << 2) // if poyo can use his grappling hook

// apply them
Class.flags = PAB_BAT|PAB_SKATEBOARD|PAB_GRAPPLINGHOOK