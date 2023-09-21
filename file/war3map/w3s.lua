-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Flags = require ('map.file.flags')

local W3S = {}

local unpack = string.unpack
local pack = string.pack

local is_format = {
	[1] = true,
	[2] = true,
	[3] = true
}

local flags = {
	[0x01] = 'looping',
	[0x02] = 'is_3d',
	[0x04] = 'stop_when_out_of_range',
	[0x08] = 'music',
	[0x10] = 'imported'
}

function W3S.unpack (input, position)
	local count
	local output = {}

	output.format, count,
	position = unpack ('< i4 i4', input, position)

	assert (is_format [output.format])

	for index = 1, count do
		local sound = {
			fade = {},
			distance = {},
			cone = {
				inside = {},
				outside = {},
				orientation = {}
			}
		}

		sound.name,
		sound.path,
		sound.effect,
		sound.flags,
		sound.fade.in_rate,
		sound.fade.out_rate,
		sound.volume,
		sound.pitch,
		sound.pitch_variance,
		sound.priority,
		sound.channel,
		sound.distance.minimum,
		sound.distance.maximum,
		sound.distance.cutoff,
		sound.cone.inside.angle,
		sound.cone.outside.angle,
		sound.cone.outside.volume,
		sound.cone.orientation.x,
		sound.cone.orientation.y,
		sound.cone.orientation.z,
		position = unpack (
			'< z z z i4 i4 i4 i4 f f i4 i4 f f f f f i4 f f f',
			input, position)

		sound.flags = Flags.unpack (flags, sound.flags)

		if output.format >= 2 then
			local name, path

			name, sound.label, path, sound.unknown_A,
			position = unpack (' < z z z c18', input, position)

			assert (name == sound.name)
			assert (path == sound.path)
		end

		if output.format >= 3 then
			sound.unknown_B,
			position = unpack ('< i4', input, position)
		end

		output [index] = sound
	end

	return output, position
end

function W3S.pack (input)
	assert (is_format [input.format])

	local output = {}
	output [#output + 1] = pack ('i4 i4', input.format, #input)

	for _, sound in ipairs (input) do
		output [#output + 1] = pack (
			'< z z z i4 i4 i4 i4 f f i4 i4 f f f f f i4 f f f',
			sound.name,
			sound.path,
			sound.effect,
			Flags.pack (flags, sound.flags),
			sound.fade.in_rate,
			sound.fade.out_rate,
			sound.volume,
			sound.pitch,
			sound.pitch_variance,
			sound.priority,
			sound.channel,
			sound.distance.minimum,
			sound.distance.maximum,
			sound.distance.cutoff,
			sound.cone.inside.angle,
			sound.cone.outside.angle,
			sound.cone.outside.volume,
			sound.cone.orientation.x,
			sound.cone.orientation.y,
			sound.cone.orientation.z)

		if input.format >= 2 then
			output [#output + 1] = pack (
				'z z z c18',
				sound.name,
				sound.label,
				sound.path,
				sound.unknown_A)
		end

		if input.format >= 3 then
			output [#output + 1] = pack ('< i4', sound.unknown_B)
		end
	end

	return table.concat (output)
end

return W3S
