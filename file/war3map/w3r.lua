-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local W3R = {}

function W3R.unpack (input)
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
		local region = {
			minimum = {
				x = unpack ('f'),
				y = unpack ('f')
			},
			maximum = {
				x = unpack ('f'),
				y = unpack ('f')
			},
			name = unpack ('z'),
			id = unpack ('i4'),
			weather = unpack ('c4'),
			sound = unpack ('z'),
			color = {
				blue = unpack ('B'),
				green = unpack ('B'),
				red = unpack ('B'),
				alpha = unpack ('B')
			}
		}

		output [index] = region
	end

	assert (#input == position - 1)

	return output
end

function W3R.pack (input)
	assert (type (input) == 'table')

	local output = {}

	local function pack (options, ...)
		output [#output + 1] = string.pack ('<' .. options, ...)
	end

	pack ('i4', input.version or 5)
	pack ('i4', #input)

	for _, region in ipairs (input) do
		pack ('f', region.minimum.x)
		pack ('f', region.minimum.y)
		pack ('f', region.maximum.x)
		pack ('f', region.maximum.y)
		pack ('z', region.name)
		pack ('i4', region.id)
		pack ('c4', region.weather)
		pack ('z', region.sound)
		pack ('B', region.color.blue)
		pack ('B', region.color.green)
		pack ('B', region.color.red)
		pack ('B', region.color.alpha)
	end

	return table.concat (output)
end

return W3R
