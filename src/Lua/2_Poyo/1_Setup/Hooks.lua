local scripts = {}
local PoyoPennynickel = PoyoPennynickel
local Class = PoyoPennynickel.Class

local function isPoyo(player)
	return player.mo and player.mo.valid and player.mo.skin == "poyo"
end

local function safeInitPoyo(player)
	if not isPoyo(player) then
		if player.mo and player.mo.valid then
			player.mo.poyoChar = nil
		end

		return false
	end

	player.mo.poyoChar = $ or Class.new(player.mo)
	return true
end

local function _callScripts(scriptName, ...)
	if not scripts[scriptName] then return end

	local returns = nil
	for _, func in ipairs(scripts[scriptName].pre) do
		returns = func(...) or returns
	end
	for _, func in ipairs(scripts[scriptName].cur) do
		returns = func(...) or returns
	end
	for _, func in ipairs(scripts[scriptName].post) do
		returns = func(...) or returns
	end


	return returns
end

function PoyoPennynickel:addScript(name, script, type)
	scripts[name] = $ or {pre = {}, cur = {}, post = {}}

	local tbl = scripts[name].cur

	if type == -1 then
		tbl = scripts[name].pre
	elseif type == 1 then
		tbl = scripts[name].post
	end

	tbl[#tbl + 1] = script
end

addHook("PreThinkFrame", function()
	for player in players.iterate do
		if not safeInitPoyo(player) then continue end

		_callScripts("PlayerPreUpdate", player)
	end
end)

addHook("ThinkFrame", function()
	for player in players.iterate do
		if not safeInitPoyo(player) then continue end

		_callScripts("PlayerPostUpdate", player)
	end
end)

addHook("PlayerSpawn", function(player)
	if not safeInitPoyo(player) then return end

	return _callScripts("PlayerSpawn", player)
end)

addHook("PlayerThink", function(player)
	if not safeInitPoyo(player) then return end

	_callScripts("PlayerUpdate", player)
end)

addHook("MobjThinker", function(mo)
	if not mo.valid then return end
	if not safeInitPoyo(mo.player) then return end

	_callScripts("PlayerMobjUpdate", mo.player)
end, MT_PLAYER)

addHook("JumpSpecial", function(player)
	if not safeInitPoyo(player) then return end

	return _callScripts("PlayerJump", player)
end)

addHook("SpinSpecial", function(player)
	if not safeInitPoyo(player) then return end

	return _callScripts("PlayerSpin", player)
end)

addHook("MobjMoveBlocked", function(mo, mobj, line)
	if not mo.valid then return end
	if not mo.player then return end
	if not safeInitPoyo(mo.player) then return end

	return _callScripts("PlayerBlocked", mo.player, mobj, line)
end, MT_PLAYER)

addHook("MobjDamage", function(mo, inflictor, source)
	if not mo.valid then return end
	if not mo.player then return end
	if not safeInitPoyo(mo.player) then return end

	return _callScripts("PlayerDamaged", mo.player, inflictor, source)
end, MT_PLAYER)

addHook("MobjDamage", function(target, inflictor, mo)
	if not mo then return end
	if not mo.valid then return end
	if not mo.player then return end
	if not safeInitPoyo(mo.player) then return end

	return _callScripts("PlayerDamage", mo.player, inflictor, target)
end)

addHook("MobjDeath", function(mo, inflictor, source)
	if not mo.valid then return end
	if not mo.player then return end
	if not safeInitPoyo(mo.player) then return end

	return _callScripts("PlayerDied", mo.player, inflictor, source)
end, MT_PLAYER)

addHook("MobjDeath", function(target, inflictor, mo)
	if not mo then return end
	if not mo.valid then return end
	if not mo.player then return end
	if not safeInitPoyo(mo.player) then return end

	return _callScripts("PlayerKilled", mo.player, inflictor, target)
end)

addHook("ShouldDamage", function(mo, inflictor, source)
	if not mo.valid then return end
	if not mo.player then return end
	if not safeInitPoyo(mo.player) then return end

	return _callScripts("PlayerShouldBeDamaged", mo.player, inflictor, source)
end, MT_PLAYER)

addHook("MobjDeath", function(target, inflictor, mo)
	if not mo then return end
	if not mo.valid then return end
	if not mo.player then return end
	if not safeInitPoyo(mo.player) then return end

	return _callScripts("PlayerShouldDamage", mo.player, inflictor, target)
end)