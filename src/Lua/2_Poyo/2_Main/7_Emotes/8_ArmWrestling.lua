local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local emote = {}
table.insert(Class.emotes, emote)

emote.name = "Arm Wrestle"

-- TODO: soap support

-- da partner
Class.armWrestlePartner = nil

-- for shared info
Class.armWrestleInfo = nil

-- player cant move, so store this here
Class.armWrestleButtons = 0
Class.armWrestleLastButtons = 0

local SPR2_ARMW = rawget(_G, "SPR2_ARMW")
if SPR2_ARMW == nil then
	SPR2_ARMW = freeslot("SPR2_ARMW")
end

local ARMWRESTLE_STATES = {}
local function freeslotWrestle(state)
	local s = freeslot(state)
	ARMWRESTLE_STATES[s] = true
	return s
end

local S_PLAY_POYO_ARMWRESTLE_LOOK = freeslotWrestle("S_PLAY_POYO_ARMWRESTLE_LOOK")
local S_PLAY_POYO_ARMWRESTLE_MATCHUP = freeslotWrestle("S_PLAY_POYO_ARMWRESTLE_MATCHUP")
local S_PLAY_POYO_ARMWRESTLE_WRESTLE = freeslotWrestle("S_PLAY_POYO_ARMWRESTLE_WRESTLE")
local S_PLAY_POYO_ARMWRESTLE_RAGDOLL = freeslot("S_PLAY_POYO_ARMWRESTLE_RAGDOLL")

local function stnd(mo)
	if not mo.valid then return end
	if not mo.player then return end

	mo.player.panim = PA_IDLE
end

local function matchup(mo)
	if not mo.valid then return end
	if not mo.player then return end

	mo.frame = ($ & ~FF_FRAMEMASK)|B
end

local function wrestle(mo)
	if not mo.valid then return end
	if not mo.player then return end

	mo.frame = ($ & ~FF_FRAMEMASK)|C
end

states[S_PLAY_POYO_ARMWRESTLE_LOOK] = {SPR_PLAY, SPR2_ARMW, -1, stnd, 0, 0, S_PLAY_POYO_ARMWRESTLE_LOOK}
states[S_PLAY_POYO_ARMWRESTLE_MATCHUP] = {SPR_PLAY, SPR2_ARMW, -1, matchup, 0, 0, S_PLAY_POYO_ARMWRESTLE_MATCHUP}
states[S_PLAY_POYO_ARMWRESTLE_WRESTLE] = {SPR_PLAY, SPR2_ARMW, -1, wrestle, 0, 0, S_PLAY_POYO_ARMWRESTLE_WRESTLE}

local WRESTLE_NONE = 0
local WRESTLE_LOOKING = 1
local WRESTLE_WRESTLING = 2

function Class:getArmWrestlingState()
	local mo = self.mo

	if mo.state == S_PLAY_POYO_ARMWRESTLE_LOOK then
		return WRESTLE_LOOKING
	end

	if ARMWRESTLE_STATES[mo.state] then
		return WRESTLE_WRESTLING
	end

	return WRESTLE_NONE
end

function Class:getLookingWrestlers(distLimit)
	local mo = self.mo
	local plyrs = {}

	for player in players.iterate do
		if player == mo.player then continue end
		if not player.mo then continue end
		if not player.mo.valid then continue end
		if not player.mo.poyoChar then continue end

		local mobj = player.mo
		local class = mobj.poyoChar

		if class:getArmWrestlingState() ~= WRESTLE_LOOKING then continue end

		local dist = R_PointToDist2(mobj.x, mobj.y, mo.x, mo.y)
		if distLimit ~= nil and dist > distLimit then continue end

		if mo.z > mobj.z + mobj.height then continue end
		if mobj.z > mo.z + mo.height then continue end

		-- get distance and insert into table based on it
		local entry = {mo = mobj, player = player, dist = dist}
		local inserted = false

		for i = 1, #plyrs do
			if dist > plyrs[i].dist then continue end
	
			table.insert(plyrs, i, entry)
			inserted = true
			break
		end

		if not inserted then
			table.insert(plyrs, entry)
		end
	end

	return plyrs
end

function Class:faceArmWrestlePartner()
	local mo = self.mo
	local player = mo.player

	if not self.armWrestlePartner then return end

	player.drawangle = R_PointToAngle2(
		mo.x,
		mo.y,
		self.armWrestlePartner.mo.x,
		self.armWrestlePartner.mo.y
	)
end

function Class:setupWrestle(wrestler)
	local plyrs = {self.mo.player, wrestler}

	local info = {
		lead = self.mo.player,
		progress = FU / 2,
		countdown = 4 * TICRATE
	}

	for i, player in ipairs(plyrs) do
		local target = plyrs[2]
		if target == player then
			target = plyrs[1]
		end

		local mo = player.mo
		local class = mo.poyoChar

		class.armWrestlePartner = target
		class.armWrestleInfo = info
		mo.state = S_PLAY_POYO_ARMWRESTLE_MATCHUP
	end
end

local function approach(orig, targ, step)
	if orig > targ then
		return max(targ, orig - step)
	end

	return min(targ, orig + step)
end

emote.use = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	mo.state = S_PLAY_POYO_ARMWRESTLE_LOOK
	if class.overlayMobj and class.overlayMobj.valid then
		class.overlayMobj.state = mo.state
	end
end

local cv_wrestlepush = CV_RegisterVar{name = "poyo_wrestlepush", defaultvalue = 20, flags = CV_NETVAR}
local cv_wrestlereset = CV_RegisterVar{name = "poyo_wrestlereset", defaultvalue = 300, flags = CV_NETVAR}
emote.update = function(player, active)
	local mo = player.mo
	local class = mo.poyoChar
	local state = class:getArmWrestlingState()

	if not active then return end

	if state == 1 then
		local plyrs = class:getLookingWrestlers(128*FU)

		if plyrs[1] then
			class:setupWrestle(plyrs[1].player)
		end
	elseif state == 2 then
		local target = class.armWrestlePartner
		local info = class.armWrestleInfo

		local push = (FU / 2) / cv_wrestlepush.value -- 50
		local reset = (FU / 2) / cv_wrestlereset.value -- 300

		if not (target
			and target.valid
			and target.mo
			and target.mo.valid
			and target.mo.poyoChar
			and target.mo.poyoChar:getArmWrestlingState() > 0
		) then
			mo.state = S_PLAY_STND
			return
		end

		class:faceArmWrestlePartner()

		if info.lead == player then
			if info.countdown then
				info.countdown = $ - 1
	
				if not info.countdown then
					mo.state = S_PLAY_POYO_ARMWRESTLE_WRESTLE
					target.mo.state = S_PLAY_POYO_ARMWRESTLE_WRESTLE
				end
			else
				info.progress = approach($, FU / 2, reset)
			end
		end

		local pressed = class.armWrestleButtons & ~class.armWrestleLastButtons

		if not info.countdown then
			if pressed & BT_JUMP then
				local dir = FU

				if info.lead ~= player then
					dir = 0
				end
	
				info.progress = approach($, dir, push)

				if info.progress == dir then
					print(player.name.." wins!")
					P_DoPlayerPain(target)
				end
			end
		end
	end
end
emote.playerpreupdate = function(player, active)
	local mo = player.mo
	local class = mo.poyoChar
	local state = class:getArmWrestlingState()

	if not active then return end

	class.armWrestleLastButtons = class.armWrestleButtons
	class.armWrestleButtons = player.cmd.buttons

	if state > WRESTLE_NONE then
		player.cmd.sidemove = 0
		player.cmd.forwardmove = 0
	end
	if state == WRESTLE_WRESTLING then
		player.cmd.buttons = 0
	end
end
emote.playerupdate = function(player, active)
	-- if not active then return end

	-- HighFiveLib.Tick(player)
end
emote.active = function(player)
	local mo = player.mo
	local class = mo.poyoChar

	return class:getArmWrestlingState() > 0
end
emote.finish = function(player) end

-- hud
addHook("HUD", function(v, player, camera)
	if not player.mo then return end
	if not player.mo.valid then return end
	if not player.mo.poyoChar then return end

	local mo = player.mo
	local class = mo.poyoChar

	if class:getArmWrestlingState() ~= WRESTLE_WRESTLING then return end

	local info = class.armWrestleInfo
	if not info then return end

	local width = 60
	local height = 6
	local pad = 2
	local progress = info.progress / (FU / (width - pad * 2))

	local x = 160 - width / 2
	local y = 100 - height / 2

	v.drawFill(x, y, width, height, 31)
	v.drawFill(x + pad, y + pad, width - pad * 2, height - pad * 2, 0)
	v.drawFill(x + pad, y + pad, progress, height - pad * 2, 36)
end)