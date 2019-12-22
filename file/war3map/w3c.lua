-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local W3C = {}

local unpack = string.unpack
local pack = string.pack

function W3C.unpack (input, version)
	assert (type (input) == 'string')
	assert (type (version) == 'table')

	local format, count, position = unpack ('< i4 i4', input)
	assert (format == 0)

	local output = {
		format = format
	}

	for index = 1, count do
		local camera = {
			target = {}
		}

		camera.target.x,
		camera.target.y,
		camera.z_offset,
		camera.rotation,
		camera.angle_of_attack,
		camera.distance,
		camera.roll,
		camera.field_of_view,
		camera.far_z,
		camera.near_z,
		position = unpack (
			'< f f f f f f f f f f', input, position)

		if version.minor >= 31 then
			camera.local_pitch,
			camera.local_yaw,
			camera.local_roll,
			position = unpack ('< f f f', input, position)
		end

		camera.name,
		position = unpack ('z', input, position)

		output [index] = camera
	end

	assert (#input == position - 1)

	return output
end

function W3C.pack (input, version)
	assert (type (input) == 'table')
	assert (type (version) == 'table')

	local output = {}
	local format = input.format or 0
	assert (format == 0)

	output [#output + 1] = pack ('< i4 i4', format, #input)

	for _, camera in ipairs (input) do
		output [#output + 1] = pack (
			'< f f f f f f f f f f',
			camera.target.x,
			camera.target.y,
			camera.z_offset,
			camera.rotation,
			camera.angle_of_attack,
			camera.distance,
			camera.roll,
			camera.field_of_view,
			camera.far_z,
			camera.near_z)

		if version.minor >= 31 then
			output [#output + 1] = pack (
				'< f f f',
				camera.local_pitch,
				camera.local_yaw,
				camera.local_roll)
		end

		output [#output + 1] = pack ('z', camera.name)
	end

	return table.concat (output)
end

return W3C
