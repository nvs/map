local IO = require ('map.io')
local Null = require ('map.io.null')

-- The W3O is a collection of object files.
local files = {
	'w3u',
	'w3t',
	'w3b',
	'w3d',
	'w3a',
	'w3h',
	'w3q'
}

local objects = {}

for _, file in ipairs (files) do
	objects [file] = require ('map.file.war3map.' .. file)
end

local W3O = {}

function W3O.unpack (io)
	if not io then
		return nil
	end

	local function unpack (options)
		return assert (IO.unpack (io, '<' .. options))
	end

	assert (io:seek ('set'))

	local output = {}

	-- Version.
	unpack ('i4')

	-- Files.
	for _, file in ipairs (files) do
		if unpack ('i4') == 1 then
			output [file] = objects [file].unpack (io)
		end
	end

	return output
end

function W3O.pack (io, input)
	assert (type (input) == 'table')

	if not io then
		return nil
	end

	local function pack (options, ...)
		assert (IO.pack (io, '<' .. options, ...))
	end

	assert (io:seek ('set'))

	-- Version.
	pack ('i4', 1)

	-- Files.
	for _, file in ipairs (files) do
		if input [file] and type (input [file]) == 'table' then
			pack ('i4', 1)
			objects [file].pack (io, input [file])
		else
			pack ('i4', 0)
		end
	end

	return true
end

function W3O.packsize (input)
	assert (type (input) == 'table')

	local io = Null.open ()

	if not W3O.pack (io, input) then
		return nil
	end

	return io:seek ('end')
end

return W3O
