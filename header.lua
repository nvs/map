local Header = {}

-- Reads the header of the specified `map (string)`, returning a `table` with
-- the following structure.
--
-- ```
-- {
--     name = 'The name of map'
-- }
-- ```
--
-- If an error is encountered, `nil` is returned.
function Header.read (map)
	local file = io.open (map, 'rb')

	if not file then
		return nil
	end

	file:seek ('set', 8)

	local buffer = {}

	repeat
		local byte = file:read (1)
		table.insert (buffer, byte)
	until byte == '\0'

	file:close ()

	local header = {}
	header.name = table.concat (buffer)

	return header
end

-- Updates the `header (table)` for the provided `map (string)`. Returns `true
-- (boolean)` upon success, and `nil` if an error is encountered.
function Header.write (map, header)
	if type (header) ~= 'table' then
		return nil
	end

	local name = header.name:sub (1, 495) .. '\0'

	local file = io.open (map, 'r+b')

	if not file then
		return nil
	end

	file:seek ('set', 8)

	-- Skip the name, which is null-terminated.
	repeat until file:read (1) == '\0'

	local old = file:seek ()
	local flags_and_players = file:read (8)

	file:seek ('set', 8)
	file:write (name)
	local new = file:seek ()
	file:write (flags_and_players)

	-- If the old name is larger than the new one, we need to pad zeroes.
	if old > new then
		file:write (string.rep ('\0', old - new))
	end

	file:close ()

	return true
end

return Header
