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

function W3S.unpack (input, version)
	local position

	local function unpack (options)
		local values = { string.unpack ('<' .. options, input, position) }
		position = values [#values]
		return table.unpack (values, 1, #values - 1)
	end

	local function unpack_flags (option)
		return Flags.unpack (flags, unpack (option))
	end

	local output = {
		version = unpack ('i4')
	}

	for index = 1, unpack ('i4') do
		local sound = {}

		sound.name = unpack ('z')
		sound.path = unpack ('z')
		sound.effect = unpack ('z')
		sound.flags = unpack_flags ('i4')
		sound.fade = {
			in_rate = unpack ('i4'),
			out_rate = unpack ('i4')
		}
		sound.volume = unpack ('i4')
		sound.pitch = unpack ('f')
		sound.unknown_A = unpack ('f')
		sound.unknown_B = unpack ('i4')
		sound.channel = unpack ('i4')
		sound.distance = {
			minimum = unpack ('f'),
			maximum = unpack ('f'),
			cutoff = unpack ('f')
		}
		sound.cone = {
			angles = {
				inside = unpack ('f'),
				outside = unpack ('f'),
			},
			volume = {
				outside = unpack ('i4')
			},
			orientation = {
				x = unpack ('f'),
				y = unpack ('f'),
				z = unpack ('f')
			}
		}

		if version.minor >= 32 then
			-- Seems to be used when generating the script.
			sound.script = {
				name = unpack ('z'),
				label = unpack ('z'),
				path = unpack ('z')
			}

			-- Rather than make assumptions, just lump it all together.
			sound.unknown_C = unpack ('c18')
		end

		output [index] = sound
	end

	assert (#input == position - 1)

	return output
end

function W3S.pack (input, version)
	assert (type (input) == 'table')
	assert (type (version) == 'table')

	local output = {}

	local function pack (options, ...)
		output [#output + 1] = string.pack ('<' .. options, ...)
	end

	local function pack_flags (option, value)
		pack (option, Flags.pack (flags, value))
	end

	pack ('i4', input.version or 1)
	pack ('i4', #input)

	for _, sound in ipairs (input) do
		pack ('z', sound.name)
		pack ('z', sound.path)
		pack ('z', sound.effect)
		pack_flags ('i4', sound.flags)
		pack ('i4', sound.fade.in_rate)
		pack ('i4', sound.fade.out_rate)
		pack ('i4', sound.volume)
		pack ('f', sound.pitch)
		pack ('f', sound.unknown_A)
		pack ('i4', sound.unknown_B)
		pack ('i4', sound.channel)
		pack ('f', sound.distance.minimum)
		pack ('f', sound.distance.maximum)
		pack ('f', sound.distance.cutoff)
		pack ('f', sound.cone.angles.inside)
		pack ('f', sound.cone.angles.outside)
		pack ('i4', sound.cone.volume.outside)
		pack ('f', sound.cone.orientation.x)
		pack ('f', sound.cone.orientation.y)
		pack ('f', sound.cone.orientation.z)

		if version.minor >= 32 then
			pack ('z', sound.script.name)
			pack ('z', sound.script.label)
			pack ('z', sound.script.path)
			pack ('c18', sound.unknown_C)
		end
	end

	return table.concat (output)
end

return W3S
