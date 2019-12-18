-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

-- Deals with the `war3map.imp`.
local Imports = {}

function Imports.unpack (input)
	local position

	local function unpack (options)
		local values = { string.unpack ('<' .. options, input, position) }
		position = values [#values]
		return table.unpack (values, 1, #values - 1)
	end

	local output = {
		version = unpack ('i4'),
		files = {}
	}

	for _ = 1, unpack ('I4') do
		local byte = unpack ('b')
		output.files [unpack ('z')] = byte
	end

	assert (#input == position - 1)

	return output
end

function Imports.pack (input)
	assert (type (input) == 'table')

	local output = {}

	local function pack (options, ...)
		output [#output + 1] = string.pack ('<' .. options, ...)
	end

	local files = {}

	for name in pairs (input.files) do
		files [#files + 1] = name
	end

	table.sort (files)

	pack ('i4', input.version)
	pack ('I4', #files)

	for _, name in ipairs (files) do
		pack ('b', input.files [name])
		pack ('z', name)
	end

	return table.concat (output)
end

return Imports
