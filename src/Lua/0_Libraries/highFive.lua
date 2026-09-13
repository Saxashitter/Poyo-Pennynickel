-- created as a way for me and my friends to high five each others characters
-- by me, #saxa

-- add your characters here in this table
local chars = {"poyo"}

if HighFiveLib then
	for _, char in ipairs(chars) do
		HighFiveLib.SupportedChars[char] = true
	end
	return
end

local function safe_freeslot(...)
	for i = 1, select("#", ...)
		if rawget(_G, select(i, ...)) ~= nil then
			continue
		end

		freeslot(select(i, ...))
	end
end

safe_freeslot("MT_HIGHFIVELIB_CORONA", "S_HIGHFIVELIB_CORONA", "SPR_HIGHFIVELIB_CORONA", "sfx_hifive")

states[S_HIGHFIVELIB_CORONA] = {
	sprite = SPR_HIGHFIVELIB_CORONA,
	frame = FF_FULLBRIGHT,
	tics = -1
}

mobjinfo[MT_HIGHFIVELIB_CORONA] = {
	spawnstate = S_HIGHFIVELIB_CORONA,
	radius = 16*FRACUNIT,
	height = 16*FRACUNIT,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPTHING|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY
}

sfxinfo[sfx_hifive].caption = "High five!"

local function SpawnCorona(x, y, z, scale, flip)
	local mo = P_SpawnMobj(x, y, z, MT_HIGHFIVELIB_CORONA)
	local beam = mo
	mo.scale = scale
	mo.blendmode = AST_ADD
	
	if flip
		mo.eflags = $ | MFE_VERTICALFLIP
		mo.z = $ - mo.height
	end
	
	// spawn beams
	for i = 1, 6
		beam.tracer = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_OVERLAY)
		beam = $.tracer
		
		beam.target = mo
		beam.blendmode = AST_ADD
		beam.state = mo.state
		beam.frame = $ & ~FF_FRAMEMASK | (B + P_RandomKey(8))
		beam.rollangle = FixedAngle(FixedMul(P_RandomFixed(), 360*FRACUNIT))
		beam.movedir = (-1 + P_RandomKey(2) * 2) * ANG1
		beam.extravalue1 = (-1 + P_RandomKey(2) * 2)
	end
	return mo
end

addHook("MobjThinker", function(mo)
	local trans
	
	if leveltime & 1
		mo.frame = $ + FF_TRANS10
	end
	trans = mo.frame & FF_TRANSMASK
	if trans > FF_TRANS90
		P_RemoveMobj(mo)
		return
	end
	
	local beam = mo.tracer
	while (beam and beam.valid)
		local frame = beam.frame & FF_FRAMEMASK
		
		if leveltime & 1
			if (frame - B) % 4 == 0
				beam.extravalue1 = 1
			elseif (frame - B) % 4 == 3
				beam.extravalue1 = -1
			end
			
			frame = $ + beam.extravalue1
		end
		
		beam.rollangle = $ + beam.movedir
		beam.frame = $ & ~(FF_FRAMEMASK|FF_TRANSMASK) | frame | trans
		beam = $.tracer
	end
end, MT_HIGHFIVELIB_CORONA)


rawset(_G, "HighFiveLib", {})
HighFiveLib.SupportedChars = $ or {}

for _, char in ipairs(chars) do
	HighFiveLib.SupportedChars[char] = true
end

safe_freeslot("SPR2_HI5_")
spr2defaults[SPR2_HI5_] = SPR2_SPNG

HighFiveLib.LookState = freeslot("S_PLAY_HIGHFIVELIB_LOOK")
HighFiveLib.HighFiveState = freeslot("S_PLAY_HIGHFIVELIB_HIGHFIVE")
HighFiveLib.HighFiveFinishState = freeslot("S_PLAY_HIGHFIVELIB_HIGHFIVEFINISH")

states[HighFiveLib.LookState] = {sprite = SPR_PLAY, frame = SPR2_HI5_, tics = -1}
states[HighFiveLib.HighFiveState] = {sprite = SPR_PLAY, frame = SPR2_HI5_, tics = -1}
states[HighFiveLib.HighFiveFinishState] = {sprite = SPR_PLAY, frame = SPR2_HI5_, tics = 15, nextstate = S_PLAY_FALL}

HighFiveLib.LeapThrust = 8*FRACUNIT
HighFiveLib.LeapZThrust = 64*FU

local function look_for_players(player) end

-- starts the entire thing
function HighFiveLib.Look(player)
	local mo = player.mo

	mo.state = HighFiveLib.LookState
	mo.highfivelib_highFivePartner = nil
	mo.highfivelib_highFiveDelay = nil
	mo.highfivelib_highFiveState = 0

	-- check around yourself for players
	-- TODO: actually do that
	-- look_for_players(player)
	return true
end

local function TryNudge(mo)
	for x = -1, 0, 1
		for y = -1, 0, 1
			if x == 0
			and y == 0
				continue
			end
			
			if P_TryMove(mo, mo.x + x*FRACUNIT, mo.y + y*FRACUNIT, false)
				return true
			end
		end
	end
	return false
end

function HighFiveLib.StartHighFive(player1, player2)
	local mo1, mo2 = player1.mo, player2.mo
	
	// try to separate players if they are in the same position,
	// otherwise they won't face each other and the high five won't connect
	if ((mo1.x - mo2.x) / FRACUNIT) == 0
	and ((mo1.y - mo2.y) / FRACUNIT) == 0
		TryNudge(mo2)
	end
	
	// set these players as each other's partners
	for i = 1, 2
		mo1.state = HighFiveLib.HighFiveState
		mo1.player.drawangle = R_PointToAngle2(mo1.x, mo1.y, mo2.x, mo2.y)
		mo1.highfivelib_highFivePartner = mo2.player
		mo1.highfivelib_highFiveState = 1
		mo1.highfivelib_highFiveDelay = 10
		mo1.frame = ($ & ~FF_FRAMEMASK)|B
		S_StartSound(nil, sfx_cdfm60, mo1.player)
		
		mo1, mo2 = $2, $1
	end
end

function HighFiveLib.IsHighFiving(player)
	return player
	and player.valid
	and player.mo
	and player.mo.valid
	and HighFiveLib.SupportedChars[player.mo.skin]
	and (player.mo.state == HighFiveLib.LookState
		or player.mo.state == HighFiveLib.HighFiveState
		or player.mo.state == HighFiveLib.HighFiveFinishState
	)
end

local function ActiveHighFiveState(player)
	return HighFiveLib.IsHighFiving(player) and player.mo.highfivelib_highFiveState > 0 and player.mo.highfivelib_highFiveState <= 3
end

function HighFiveLib.Tick(player)
	if not HighFiveLib.IsHighFiving(player) then
		if player.mo and player.mo.valid and player.mo.highfivelib_highFiveState then
			player.mo.highfivelib_highFiveState = nil
		end
		return
	end

	local mo = player.mo
	
	// searching for a high five partner
	if mo.highfivelib_highFiveState == 0
		local closestDist = FixedMul(256*FRACUNIT, mo.scale)
		local closestPlayer
		
		for player2 in players.iterate
			local mo2 = player2.mo
			
			if player == player2
			or not HighFiveLib.IsHighFiving(player2)
			or (mo2.eflags & MFE_VERTICALFLIP ~= mo.eflags & MFE_VERTICALFLIP)
				continue
			end
			
			local dist = FixedHypot(FixedHypot(mo2.x - mo.x, mo2.y - mo.y),
				(mo2.z + (mo2.height >> 1)) - (mo.z + (mo.height >> 1)))
			
			if dist > closestDist
				continue
			end
			
			closestPlayer = player2
			closestDist = dist
		end
		
		if not closestPlayer
			return
		end
		
		HighFiveLib.StartHighFive(player, closestPlayer)
		if #closestPlayer < #player
			return // ensure both players' timers start counting down on the same tic
		end
	end
	
	// performing a high five
	if ActiveHighFiveState(player)
		local partner = mo.highfivelib_highFivePartner
		local partnerMo = ActiveHighFiveState(partner) and partner.mo
		
		// if the partner exits the commitment, return to search state
		if not (partner and partner.valid)
		or not partnerMo
		or (partnerMo.eflags & MFE_VERTICALFLIP ~= mo.eflags & MFE_VERTICALFLIP)
			if mo.highfivelib_highFiveState then
				mo.state = S_PLAY_FALL
			end
			mo.highfivelib_highFiveState = nil
			return
		end
		
		// face your partner
		player.drawangle = R_PointToAngle2(mo.x, mo.y, partnerMo.x, partnerMo.y)
		
		// initiation: pause for a second so you see your partner
		if mo.highfivelib_highFiveState == 1
			// force the camera to swing to a side view
			// this doesn't work in old analog mode but I don't care, all my homies hate old analog mode
			mo.angle = player.drawangle + ANGLE_90
			
			// once the timer is up, leap towards your partner
			mo.highfivelib_highFiveDelay = $ - 1
			if mo.highfivelib_highFiveDelay <= 0
				local flip = P_MobjFlip(mo)
				local grav = P_GetMobjGravity(mo)
				local scale = (mo.destscale + partnerMo.destscale)/2
				local hSpeed = FixedMul(HighFiveLib.LeapThrust, scale)
				local hDist = FixedHypot(mo.x - partnerMo.x, mo.y - partnerMo.y)/2 - (mo.radius + partnerMo.radius)
				local goalZ, vDist

				if mo.eflags & MFE_VERTICALFLIP
					goalZ = min(mo.z + mo.height, partnerMo.z + partnerMo.height) - FixedMul(HighFiveLib.LeapZThrust, scale)
					vDist = goalZ - (mo.z + mo.height)
				else
					goalZ = max(mo.z, partnerMo.z) + FixedMul(HighFiveLib.LeapZThrust, scale)
					vDist = goalZ - mo.z
				end
				
				mo.z = $ + flip // raise the player above the ground
				if mo.standingslope // this will trigger a slope launch next tic, so we have to do ugly hacks to bypass this...
					local x, y, z = mo.x, mo.y, mo.z // store their current position
					P_XYMovement(mo) // trigger the slope launch early (AWFUL)
					P_SetOrigin(mo, x, y, z) // teleport them back to their initial position
				end
				mo.momz = flip*FixedSqrt(abs(2 * FixedMul(grav, vDist)))
				P_InstaThrust(mo, player.drawangle, -FixedDiv(hDist, FixedDiv(mo.momz, grav)))
				print(hDist)
				
				player.panim = PA_FALL
				mo.highfivelib_highFiveState = 2
				// I don't know why but the sounds stop immediately if they just play
				if player == displayplayer
					S_StartSound(nil, sfx_ngjump, player)
				elseif partner != displayplayer
					S_StartSound(mo, sfx_ngjump)
				end
			end
			// disable controls
			player.pflags = $ | PF_FULLSTASIS
		end
		
		// during the leap
		if mo.highfivelib_highFiveState == 2
			// check whether we made contact with our partner!
			local scale = (mo.destscale + partnerMo.destscale)/2
			local zDist
			if mo.eflags & MFE_VERTICALFLIP
				zDist = abs((mo.z + mo.height) - (partnerMo.z + partnerMo.height))
			else
				zDist = abs(mo.z - partnerMo.z)
			end
			
			if partnerMo.highfivelib_highFiveState == 2 // no highfiving people on the ground LOL
			and zDist <= FixedMul(abs(16*FRACUNIT), scale)
				local dist = FixedDiv(FixedHypot(mo.x - partnerMo.x, mo.y - partnerMo.y), scale)
				if dist <= 70*FRACUNIT
				and dist >= 70*FRACUNIT - 9*FRACUNIT
					HighFiveLib.HighFiveContact(player, partner)
				end
			end
					
			// disable controls
			player.pflags = $ | PF_FULLSTASIS
		end

		if mo.highfivelib_highFiveState == 3
			// force the camera to swing to a side view
			// this doesn't work in old analog mode but I don't care, all my homies hate old analog mode
			mo.angle = player.drawangle + ANGLE_90

			mo.momx = 0
			mo.momy = 0
			mo.momz = 0
			// disable controls
			player.pflags = $ | PF_FULLSTASIS
		end
	end
end

function HighFiveLib.HighFiveContact(player, player2)
	local mo, mo2 = player.mo, player2.mo
	local scale = (mo.scale + mo2.scale)/2
	local x, y = mo.x/2 + mo2.x/2, mo.y/2 + mo2.y/2
	
	if mo.eflags & MFE_VERTICALFLIP
		local z = (mo.z + mo.height)/2 + (mo2.z + mo2.height)/2
		S_StartSound(SpawnCorona(x, y, z, scale, true), sfx_thok)
	else
		local z = (mo.z/2 + mo2.z/2)
		S_StartSound(SpawnCorona(x, y, z, scale), sfx_thok)
	end
	
	for i = 1, 2
		local mo = player.mo
		
		--CC.StartHitLag(player, TICRATE/2)
		mo.state = HighFiveLib.HighFiveFinishState
		mo.frame = ($ & ~FF_FRAMEMASK)|B
		mo.highfivelib_highFiveState = 3
		mo.momx = 0
		mo.momy = 0
		mo.momz = 0
		
		player = player2
	end
end

-- placeholder
-- addHook("PlayerThink", function(player)
-- 	if not HighFiveLib.IsHighFiving(player) then return end
-- 	HighFiveLib.Tick(player)
-- end)

-- COM_AddCommand("highfive", function(player)
-- 	HighFiveLib.Look(player)
-- end)