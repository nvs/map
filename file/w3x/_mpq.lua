local Path = require ('map.path')
local Storm = require ('stormlib')

-- Wrapper for a MPQ object provided by [lua-stormlib], primarily focused on
-- providing W3X compatibility.
--
-- [lua-stormlib]: https://github.com/nvs/lua-stormlib
local MPQ = {}
MPQ.__index = MPQ

function MPQ.new (path, mode)
	local mpq, message, code = Storm.open (path, mode)

	if not mpq then
		return nil, message, code
	end

	local self = {
		_mpq = mpq
	}

	return setmetatable (self, MPQ)
end

local function to_internal (name)
	return (name:gsub ('[\\/]+', '\\'))
end

local function to_external (name)
	return (name:gsub ('[\\/]+', Path.separator))
end

function MPQ:has (name)
	return self._mpq:has (to_internal (name))
end

function MPQ:list (mask)
	local iterator = self._mpq:list (mask and to_internal (mask))

	return function ()
		local name = iterator ()

		if name then
			return to_external (name)
		end
	end
end

function MPQ:open (name, mode, size)
	return self._mpq:open (to_internal (name), mode, size)
end

function MPQ:add (path, name)
	return self._mpq:add (path, to_internal (name))
end

function MPQ:extract (name, path)
	return self._mpq:extract (to_internal (name), path)
end

function MPQ:rename (old, new)
	return self._mpq:rename (to_internal (old), to_internal (new))
end

function MPQ:remove (name)
	return self._mpq:remove (to_internal (name))
end

function MPQ:compact ()
	return self._mpq:compact ()
end

function MPQ:close ()
	return self._mpq:close ()
end

return MPQ
