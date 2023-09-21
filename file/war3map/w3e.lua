-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local bit32 = require (jit and 'bit' or 'bit32') -- luacheck: globals jit

-- Credit to HiveWE for format and information:
-- - https://github.com/stijnherfst/HiveWE/wiki/war3map.w3e-Terrain
local W3E = {}

local unpack = string.unpack
local pack = string.pack
local floor = math.floor
local band = bit32.band

local is_format = {
	[11] = true
}

function W3E.unpack (input, position)
	local magic, count
	local output = {
		textures = {},
		offset = {}
	}

	magic, output.format,
	position = unpack ('< c4 i4', input, position)

	assert (magic == 'W3E!')
	assert (is_format [output.format])

	output.tileset, output.custom_tileset, count,
	position = unpack ('< c1 I4 I4', input, position)

	output.textures.ground = {
		unpack (('c4'):rep (count), input, position)
	}
	position = table.remove (output.textures.ground)

	count, position = unpack ('< I4', input, position)
	output.textures.cliff = { unpack (('c4'):rep (count), input, position) }
	position = table.remove (output.textures.cliff)

	local columns, rows

	columns, rows, output.offset.x, output.offset.y,
	position = unpack ('< I4 I4 f f', input, position)

	local tiles = {}
	output.tiles = tiles
	local format =  '<' .. ('I2 I2 I1 I1 I1'):rep (columns)

	for row = rows, 1, -1 do
		local line = {}
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

			line [column] = {
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
		end

		tiles [row] = line
	end

	return output, position
end

function W3E.pack (input)
	assert (is_format [input.format])

	local output = {}

	output [#output + 1] = pack (
		'< c4 I4 c1 I4', 'W3E!',
		input.format,
		input.tileset,
		input.custom_tileset)

	local count = #input.textures.ground
	output [#output + 1] = pack (
		'< I4' .. ('c4'):rep (count),
		count, table.unpack (input.textures.ground))

	count = #input.textures.cliff
	output [#output + 1] = pack (
		'< I4' .. ('c4'):rep (count),
		count, table.unpack (input.textures.cliff))

	local tiles = input.tiles
	local rows = #tiles
	local columns = #tiles [1]

	output [#output + 1] = pack (
		'< I4 I4 f f',
		columns,
		rows,
		input.offset.x,
		input.offset.y)

	for row = rows, 1, -1 do
		row = tiles [row]

		for column = 1, columns do
			local tile = row [column]
			local ground = tile.ground
			local water = tile.water
			local flags = tile.flags
			local cliff = tile.cliff

			output [#output + 1] = pack (
				'< I2 I2 I1 I1 I1',
				ground.height,
				water.height + (flags.edge and 0x4000 or 0),
				ground.texture
					+ (flags.ramp and 0x10 or 0)
					+ (flags.blight and 0x20 or 0)
					+ (flags.water and 0x40 or 0)
					+ (flags.boundary and 0x80 or 0),
				cliff.variation * 32 + ground.variation,
				cliff.texture * 16 + cliff.level)
		end
	end

	return table.concat (output)
end

return W3E
