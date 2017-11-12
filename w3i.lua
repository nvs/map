local Grimex = require ('map.tools.grimex')
local MPQEditor = require ('map.tools.mpqeditor')
local Path = require ('map.path')

local W3I = {}

-- Reads the 'war3map.w3i' from the specified `map (string)`, returning a
-- `table` with the following structure. Uses the provided `directory
-- (string)` for temporary files. If provided, the `prefix (string)` will be
-- prepended to the command line.
--
-- ```
-- {
--     name = '',
--     author = '',
--     description = '',
--
--     loading_screen = {
--         text = '',
--         title = '',
--         subtitle = ''
--     },
--
--     players = {
--         [1] = {
--             name = ''
--         }
--     },
--
--     forces = {
--         [1] = {
--             name = ''
--         }
--     }
-- }
-- ```
--
-- If an error is encountered, `nil` is returned.
function W3I.read (map, directory, prefix, block, input)
	local file_path = MPQEditor.export (map, 'war3map.w3i', directory, prefix)

	if not file_path then
		return nil
	end

	local file = io.open (file_path, 'rb')

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

	-- TODO: Transform integer into byte representation
	--
	-- The integer `value (number)` must be transformed into its four-byte
	-- representation, otherwise, this won't work as intended for writing.
	local function read_integer (value)
		local bytes = { read (4, value):byte (1, -1) }
		local integer = 0

		-- Little-endian.
		for index, byte in ipairs (bytes) do
			integer = integer + byte * 2 ^ (8 * (index - 1))
		end

		return integer
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

	-- (int) File format:
	-- - 18 = RoC
	-- - 25 = TFT
	local is_tft = read_integer () == 25

	-- (int) Number of saves:
	read (4)

	-- (int) Editor version:
	read (4)

	-- (string) Map name:
	output.name = read_string (input and input.name)

	-- (string) Map author:
	output.author = read_string (input and input.author)

	-- (string) Map description:
	output.description = read_string (input and input.description)

	-- (string) Player recommended:
	read_string ()

	-- (float [8]) Camera bounds:
	read (4 * 8)

	-- Map dimensions:
	-- - Width = A + E + B
	-- - Height = C + F + D

	-- (int [4]) Camera bounds complements (A, B, C, D):
	read (4 * 4)

	-- (int) Playable area width (E):
	read (4)

	-- (int) Playable area height (F):
	read (4)

	-- (int) Flags:
	-- - 0x0001: 1 = Hide minimap in preview screen
   -- - 0x0002: 1 = Modify ally priorities
   -- - 0x0004: 1 = Melee map
   -- - 0x0008: 1 = Playable map size was large and has never been
	--               reduced to medium (?)
   -- - 0x0010: 1 = Masked area are partially visible
   -- - 0x0020: 1 = Fxed player setting for custom forces
   -- - 0x0040: 1 = Use custom forces
   -- - 0x0080: 1 = Use custom techtree
   -- - 0x0100: 1 = Use custom abilities
   -- - 0x0200: 1 = Use custom upgrades
   -- - 0x0400: 1 = Map properties menu opened at least once
	--               since map creation (?)
   -- - 0x0800: 1 = Show water waves on cliff shores
   -- - 0x1000: 1 = Show water waves on rolling shores
   -- - 0x2000: 1 = Unknown
   -- - 0x4000: 1 = Unknown
   -- - 0x8000: 1 = Unknown
	read (4)

	-- (char) Ground type:
	read (1)

	output.loading_screen = {}

	if is_tft then
		-- (int) Loading screen background number:
		--
		-- Index in the preset list. A value of -1 implies none or a custom
		-- imported file.
		read (4)

		-- (string) Custom loading screen model:
		read_string ()
	else
		-- (int) Campaign background number.
		--
		-- Index in the preset list. A value of -1 implies none.
		read (4)
	end

	-- (string) Loading screen text:
	output.loading_screen.text = read_string (input and
		input.loading_screen and input.loading_screen.text)

	-- (string) Loading screen title:
	output.loading_screen.title = read_string (input and
		input.loading_screen and input.loading_screen.title)

	-- (string) Loading screen subtitle:
	output.loading_screen.subtitle = read_string (input and
		input.loading_screen and input.loading_screen.subtitle)

	if is_tft then
		-- (int) Used game data set:
		--
		-- Index in the preset list. A value of 0 = Standard.
		read (4)

		-- (string) Prologue screen path:
		read_string ()
	else
		-- (int) Loading screen background number:
		--
		-- Index in the preset list. A value of -1 implies none.
		read (4)
	end

	-- (string) Prologue screen text:
	read_string ()

	-- (string) Prologue screen title:
	read_string ()

	-- (string) Prologue screen subtitle:
	read_string ()

	if is_tft then
		-- (int) Use terrain fog:
		--
		-- Inex in preset list. A value of 0 implies not used.
		read (4)

		-- (float) Fog start Z height:
		read (4)

		-- (float) Fog end Z height:
		read (4)

		-- (float) Fog density:
		read (4)

		-- (byte [4]) Fog tinting: red; gree; blue; alpha.
		read (4)

		-- (int) Global weather ID:
		--
		--	A value of 0 implies none. Otherwise, it is one of 4 letter ID values
		--	found in TerrainArt\Weather.slk.
		read (4)

		-- (string) Custom sound environment:
		--
		-- Set to the desired sound label.
		read_string ()

		-- (char): Tileset ID of used custom light environment:
		read (1)

		-- (byte [4]) Custom water tinting: red; green; blue; alpha.
		read (4)
	end

	output.players = {}

	-- (int) Maximum number of players:
	for i = 1, read_integer () do
		output.players [i] = {}

		-- (int) Internal player number:
		read (4)

		-- (int) Player type:
		-- - 1 = Human
		-- - 2 = Computer
		-- - 3 = Neutral
		-- - 4 = Rescuable
		read (4)

		-- (int) Player race:
		-- - 1 = Human
		-- - 2 = Orc
		-- - 3 = Undead
		-- - 4 = Night Elf
		read (4)

		-- (int) Start position:
		-- - 0x00000001 = Fixed
		read (4)

		-- (string) Player name:
		output.players [i].name = read_string (input and
			input.players and input.players [i] and input.players [i].name)

		-- (float) Starting X:
		read (4)

		-- (float) Starting Y:
		read (4)

		-- (int) Ally low priority flags:
		--
		-- Bit 'X' equal to 1 implies set for player 'X'.
		read (4)

		-- (int) Ally high priority flags:
		--
		-- Bit 'X' equal to 1 implies set for player 'X'.
		read (4)
	end

	output.forces = {}

	-- (int) Maximum number of forces:
	for i = 1, read_integer () do
		output.forces [i] = {}

		-- (int) Force flags:
		-- - 0x00000001: Allied (Force 1)
		-- - 0x00000002: Allied victory
		-- - 0x00000004: Share vision
		-- - 0x00000010: Share unit control
		-- - 0x00000020: Share advanced unit control
		read (4)

		-- (int) Player masks:
		--
		-- Bit 'X' equal to 1 implies player 'X' is in force.
		read (4)

		-- (string) Force name:
		output.forces [i].name = read_string (input and
			input.forces and input.forces [i] and input.forces [i].name)
	end

	-- Ignoring the following (the rest of the file):
	-- - Upgrade availability changes
	-- - Tech availability changes
	-- - Random unit tables
	-- - Random item tables (TFT only)
	read ('*a')

	file:close ()
	os.remove (file_path)

	return output
end

-- Uses the `information (table)` (see `W3I.read ()` for details) to upate
-- the 'war3map.w3i' for the provided `map (string)`. Uses the provided
-- `directory (string)` for temporary files. If provided, the `prefix
-- (string)` will be prepended to the command line. Returns `true (boolean)`
-- upon success, or `nil` if an error is encountered.
function W3I.write (information, map, directory, prefix)
	local contents = {}

	local block = function (existing, replacement)
		table.insert (contents, replacement and replacement or existing)
	end

	if not W3I.read (map, directory, prefix, block, information) then
		return nil
	end

	local file_path = Path.join (directory, 'war3map.w3i')
	local file = io.open (file_path, 'wb')
	local status

	if file then
		file:write (table.concat (contents))
		file:close ()

		status = Grimex.imports (prefix, map, file_path, 'war3map.w3i')

		os.remove (file_path)
	end

	return status
end

return W3I
