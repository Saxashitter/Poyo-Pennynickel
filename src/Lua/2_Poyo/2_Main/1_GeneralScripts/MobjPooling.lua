-- this should solve poyos memory leak problem

local pool = {
	used = {},
	unused = {},
	orderOfAdditions = {}, -- for sync purposes
	additions = {} -- also for sync purposes
}

-- the idea is this
-- if we need an object, we try to get from the unused table and transfer that to the used table
-- if there is nothing from the unused table, construct a new mobj and put it in the used table
-- once were done with an object, it should get sent to the unused table and stay cached until we need to use it

local function SetUnusedObjectProperties(mo)
	mo.state = S_INVISIBLE
	mo.tics = -1
	mo.fuse = -1
	mo.flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOTHINK
	mo.radius = 0
	mo.height = 0
	
end

local function GetFromPool(x, y, z, objectType)
	if pool.additions[objectType] == nil then
		pool.additions[objectType] = true
		pool.orderOfAdditions[#pool.orderOfAdditions+1] = objectType
	end

	pool.used[objectType] = $ or {}
	pool.unused[objectType] = $ or {}

	local used = pool.used[objectType]
	local unused = pool.unused[objectType]
	local info = mobjinfo[objectType]
	local object

	print(#unused)

	if #unused then
		object = unused[#unused]
		unused[#unused] = nil

-- 		object.scale = FU
-- 		object.health = info.spawnhealth
-- 		object.radius = info.radius
-- 		object.height = info.height
-- 		object.health = info.spawnhealth
-- 		object.flags = info.flags
-- 		object.flags2 = 0
-- 		object.eflags = 0
-- 		object.alpha = FU
-- 		object.state = info.spawnstate
		print("drag from unused table")
	else
		object = P_SpawnMobj(0,0,0, objectType)
-- 		if object and object.valid then
-- 			SetUnusedObjectProperties(object) -- consistency
-- 		end
		print("new object")
	end

	used[#used+1] = object
	-- print(#used)

	if object and object.valid then
		P_SetOrigin(object, x,y,z)
		return object
	end
end

local function RemoveFromPool(object, i, objectType)
	if objectType == nil then
		if object and object.valid then
			objectType = object.type
		else
			return false
		end
	end


	pool.used[objectType] = $ or {}
	pool.unused[objectType] = $ or {}

	local used = pool.used[objectType]
	local unused = pool.unused[objectType]

	-- search table for key if not provided
	if i == nil then
		for k, v in ipairs(used) do
			if v == object then
				i = k
				break
			end
		end

		if i == nil then
			return false
		end
	end

	local len = #used
	used[i] = nil
	unused[#unused+1] = object

	-- properly put objects in order
	for i = i+1, len do
		used[i-1] = used[i]
		used[i] = nil
	end

	if object.valid then
		SetUnusedObjectProperties(object)
	end

	return true
end

addHook("NetVars", function(net)
	pool.used = net($)
	pool.unused = net($)
	pool.orderOfAdditions = net($)
	pool.additions = net($)
end)

-- basic testing
local tableKeys = {"used", "unused"}
addHook("ThinkFrame", function()
	for _, type in ipairs(pool.orderOfAdditions) do
		for _, key in ipairs(tableKeys) do
			if not pool[key][type] then
				continue
			end

			for i, object in ipairs(pool[key][type]) do
				if object and object.valid then continue end
				RemoveFromPool(object, i, type)
			end
		end
	end
end)

addHook("MapChange", function()
	-- nuke the WHOLE generation
	pool.used = {}
	pool.unused = {}
	pool.orderOfAdditions = {}
	pool.additions = {}
end)

-- expose functions. we only use locals here for optimizations
PoyoPennynickel.GetFromPool = GetFromPool
PoyoPennynickel.RemoveFromPool = RemoveFromPool