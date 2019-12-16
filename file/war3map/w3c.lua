-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local W3C = {}

function W3C.unpack (input, version)
	assert (type (input) == 'string')
	assert (type (version) == 'table')

	local position

	local function unpack (options)
		local values = { string.unpack ('<' .. options, input, position) }
		position = values [#values]
		return table.unpack (values, 1, #values - 1)
	end

	local output = {
		version = unpack ('i4')
	}

	for index = 1, unpack ('i4') do
		local camera = {
			target = {
				x = unpack ('f'),
				y = unpack ('f')
			},
			z_offset = unpack ('f'),
			rotation = unpack ('f'),
			angle_of_attack = unpack ('f'),
			distance = unpack ('f'),
			roll = unpack ('f'),
			field_of_view = unpack ('f'),
			far_z = unpack ('f'),
			near_z = unpack ('f')
		}

		if version.minor >= 31 then
			camera.local_pitch = unpack ('f')
			camera.local_yaw = unpack ('f')
			camera.local_roll = unpack ('f')
		end

		camera.name = unpack ('z')

		output [index] = camera
	end

	assert (#input == position - 1)

	return output
end

function W3C.pack (input, version)
	assert (type (input) == 'table')

	if version then
		assert (type (version) == 'table')
	end

	local output = {}

	local function pack (options, ...)
		output [#output + 1] = string.pack ('<' .. options, ...)
	end

	pack ('i4', input.version or 0)
	pack ('i4', #input)

	for _, camera in ipairs (input) do
		pack ('f', camera.target.x)
		pack ('f', camera.target.y)
		pack ('f', camera.z_offset)
		pack ('f', camera.rotation)
		pack ('f', camera.angle_of_attack)
		pack ('f', camera.distance)
		pack ('f', camera.roll)
		pack ('f', camera.field_of_view)
		pack ('f', camera.far_z)
		pack ('f', camera.near_z)

		if version and version.major >= 1 and version.minor >= 31 then
			pack ('f', camera.local_pitch)
			pack ('f', camera.local_yaw)
			pack ('f', camera.local_roll)
		end

		pack ('z', camera.name)
	end

	return table.concat (output)
end

return W3C
