-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local W3R = {}

local unpack = string.unpack
local pack = string.pack

local is_format = {
	[5] = true
}

function W3R.unpack (input, position)
	local count
	local output = {}

	output.format, count,
	position = unpack ('< i4 i4', input, position)

	assert (is_format [output.format])

	for index = 1, count do
		local region = {
			x = {},
			y = {},
			color = {}
		}

		region.x.minimum,
		region.y.minimum,
		region.x.maximum,
		region.y.maximum,
		region.name,
		region.id,
		region.weather,
		region.sound,
		region.color.blue,
		region.color.green,
		region.color.red,
		region.color.alpha,
		position = unpack (
			'< f f f f z i4 c4 z B B B B', input, position)

		output [index] = region
	end

	return output, position
end

function W3R.pack (input)
	assert (is_format [input.format])

	local output = {}
	output [#output + 1] = pack ('i4 i4', input.format, #input)

	for _, region in ipairs (input) do
		output [#output + 1] = pack (
			'< f f f f z i4 c4 z B B B B',
			region.x.minimum,
			region.y.minimum,
			region.x.maximum,
			region.y.maximum,
			region.name,
			region.id,
			region.weather,
			region.sound,
			region.color.blue,
			region.color.green,
			region.color.red,
			region.color.alpha)
	end

	return table.concat (output)
end

return W3R
