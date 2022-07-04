-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Flags = require ('map.file.flags')

local IMP = {}

local unpack = string.unpack
local pack = string.pack

local is_format = {
	[1] = true
}

local flags = {
	[0x01] = 'unknown_0x01',
	[0x02] = 'unknown_0x02',
	[0x04] = 'unknown_0x04',
	[0x08] = 'unknown_0x08',
	[0x10] = 'unknown_0x10',
}

function IMP.unpack (input, position)
	local count
	local output = {
		files = {}
	}

	output.format, count, position = unpack ('< i4 i4', input, position)
	assert (is_format [output.format])

	for _ = 1, count do
		local byte, name

		byte, name,
		position = unpack ('< B z', input, position)

		output.files [name] = Flags.unpack (flags, byte)
	end

	return output, position
end

function IMP.pack (input)
	assert (is_format [input.format])

	local output = {
		pack ('< i4 i4', input.format, #input.files)
	}
	local files = {}

	for name in pairs (input.files) do
		files [#files + 1] = name
	end

	table.sort (files)

	for _, name in ipairs (files) do
		output [#output + 1] = pack ('< B z',
			Flags.pack (flags, input.files [name]), name)
	end

	return table.concat (output)
end

return IMP
