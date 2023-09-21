-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local WPM = {}

local is_format = {
	[0] = true
}

function WPM.unpack (input, position)
	local unpack = string.unpack
	local byte = string.byte

	local magic, columns, rows
	local output = {}

	magic, output.format, columns, rows,
	position = unpack ('< c4 i4 i4 i4', input, position)

	assert (magic == 'MP3W')
	assert (is_format [output.format])

	local cells = {}
	output.cells = cells

	for row = rows, 1, -1 do
		local next = position + columns
		local bytes = { byte (input, position, next - 1) }
		position = next
		local line = {}

		for column = 1, columns do
			local value = bytes [column]

			line [column] = {
				walkable = value % (0x02 + 0x02) < 0x02,
				flyable = value % (0x04 + 0x04) < 0x04,
				buildable = value % (0x08 + 0x08) < 0x08,
				blight = value % (0x20 + 0x20) >= 0x20,
				water = value % (0x40 + 0x40) < 0x40,
				amphibious = value % (0x80 + 0x80) < 0x80,
			}
		end

		cells [row] = line
	end

	return output, position
end

function WPM.pack (input)
	assert (is_format [input.format])

	local pack = string.pack
	local char = string.char
	local unpack = table.unpack

	local output = {}
	local cells = input.cells
	local rows = #cells
	local columns = #cells [1]

	output [#output + 1] = pack (
		'< c4 I4 I4 I4',
		'MP3W',
		input.format,
		columns,
		rows)

	for row = rows, 1, -1 do
		row = cells [row]
		local bytes = {}

		for column = 1, columns do
			local cell = row [column]

			bytes [column] = 0
				+ (cell.walkable and 0 or 0x02)
				+ (cell.flyable and 0 or 0x04)
				+ (cell.buildable and 0 or 0x08)
				+ (cell.blight and 0x20 or 0)
				+ (cell.water and 0 or 0x40)
				+ (cell.amphibious and 0 or 0x80)
		end

		output [#output + 1] = char (unpack (bytes))
	end

	return table.concat (output)
end

return WPM
