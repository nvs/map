local IO = require ('map.io')
local Null = require ('map.io.null')

-- Deals with the `war3map.imp`.
local Imports = {}

function Imports.unpack (io)
	if not io then
		return nil
	end

	local function unpack (options)
		return assert (IO.unpack (io, '<' .. options))
	end

	assert (io:seek ('set'))

	local output = {
		version = unpack ('i4'),
		files = {}
	}

	for _ = 1, unpack ('I4') do
		local byte = unpack ('b')
		output.files [unpack ('z')] = byte
	end

	return output
end

function Imports.pack (io, input)
	assert (type (input) == 'table')

	if not io then
		return nil
	end

	local function pack (options, ...)
		assert (IO.pack (io, '<' .. options, ...))
	end

	assert (io:seek ('set'))

	local files = {}

	for name in pairs (input.files) do
		files [#files + 1] = name
	end

	table.sort (files)

	pack ('i4', input.version)
	pack ('I4', #files)

	for _, name in ipairs (files) do
		local byte = input.files [name]

		if type (byte) ~= 'number' then
			byte = 0x1D
		end

		pack ('b', byte)
		pack ('z', name)
	end

	return true
end

function Imports.packsize (input)
	assert (type (input) == 'table')

	local io = Null.open ()

	if not Imports.pack (io, input) then
		return nil
	end

	return io:seek ('end')
end

return Imports
