local PoyoPennynickel = PoyoPennynickel

local Class = {}
Class.__index = Class
registerMetatable(Class)

function Class.new(mo)
	local self = setmetatable({}, Class)

	self.mo = mo

	return self
end

PoyoPennynickel.Class = Class