-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local bit32 = require (jit and 'bit' or 'bit32') -- luacheck: globals jit

-- Credit to HiveWE for format and information:
-- - https://github.com/stijnherfst/HiveWE/wiki/war3map.w3e-Terrain
local W3E = {}

function W3E.unpack (input)
	assert (type (input) == 'string')

	local position

	local function unpack (options)
		local values = { string.unpack ('<' .. options, input, position) }
		position = values [#values]
		return table.unpack (values, 1, #values - 1)
	end

	local magic = unpack ('c4')
	assert (magic == 'W3E!')

	local output = {}
	output.format = unpack ('I4')
	assert (output.format == 11)

	output.tileset = unpack ('c1')
	output.custom_tileset = unpack ('I4') == 1
	output.textures = {
		ground = { unpack (('c4'):rep (unpack ('I4'))) },
		cliff = { unpack (('c4'):rep (unpack ('I4'))) }
	}

	local columns = unpack ('I4')
	local rows = unpack ('I4')

	output.offset = {
		x = unpack ('f'),
		y = unpack ('f')
	}

	local tiles = {}
	output.tiles = tiles

	unpack = string.unpack
	local floor = math.floor
	local band = bit32.band
	local format =  '<' .. ('I2I2I1I1I1'):rep (columns)

	for row = rows, 1, -1 do
		tiles [row] = {}

		local temp = { unpack (format, input, position) }
		position = temp [#temp]

		for column = 1, columns do
			local index = (column - 1) * 5 + 1
			-- A: Ground height.
			-- B: Water height and edge flag.
			-- C: Ground texture and flags.
			-- D: Variations.
			-- E: Cliff texture and layers.
			local A = temp [index]
			local B = temp [index + 1]
			local C = temp [index + 2]
			local D = temp [index + 3]
			local E = temp [index + 4]

			local tile = {
				flags = {
					edge = B % (0x4000 + 0x4000) >= 0x4000,
					ramp = C % (0x10 + 0x10) >= 0x10,
					blight = C % (0x20 + 0x20) >= 0x20,
					water = C % (0x40 + 0x40) >= 0x40,
					boundary = C % (0x80 + 0x80) >= 0x80,
				},
				ground = {
					height = A,
					texture = C % 0x10,
					variation = D % 0x20
				},
				cliff = {
					level = E % 0x10,
					texture = floor (band (E, 0xF0) / 16),
					variation = floor (band (D, 0xE0) / 32)
				},
				water = {
					height = B % 0x4000
				},
			}

			tiles [row] [column] = tile
		end
	end

	assert (#input == position - 1)

	return output
end

function W3E.pack (input)
	assert (type (input) == 'table')

	local output = {}

	local function pack (options, ...)
		output [#output + 1] = string.pack ('<' .. options, ...)
	end

	assert (input.format == 11)

	pack ('c4', 'W3E!')
	pack ('I4', input.format)
	pack ('c1', input.tileset)
	pack ('I4', input.custom_tileset and 1 or 0)

	do
		local count = #input.textures.ground
		pack ('I4', count)
		pack (('c4'):rep (count), table.unpack (input.textures.ground))
	end

	do
		local count = #input.textures.cliff
		pack ('I4', count)
		pack (('c4'):rep (count), table.unpack (input.textures.cliff))
	end

	pack ('I4', #input.tiles [1])
	pack ('I4', #input.tiles)
	pack ('f', input.offset.x)
	pack ('f', input.offset.y)

	pack = string.pack

	for row = #input.tiles, 1, -1 do
		for _, tile in ipairs (input.tiles [row]) do
			output [#output + 1] = pack ('<I2I2I1I1I1',
				tile.ground.height,
				tile.water.height
					+ (tile.flags.edge and 0x4000 or 0),
				tile.ground.texture
					+ (tile.flags.ramp and 0x10 or 0)
					+ (tile.flags.blight and 0x20 or 0)
					+ (tile.flags.water and 0x40 or 0)
					+ (tile.flags.boundary and 0x80 or 0),
				tile.cliff.variation * 32
					+ tile.ground.variation,
				tile.cliff.texture * 16
					+ tile.cliff.level)
		end
	end

	return table.concat (output)
end

return W3E
