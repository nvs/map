-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local W3C = {}

local unpack = string.unpack
local pack = string.pack

local is_format = {
	[0] = true
}

local unpackers = {
	-- Format for patch `< 1.31`.
	function (input, position)
		local count
		local output = {}

		output.format, count,
		position = unpack ('< i4 i4', input, position)

		assert (is_format [output.format])

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
			camera.name,
			position = unpack (
				'< f f f f f f f f f f z', input, position)

			output [index] = camera
		end

		return output, position
	end,

	-- Format for patch '>= 1.31`.
	function (input, position)
		local count
		local output = {}

		output.format, count,
		position = unpack ('< i4 i4', input, position)

		assert (is_format [output.format])

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
			camera.local_pitch,
			camera.local_yaw,
			camera.local_roll,
			camera.name,
			position = unpack (
				'< f f f f f f f f f f f f f z', input, position)

			output [index] = camera
		end

		return output, position
	end
}

function W3C.unpack (input, position)
	-- Attempt to use the older format first.  If the `input` is not fully
	-- consumed, then we assume we need to use the latest format.
	for _, unpacker in ipairs (unpackers) do
		local output, _position = unpacker (input, position)

		if _position > #input then
			return output, _position
		end
	end
end

function W3C.pack (input)
	assert (is_format [input.format])

	local output = {}
	output [#output + 1] = pack ('< i4 i4', input.format, #input)

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

		if camera.local_pitch then
			output [#output + 1] = pack (
				'< f f f',
				camera.local_pitch,
				camera.local_yaw,
				camera.local_roll)
		end

		output [#output + 1] = pack ('< z', camera.name)
	end

	return table.concat (output)
end

return W3C
