-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Objects = require ('map.file.objects')

local W3O = {}

local unpack = string.unpack
local pack = string.pack

local is_format = {
	[1] = true
}

local objects = {
	{
		file = 'w3u',
		has_variations = false,
		is_file = false
	},
	{
		file = 'w3t',
		has_variations = false,
		is_file = false
	},
	{
		file = 'w3b',
		has_variations = false,
		is_file = false
	},
	{
		file = 'w3d',
		has_variations = true,
		is_file = false
	},
	{
		file = 'w3a',
		has_variations = true,
		is_file = false
	},
	{
		file = 'w3h',
		has_variations = false,
		is_file = false
	},
	{
		file = 'w3q',
		has_variations = true,
		is_file = true
	}
}

function W3O.unpack (input, position)
	local library
	local output = {}

	output.format, position = unpack ('< i4', input, position)
	assert (is_format [output.format])

	for _, object in ipairs (objects) do
		library, position = unpack ('< i4', input, position)

		if library == 1 then
			output [object.file],
			position = Objects.unpack (input, position, object)
		end
	end

	return output, position
end

function W3O.pack (input)
	assert (is_format [input.format])

	local output = {
		pack ('< i4', input.format)
	}

	for _, object in ipairs (objects) do
		local file = object.file
		output [#output + 1] = pack ('< i4', input [file] and 1 or 0)

		if input [file] then
			output [#output + 1] = Objects.pack (input [file], object)
		end
	end

	return table.concat (output)
end

return W3O
