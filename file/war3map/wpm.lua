-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local WPM = {}

function WPM.unpack (input)
	assert (type (input) == 'string')

	local magic,
		format,
		columns,
		rows,
		position = string.unpack ('< c4 I4 I4 I4', input)

	assert (magic == 'MP3W')
	assert (format == 0)

	local output = {
		format = format,
	}

	local cells = {}
	output.cells = cells
	local byte = string.byte

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

	return output
end

function WPM.pack (input)
	assert (type (input) == 'table')

	local output = {}
	local format = input.format or 0
	assert (format == 0)

	local cells = input.cells
	local rows = #cells
	local columns = #cells [1]

	output [#output + 1] = string.pack (
		'< c4 I4 I4 I4',
		'MP3W',
		format,
		columns,
		rows)

	local char = string.char
	local unpack = table.unpack

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
