local Header = {}

-- Reads the header of the specified `map (string)`, returning a `table`
-- with the following structure.
--
-- ```
-- {
--     name = 'The name of map'
-- }
-- ```
--
-- If an error is encountered, `nil` is returned.
function Header.read (map, block, input)
	local file = io.open (map, 'rb')

	if not file then
		return nil
	end

	-- A simple wrapper for `file.read ()`, passing the resultant text and
	-- replacement `value (string)` to `block (function)`.
	local function read (format, value)
		local text = file:read (format)

		if block then
			block (text, value)
		end

		return text
	end

	-- The replacement `value (string)` is not null-terminated (or, at least,
	-- it shouldn't be).
	local function read_string (value)
		local buffer = {}

		-- Strings are null-terminated.
		repeat
			local byte = file:read (1)
			table.insert (buffer, byte)
		until byte == '\0'

		buffer = table.concat (buffer)

		if block then
			block (buffer, value and value .. '\0')
		end

		-- Ignore the null character.
		return buffer:sub (1, -2)
	end

	local output = {}

	-- (char 4) 'HM3W':
	read (4)

	-- (int) Unknown:
	read (4)

	-- (string) Map name:
	output.name = read_string (input and input.name)

	-- (int) Flags:
	-- - 0x0001: 1 = Hide minimap in preview screens
	-- - 0x0002: 1 = Modify ally priorities
	-- - 0x0004: 1 = Melee map
	-- - 0x0008: 1 = Playable map size was large and has never been
	--               reduced to medium (?)
	-- - 0x0010: 1 = Masked area are partially visible
	-- - 0x0020: 1 = Fixed player setting for custom forces
	-- - 0x0040: 1 = Use custom forces
	-- - 0x0080: 1 = Use custom techtree
	-- - 0x0100: 1 = Use custom abilities
	-- - 0x0200: 1 = Use custom upgrades
	-- - 0x0400: 1 = Map properties menu opened at least once
	--               since map creation (?)
	-- - 0x0800: 1 = Show water waves on cliff shores
	-- - 0x1000: 1 = Show water waves on rolling shores
	read (4)

	-- (int) Maximum number of players:
	read (4)

	file:close ()

	return output
end

-- Updates the `header (table)` for the provided `map (string)`. Returns
-- `true (boolean)` upon success, and `nil` if an error is encountered.
function Header.write (header, map)
	local contents = {}

	local block = function (existing, replacement)
		table.insert (contents, replacement and replacement or existing)
	end

	if not Header.read (map, block, header) then
		return nil
	end

	contents = table.concat (contents)

	if #contents > 512 then
		return nil
	end

	local file = io.open (map, 'r+b')

	if not file then
		return nil
	end

	file:write (contents, string.rep ('\0', 512 - #contents))
	file:close ()

	return true
end

return Header
