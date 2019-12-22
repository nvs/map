-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Flags = require ('map.file.flags')

local W3S = {}

local flags = {
	[0x01] = 'looping',
	[0x02] = 'is_3d',
	[0x04] = 'stop_when_out_of_range',
	[0x08] = 'music'
}

local unpack = string.unpack
local pack = string.pack

function W3S.unpack (input)
	assert (type (input) == 'string')

	local format,
		count,
		position = unpack ('< i4 i4', input)

	assert (format == 1 or format == 2)

	local output = {
		format = format
	}

	for index = 1, count do
		local sound = {
			fade = {},
			distance = {},
			cone = {
				angles = {},
				volume = {},
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
		sound.unknown_A,
		sound.unknown_B,
		sound.channel,
		sound.distance.minimum,
		sound.distance.maximum,
		sound.distance.cutoff,
		sound.cone.angles.inside,
		sound.cone.angles.outside,
		sound.cone.volume.outside,
		sound.cone.orientation.x,
		sound.cone.orientation.y,
		sound.cone.orientation.z,
		position = unpack (
			'< z z z i4 i4 i4 i4 f f i4 i4 f f f f f i4 f f f',
			input, position)

		sound.flags = Flags.unpack (flags, sound.flags)

		if format == 2 then
			sound.script = {}

			sound.script.name,
			sound.script.label,
			sound.script.path,
			sound.unknown_C,
			position = unpack ('z z z c18', input, position)
		end

		output [index] = sound
	end

	assert (#input == position - 1)

	return output
end

function W3S.pack (input)
	assert (type (input) == 'table')

	local output = {}
	local format = input.format or 2
	assert (format == 1 or format == 2)

	output [#output + 1] = pack ('i4 i4', format, #input)

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
			sound.unknown_A,
			sound.unknown_B,
			sound.channel,
			sound.distance.minimum,
			sound.distance.maximum,
			sound.distance.cutoff,
			sound.cone.angles.inside,
			sound.cone.angles.outside,
			sound.cone.volume.outside,
			sound.cone.orientation.x,
			sound.cone.orientation.y,
			sound.cone.orientation.z)

		if format == 2 then
			output [#output + 1] = pack (
				'z z z c18',
				sound.script.name,
				sound.script.label,
				sound.script.path,
				sound.unknown_C)
		end
	end

	return table.concat (output)
end

return W3S
