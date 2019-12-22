-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local IMP = {}

local unpack = string.unpack
local pack = string.pack

function IMP.unpack (input)
	assert (type (input) == 'string')

	local format,
		count,
		position = unpack ('< i4 i4', input)

	assert (format == 1)

	local output = {
		format = format,
		files = {}
	}

	local byte, name

	for _ = 1, count do
		byte,
		name,
		position = unpack ('B z', input, position)

		output.files [name] = byte
	end

	assert (#input == position - 1)

	return output
end

function IMP.pack (input)
	assert (type (input) == 'table')

	local output = {}
	local format = input.format or 1
	assert (format == 1)

	local files = {}

	for name in pairs (input.files) do
		files [#files + 1] = name
	end

	table.sort (files)

	output [#output + 1] = pack ('i4 i4', format, #files)

	for _, name in ipairs (files) do
		output [#output + 1] = pack ('B z', input.files [name], name)
	end

	return table.concat (output)
end

return IMP
