local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

-- gets players in your hitbox and runs a callback
-- if callback is not supplied then whatever
-- returns table of players hit
function Class:getPlayersInHitbox(callback)
	-- TODO: figure out if players.iterate or searchBlockmap is more optimized

	local mo = self.mo
	local player = mo.player

	local playersInside = {}

	for target in players.iterate do
		if target == player then continue end
		if not target.mo then continue end
		if not target.mo.valid then continue end
		if not target.mo.health then continue end
		if target.mo.flags & MF_NOCLIP then continue end

		local tmo = target.mo

		local dist = R_PointToDist2(mo.x, mo.y, tmo.x, tmo.y)
		if dist > mo.radius + tmo.radius then
			-- we are over the hitbox
			continue
		end

		-- these are z checks
		if mo.z > tmo.z + tmo.height then continue end
		if tmo.z > mo.z + mo.height then continue end

		if callback then
			callback(player, target)
		end

		playersInside[#playersInside + 1] = target
	end

	return playersInside
end

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	if class.flags & PAB_ASSHOLE == 0 then return end
	if player.powers[pw_strong] & STR_ATTACK == 0 then return end
	if not mo.health then return end
	if P_PlayerInPain(player) then return end

	class:getPlayersInHitbox(function(_, target)
		local tmo = target.mo

		if P_PlayerInPain(target) then return end
		if not tmo.health then return end
		if not P_DamageMobj(tmo, mo, mo) then return end

		if mo.state == S_PLAY_POYO_DASH_ATTACK then
			local angle = R_PointToAngle2(0,0, tmo.momx, tmo.momy)

			P_SetObjectMomZ(tmo, 20*FU)
			P_InstaThrust(tmo, angle, 7*mo.scale)
		end

		if mo.state == S_PLAY_POYO_DOWNWARDS_SWING then
			local angle = R_PointToAngle2(0,0, tmo.momx, tmo.momy)

			P_SetObjectMomZ(tmo, -10*FU)
			P_InstaThrust(tmo, angle, 7*mo.scale)
		end
	end)
end, 1)

local CVAR_YES_STRING = "You have been given the ability to be an asshole and hurt people as Poyo!"
local CVAR_NO_STRING = "You do not have the ability to be an asshole and hurt people as Poyo."

function Class:asshole(cvar)
	local mo = self.mo
	local player = mo.player

	cvar = $ or PoyoPennynickel.CV_Asshole

	if cvar.value == 1 then
		return (IsPlayerAdmin(player) or player == server)
	end

	return cvar.value == 2
end

PoyoPennynickel.CV_Asshole = CV_RegisterVar{
	name = "poyo_asshole",
	defaultvalue = 0,
	flags = CV_NETVAR|CV_CALL,
	PossibleValue = {Off = 0, Admin = 1, Everyone = 2},
	func = function(var)
		for player in players.iterate do
			if not player.mo then continue end
			if not player.mo.valid then continue end
			if not player.mo.poyoChar then continue end

			local enabled = player.mo.poyoChar:asshole()

			-- oh dude... this code sucks
			if enabled then
				if player.mo.poyoChar.flags & PAB_ASSHOLE == 0 then
					player.mo.poyoChar.flags = $|PAB_ASSHOLE
					CONS_Printf(player, CVAR_YES_STRING)
				end
			else
				if player.mo.poyoChar.flags & PAB_ASSHOLE then
					player.mo.poyoChar.flags = $ & ~PAB_ASSHOLE
					CONS_Printf(player, CVAR_NO_STRING)
				end
			end
		end
	end
}