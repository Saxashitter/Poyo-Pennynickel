local EMOTE_KEY = "b"
local EMOTE_CONFIRM_KEY = "mouse1"
local EMOTE_LEAVE_KEY = "escape"
local MENU_ACTIVE = true
local CURSOR_X = 0
local CURSOR_Y = 0

local SCREEN_WIDTH = 320
local SCREEN_HEIGHT = 200
local SCREEN_SCALE_X = 1
local SCREEN_SCALE_Y = 1

local DEADZONE = 8 -- pixels from center where selection doesn't change
local CURRENT_SELECTION = 1

local CMD_ANGLE = 0
local CMD_AIMING = 0

local function clamp(val, a, b)
	return max(a, min(val, b))
end

local function getWheelSelection()
	local NUM_EMOTES = #PoyoPennynickel.Class.emotes
	local center_x, center_y = SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2
	local dist = R_PointToDist2(center_x*FU, center_y*FU, CURSOR_X*FU, CURSOR_Y*FU)

	if dist < DEADZONE * FRACUNIT then
		return CURRENT_SELECTION
	end

	local angle = R_PointToAngle2(center_x*FU, center_y*FU, CURSOR_X*FU, CURSOR_Y*FU)
	local split = 360*FU/NUM_EMOTES
	local rel = AngleFixed(InvAngle(angle + ANGLE_90)) -- ANGLE_90 - angle, wrapped positive

	rel = ($ + split/2) % (360*FU)

	return (FixedTrunc(FixedDiv(rel, split))/FU) + 1
end

addHook("KeyDown", function(keyevent)
	if isdedicatedserver then return end
	if keyevent.repeated then return end
	if gamestate ~= GS_LEVEL then return end
	-- this is what ChatGPT told me to do
	if chatactive then return end

	if not consoleplayer then return end
	if not consoleplayer.valid then return end

	local player = consoleplayer

	if not player.mo then return end
	if not player.mo.valid then return end
	if not player.mo.poyoChar then return end
	if not player.mo.poyoChar:canEmote() then return end

	if not MENU_ACTIVE and keyevent.name == EMOTE_KEY then
		if player.mo.poyoChar.emoting then
			COM_BufInsertText(consoleplayer, "poyo_stopemote")
			return true
		end

		CURSOR_X = SCREEN_WIDTH / 2
		CURSOR_Y = SCREEN_HEIGHT / 2
		MENU_ACTIVE = true
		return true
	end

	if MENU_ACTIVE and keyevent.name == EMOTE_LEAVE_KEY then
		MENU_ACTIVE = false
		return true
	end

	if MENU_ACTIVE and (keyevent.name == EMOTE_CONFIRM_KEY or keyevent.name == EMOTE_KEY) then
		COM_BufInsertText(consoleplayer, "poyo_emote "..CURRENT_SELECTION)
		MENU_ACTIVE = false
		return true
		-- also enable cooldown
	end

	if MENU_ACTIVE then
		return true
	end
end)

addHook("ThinkFrame", function()
	if not MENU_ACTIVE then return end

	if not (
		consoleplayer
		and consoleplayer.valid
		and consoleplayer.mo
		and consoleplayer.mo.valid
		and consoleplayer.mo.poyoChar
		and consoleplayer.mo.poyoChar:canEmote()
	) then
		MENU_ACTIVE = false
		return
	end

	CURSOR_X = clamp($ + mouse.rdx, 0, SCREEN_WIDTH)
	CURSOR_Y = clamp($ + mouse.rdy, 0, SCREEN_HEIGHT)

	CURRENT_SELECTION = getWheelSelection()
end)

addHook("PlayerCmd", function(player, cmd)
	if not MENU_ACTIVE then
		CMD_ANGLE = cmd.angleturn
		CMD_AIMING = cmd.aiming
	else
		cmd.angleturn = CMD_ANGLE
		cmd.aiming = CMD_AIMING
	end
end)

addHook("HUD", function(v, player, camera)
	SCREEN_WIDTH = v.width()
	SCREEN_HEIGHT = v.height()
	SCREEN_SCALE_X = v.dupx()
	SCREEN_SCALE_Y = v.dupy()

	if not MENU_ACTIVE then return end

	local flags = V_SNAPTOLEFT|V_SNAPTOTOP
	local cursor = v.cachePatch("POYO_CURSOR")
	local wheel = v.cachePatch("POYO_TAUNTWHEEL")

	v.drawScaled(160*FU, 100*FU, FU/2, wheel, V_40TRANS)
	v.draw(CURSOR_X, CURSOR_Y, cursor, flags|V_NOSCALEPATCH|V_NOSCALESTART)

	local split = 360*FU/#PoyoPennynickel.Class.emotes

	for i, emote in ipairs(PoyoPennynickel.Class.emotes) do
		local angle = -ANGLE_90
		local thrust = 45*FU
		local flags = 0

		if i == CURRENT_SELECTION then
			flags = V_YELLOWMAP
		end

		angle = $ - FixedAngle(split*(i-1))

		v.drawString(
			160*FU + P_ReturnThrustX(nil, angle, thrust),
			100*FU + P_ReturnThrustY(nil, angle, thrust) - 4*FU,
			emote.name,
			flags,
			"thin-fixed-center")
	end
end)