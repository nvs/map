local Null = {}
Null.__index = Null

-- This is basically a black hole.  You write to it, and it stores nothing.
-- The purpose is to keep track of the amount of bytes written, and to
-- provide a seek interface.  Adheres to the API presented by Lua's [I/O]
-- library.
--
-- [I/O]: https://www.lua.org/manual/5.3/manual.html#6.8
function Null.open ()
	local self = {
		_size = 0,
		_position = 0
	}

	return setmetatable (self, Null)
end

local is_whence = {
	['set'] = true,
	['cur'] = true,
	['end'] = true
}

function Null:seek (whence, offset)
	whence = whence or 'cur'
	offset = offset or 0

	assert (is_whence [whence])
	assert (type (offset) == 'number')

	local position

	if whence == 'set' then
		position = offset
	elseif whence == 'cur' then
		position = self._position + offset
	elseif whence == 'end' then
		position = self._size + offset
	end

	if position < 0 then
		return nil
	elseif position > self._size then
		position = self._size
	end

	self._position = position

	return position
end

function Null:write (value)
	assert (type (value) == 'string'
		or type (value) == 'number')

	self._size = self._size + #tostring (value)

	return self
end

function Null.close ()
	return true
end

function Null.flush ()
	return true
end

function Null.lines ()
	return nil
end

function Null.read ()
	return nil
end

function Null.setvbuf ()
	return true
end

return Null
