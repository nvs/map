-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local W3R = {}

local unpack = string.unpack
local pack = string.pack

function W3R.unpack (input)
	assert (type (input) == 'string')

	local format,
		count,
		position = unpack ('< i4 i4', input)

	assert (format == 5)

	local output = {
		format = format
	}

	for index = 1, count do
		local region = {
			minimum = {},
			maximum = {},
			color = {}
		}

		region.minimum.x,
		region.minimum.y,
		region.maximum.x,
		region.maximum.y,
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

	assert (#input == position - 1)

	return output
end

function W3R.pack (input)
	assert (type (input) == 'table')

	local output = {}
	local format = input.format or 5
	assert (format == 5)

	output [#output + 1] = pack ('i4 i4', format, #input)

	for _, region in ipairs (input) do
		output [#output + 1] = pack (
			'< f f f f z i4 c4 z B B B B',
			region.minimum.x,
			region.minimum.y,
			region.maximum.x,
			region.maximum.y,
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
