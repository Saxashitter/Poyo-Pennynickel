local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

Class.emotes = {}
Class.emoting = 0

function PoyoPennynickel.EmoteAction(mo)
	if not mo then return end
	if not mo.valid then return end
	if not mo.player then return end

	mo.player.panim = PA_IDLE
end

function Class:canEmote()
	local mo = self.mo
	local player = mo.player

	if not mo.health then return false end
	if P_PlayerInPain(player) then return false end
	if player.panim ~= PA_IDLE then return false end
	if mo.state == S_PLAY_POYO_UHOH then return false end

	return true
end

function Class:emote(i)
	local mo = self.mo
	local player = mo.player

	if not self:canEmote() then return false end
	if not self.emotes[i] then return false end

	local emote = self.emotes[i]

	if self.emoting then
		self:stopEmote()
	end

	emote.use(player)
	self.emoting = i

	return true
end

function Class:stopEmote()
	local mo = self.mo
	local player = mo.player

	if not self:canEmote() then return false end
	if not self.emoting then return false end

	local emote = self.emotes[self.emoting]

	if self.emoting then
		self.emotes[self.emoting].finish(player)
	end
	return true
end

COM_AddCommand("poyo_emote", function(player, i)
	if not player.mo then return end
	if not player.mo.valid then return end
	if not player.mo.health then return end
	if not player.mo.poyoChar then return end
	if player.mo.poyoChar.emoting then return end

	if i == nil then i = "1" end
	i = tonumber($)
	if i == nil then i = 1 end

	local result = player.mo.poyoChar:emote(i)
end)

COM_AddCommand("poyo_stopemote", function(player)
	if not player.mo then return end
	if not player.mo.valid then return end
	if not player.mo.health then return end
	if not player.mo.poyoChar then return end

	if player.mo.poyoChar.emoting then
		player.mo.state = S_PLAY_STND
	end
end)

PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
	local mo = player.mo
	local class = mo.poyoChar

	-- update emoting check
	if class.emoting then
		local new_emoting = 0

		if class:canEmote() then
			for k,v in ipairs(class.emotes) do
				if v.active(player) then
					new_emoting = k
					break
				end
			end
		end

		if not new_emoting then
			class.emotes[class.emoting].finish(player)
			class.emoting = 0
		end
	end

	-- update emotes
	for k,v in ipairs(class.emotes) do
		v.update(player, v.active(player))
	end
end)

-- local PoyoPennynickel = PoyoPennynickel
-- local Class = PoyoPennynickel.Class

-- local function animationAction(mo)
-- 	if not mo then return end
-- 	if not mo.valid then return end
-- 	if not mo.player then return end

-- 	mo.player.panim = PA_IDLE
-- end

-- local sfx_psoboy = freeslot("sfx_psoboy")
-- local sfx_py_omg = freeslot("sfx_py_omg")

-- local S_PLAY_POYO_TRASHMYSTIA = freeslot("S_PLAY_POYO_TRASHMYSTIA")
-- local S_PLAY_POYO_OOH = freeslot("S_PLAY_POYO_OOH")
-- local S_PLAY_POYO_SIXSEVEN = freeslot("S_PLAY_POYO_SIXSEVEN")

-- sfxinfo[sfx_psoboy].caption = "trash mystia"
-- sfxinfo[sfx_py_omg].caption = "OOOH"

-- states[S_PLAY_POYO_TRASHMYSTIA] = {
-- 	sprite = SPR_PLAY,
-- 	frame = SPR2_CLMB,
-- 	tics = 1,
-- 	action = animationAction,
-- 	nextstate = S_PLAY_POYO_TRASHMYSTIA
-- }

-- states[S_PLAY_POYO_OOH] = {
-- 	sprite = SPR_PLAY,
-- 	frame = SPR2_TAL1,
-- 	tics = 17,
-- 	action = animationAction,
-- 	nextstate = S_PLAY_STND
-- }
-- states[S_PLAY_POYO_SIXSEVEN] = {
-- 	sprite = SPR_PLAY,
-- 	frame = SPR2_TAL2,
-- 	tics = 2,
-- 	action = animationAction,
-- 	nextstate = S_PLAY_POYO_SIXSEVEN
-- }

-- Class.emotes = {
-- 	["trash mystia"] = function(player)
-- 		local mo = player.mo
-- 		local class = mo.poyoChar

-- 		mo.state = S_PLAY_POYO_TRASHMYSTIA
-- 		S_FadeMusic(0, 1000, player)
-- 		class.soujiaBoy = true
-- 	end,
-- 	["ooh"] = function(player)
-- 		local mo = player.mo

-- 		mo.state = S_PLAY_POYO_OOH
-- 		S_StartSound(mo, sfx_py_omg)
-- 	end,
-- 	["67"] = function(player)
-- 		local mo = player.mo

-- 		mo.state = S_PLAY_POYO_SIXSEVEN
-- 	end
-- }

-- local function toggle(player, soujia)
-- 	local mo = player.mo
-- 	local class = mo.poyoChar

-- 	if not mo.health then return end
-- 	if P_PlayerInPain(player) then return end
-- 	if player.panim ~= PA_IDLE then return end
-- 	if mo.state == S_PLAY_POYO_UHOH then return end
-- 	if player.cmd.buttons & BT_TOSSFLAG == 0 then return end
-- 	if player.lastbuttons & BT_TOSSFLAG > 0 then return end
-- 	if mo.state == S_PLAY_POYO_OOH then return end
-- 	if mo.state == S_PLAY_POYO_TRASHMYSTIA then
-- 		mo.state = S_PLAY_STND
-- 		return
-- 	end

-- 	if soujia then
-- 		mo.state = S_PLAY_POYO_TRASHMYSTIA
-- 		S_FadeMusic(0, 1000, player)
-- 		class.soujiaBoy = true
-- 	else
-- 		mo.state = S_PLAY_POYO_OOH
-- 		S_StartSound(mo, sfx_py_omg)
-- 	end
-- end

-- PoyoPennynickel:addScript("PlayerPostUpdate", function(player)
-- 	local mo = player.mo
-- 	local class = mo.poyoChar

-- 	toggle(player, player.cmd.buttons & BT_WEAPONNEXT == 0)

-- 	if mo.state == S_PLAY_POYO_TRASHMYSTIA then
-- 		if not S_SoundPlaying(mo, sfx_psoboy) then
-- 			S_StartSoundAtVolume(mo, sfx_psoboy, 75)
-- 		end

-- 		return
-- 	end
-- 	if not class.soujiaBoy then return end

-- 	class.soujiaBoy = false
-- 	S_StopSoundByID(mo, sfx_psoboy)
-- 	if mo.state ~= S_PLAY_POYO_UHOH then
-- 		S_FadeMusic(100, 1000, player)
-- 	end
-- end)

-- addHook("PlayerMsg", function(player, type, target, msg)
-- 	if type then return end
-- 	if target then return end

-- 	if not player then return end
-- 	if not player.mo then return end
-- 	if not player.mo.valid then return end
-- 	if not player.mo.poyoChar then return end

-- 	print("Poyo!")
-- 	local mo = player.mo
-- 	local class = mo.poyoChar

-- 	if not mo.health then return end
-- 	if P_PlayerInPain(player) then return end
-- 	if player.panim ~= PA_IDLE then return end
-- 	if mo.state == S_PLAY_POYO_UHOH then return end

-- 	msg = $:lower()

-- 	if not class.emotes[msg] then return end
-- 	class.emotes[msg](player)
-- end)