-- original code by Aberranthian --
-- https://github.com/Aberranthian/Vector3-Lua-Module/tree/main --

local Vector3 = {}

local _ = {__index = Vector3};
registerMetatable(_)

-----------------------
----| Metamethods |----
-----------------------

function _.__add(a, b) return Vector3.new(a.x + b.x, a.y + b.y, a.z + b.z); end

function _.__sub(a, b) return Vector3.new(a.x - b.x, a.y - b.y, a.z - b.z); end

function _:__unm() return Vector3.new(-self.x, -self.y, -self.z); end

function _.__eq(a, b) if (a.x == b.x and a.y == b.y and a.z == b.z) then return true; else return false; end; end;

function _:__tostring() return ("Vector(x: %0.2f, y: %0.2f, z: %0.2f)"):format(self.x, self.y, self.z); end;

function _.__concat(a, b) return tostring(a)..tostring(b); end;

function _.__mul(a, b)
  if (type(b) == "number") then
	return Vector3.new(
		FixedMul(a.x, b),
		FixedMul(a.y, b),
		FixedMul(a.z, b)
	);
  end

  return Vector3.new(
	  FixedMul(a.x, b.x),
	  FixedMul(a.y, b.y),
	  FixedMul(a.z, b.z)
  );
end

function _.__div(a, b) -- Unsure if useful but kept just in case.
  if (type(b) == "number") then
	if (b == 0) then print("Attempted to divide by zero. Returning nil"); return nil; end

	return Vector3.new(
		FixedDiv(a.x, b),
		FixedDiv(a.y, b),
		FixedDiv(a.z, b)
	);
  end

  if (b.x == 0 or b.y == 0 or b.z == 0) then print("Attempted to divide by zero. Returning nil."); return nil; end

  return Vector3.new(
	  FixedDiv(a.x, b.x),
	  FixedDiv(a.y, b.y),
	  FixedDiv(a.z, b.z)
  );
end

---------------------------
----| Vector3 Methods |----
---------------------------

function Vector3.new(x, y, z)
	return setmetatable({
	  x = x or 0,
	  y = y or 0,
	  z = z or 0
	}, _);
end

function Vector3.lerp(start, finish, ratio)
	return Vector3.new(
		FixedMul(start.x + (finish.x - start.x), ratio),
		FixedMul(start.y + (finish.y - start.y), ratio),
		FixedMul(start.z + (finish.z - start.z), ratio)
	);
end

function Vector3:distance(other)
	return R_PointToDist2(0, self.z, R_PointToDist2(self.x, self.y, other.x, other.y), other.z)
	-- return math.sqrt((self.x - other.x)^2 + (self.y - other.y)^2 + (self.z - other.z)^2);
end

function Vector3:magnitude()
	return R_PointToDist2(0, 0, R_PointToDist2(0, 0, self.x, self.y), self.z)
	-- return math.sqrt(self.x^2 + self.y^2 + self.z^2);
end

function Vector3:normalized()
	local magnitude = self:magnitude();

	if (magnitude == 0) then return Vector3.new(); end

	return Vector3.new(
		FixedDiv(self.x, magnitude),
		FixedDiv(self.y, magnitude),
		FixedDiv(self.z, magnitude)
	);
end

function Vector3:dot(other)
	return (FixedMul(self.x, other.x) + FixedMul(self.y, other.y) + FixedMul(self.z, other.z));
end

function Vector3:cross(other)
	local result = Vector3.new(
		FixedMul(self.y, other.z) - FixedMul(self.z, other.y),
		FixedMul(self.z, other.x) - FixedMul(self.x, other.z),
		FixedMul(self.x, other.y) - FixedMul(self.y, other.x)
	);

	-- Doing some workarounds to avoid '-0' in Lua.
	if (result.x == 0) then result.x = 0; end
	if (result.y == 0) then result.y = 0; end
	if (result.z == 0) then result.z = 0; end

	return result;
end

function Vector3:abs()
    return Vector3.new(
        abs(self.x),
        abs(self.y),
        abs(self.z)
    )
end

function Vector3:angle(other)
	local horz = R_PointToAngle2(self.x, self.y, other.x, other.y)
	local vert = R_PointToAngle2(0, self.z, R_PointToDist2(self.x, self.y, other.x, other.y), other.z)

	return horz, vert
end

function Vector3:direction(other)
	local offset = other - self
	return offset:normalized()
end

function Vector3.fromMobj(mo, centered)
	if centered then
		return Vector3.new(mo.x, mo.y, mo.z + mo.height / 2)
	end

	return Vector3.new(mo.x, mo.y, mo.z)
end

function Vector3.fromMobjMom(mo)
	return Vector3.new(mo.momx, mo.momy, mo.momz)
end

function Vector3.fromAngle(angle, aiming)
	return Vector3.new(
		FixedMul(cos(angle), cos(aiming)),
		FixedMul(sin(angle), cos(aiming)),
		sin(aiming)
	)
end

function Vector3:setMobj(mo, interpolation)
	if not interpolation then
		P_SetOrigin(mo, self.x, self.y, self.z)
		return mo
	end

	P_MoveOrigin(mo, self.x, self.y, self.z)
	return mo
end

function Vector3:setMobjMom(mo, relative)
	if relative then
		mo.momx = $ + self.x
		mo.momy = $ + self.y
		mo.momz = $ + self.z
		return mo
	end

    mo.momx = self.x
    mo.momy = self.y
    mo.momz = self.z

	return mo
end

function Vector3:tostring()
	return tostring(self);
end

---- Vector3 Fields ----
Vector3.zero    = Vector3.new(0, 0, 0);
Vector3.up      = Vector3.new(0, 0, FU);
Vector3.down    = Vector3.new(0, 0, -FU);
Vector3.left    = Vector3.new(-FU, 0, 0);
Vector3.right   = Vector3.new(FU, 0, 0);
Vector3.forward = Vector3.new(0, FU, 0);
Vector3.back    = Vector3.new(0, -FU, 0);

-- return Vector3;
rawset(_G, "Vector3", Vector3)