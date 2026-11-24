local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local MT_POYO_GRAPPLECHAIN = freeslot("MT_POYO_GRAPPLECHAIN")
local S_POYO_GRAPPLECHAIN = freeslot("S_POYO_GRAPPLECHAIN")
if not rawget(_G, "SPR_POYO_GRAPPLEHOOK") then
	freeslot("SPR_POYO_GRAPPLEHOOK")
end
local CHAIN_FRAME = B

local LINE_DISTANCE = 38 * FU

states[S_POYO_GRAPPLECHAIN] = {
	sprite = SPR_POYO_GRAPPLEHOOK,
	frame = CHAIN_FRAME|FF_PAPERSPRITE,
	tics = -1,
	nextstate = S_NULL
}

-- this aint SHIT
mobjinfo[MT_POYO_GRAPPLECHAIN] = {
	spawnstate = S_POYO_GRAPPLECHAIN,
	radius = FU,
	height = FU,
	flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOCLIPTHING|MF_NOGRAVITY|MF_NOBLOCKMAP|MF_SCENERY
}

-- origin and dest are vector3s
function Class:createGrapplingChain(origin, dest)
    -- if this didnt exist before, now it does
    -- we dont construct it above as a default variable because it gets replicated instead of re-created

    self.grapplingChains = $ or {}

    local offset = dest - origin
    local loops = (offset / LINE_DISTANCE):magnitude()/FU
    local horz, vert = origin:angle(dest)

    for i = 1, loops do
        local t = FixedDiv(i - 1, loops)
        local position = origin + (dest - origin) * t
        local chain = self.grapplingChains[i]
    
        if not chain or not chain.valid then
            chain = P_SpawnMobj(position.x, position.y, position.z, MT_POYO_GRAPPLECHAIN)
            if not chain.valid then break end

            self.grapplingChains[i] = chain
        else
            P_MoveOrigin(chain, position.x, position.y, position.z)
        end

        if chain and chain.valid then
            chain.tics = 2
            chain.angle = horz
            chain.spriteroll = vert
        end
    end

    if loops + 1 < #self.grapplingChains then
        return
    end

    for i = loops + 1, #self.grapplingChains do
        local chain = self.grapplingChains[i]

        if chain.valid then
           P_RemoveMobj(chain)
        end

        self.grapplingChains[i] = nil
    end
end

function Class:deleteGrapplingChain()
    if not self.grapplingChains then return end

    for i = #self.grapplingChains, 1, -1 do
        local chain = self.grapplingChains[i]

        if chain.valid then
            P_RemoveMobj(chain)
        end

        self.grapplingChains[i] = nil
    end

    self.grapplingChains = nil
end