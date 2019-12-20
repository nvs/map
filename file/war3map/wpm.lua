-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local WPM = {}

function WPM.unpack (input)
	assert (type (input) == 'string')

	local magic, format, columns, rows, position =
		string.unpack ('<c4I4I4I4', input)

	assert (magic == 'MP3W')
	assert (format == 0)

	local output = {
		format = format,
	}

	local cells = {}
	output.cells = cells

	for row = rows, 1, -1 do
		local line = {}
		cells [row] = line

		for column = 1, columns do
			local value = input:byte (position)
			position = position + 1

			line [column] = {
				walkable = value % (0x02 + 0x02) < 0x02,
				flyable = value % (0x04 + 0x04) < 0x04,
				buildable = value % (0x08 + 0x08) < 0x08,
				blight = value % (0x20 + 0x20) >= 0x20,
				water = value % (0x40 + 0x40) < 0x40,
				amphibious = value % (0x80 + 0x80) < 0x80,
			}
		end
	end

	return output
end

-- Set this to the default value in Lua 5.1 and LuaJIT, as it is smaller
-- there.  Given that this compile time option could be adjusted, it is
-- possible, but probably rare, for this to be too large and fail.
--
-- The alternative method, which gets the character for each cell at the
-- time bits are added together, incurs a `50%` performance penalty, but
-- uses roughly `15%` less memory.
local C_STACK_SIZE = 8000

function WPM.pack (input)
	assert (type (input) == 'table')
	assert (input.format == 0)

	local output = {}

	output [#output + 1] = string.pack ('<c4I4I4I4',
		'MP3W', input.format, #input.cells [1], #input.cells)

	local index = 0
	local bytes = {}

	for row = #input.cells, 1, -1 do
		row = input.cells [row]

		for _, cell in ipairs (row) do
			index = index + 1
			bytes [index] = 0
				+ (cell.walkable and 0 or 0x02)
				+ (cell.flyable and 0 or 0x04)
				+ (cell.buildable and 0 or 0x08)
				+ (cell.blight and 0x20 or 0)
				+ (cell.water and 0 or 0x40)
				+ (cell.amphibious and 0 or 0x80)
		end
	end

	index = 1
	local size = #bytes
	repeat
		-- Subtract the two arguments that preceed the unpacked bytes on the
		-- C stack: the function call and the format string.
		local next = index + C_STACK_SIZE - 3

		if next >= size then
			next = size + 1
		end

		output [#output + 1] = string.pack (
			('I1'):rep (next - index),
			table.unpack (bytes, index, next - 1))
		index = next
	until index > size

	return table.concat (output)
end

return WPM
