local JASS = {}

-- Modifies the provided JASS `script (table)` according to whether debugging
-- is `enabled (boolean)`. If enabled, the 'debug' keyword will simply be
-- removed from lines, allowing them to run. If disabled, which is the
-- default, lines affected by the 'debug' keyword will be removed completely.
function JASS.debug (script, enabled)
	local lines = {}

	local keyword
	local count

	for _, line in ipairs (script.non_globals) do
		-- Remove 'debug' keyword from matching lines.
		if enabled then
			local indentation, contents = line:match ('^(%s*)debug%s(.*)$')

			if contents then
				table.insert (lines, indentation .. contents)
			else
				table.insert (lines, line)
			end

		-- Remove all lines modified by the 'debug' keyword.
		else
			local A, B = line:match ('^%s*(%a+)%s*(%a*).*$')

			if keyword then
				if keyword == A or keyword == B then
					count = count + 1
				elseif 'end' .. keyword == A then
					count = count - 1
				end

				if count == 0 then
					keyword = nil
				end
			elseif A == 'debug' and (B == 'if' or B == 'loop') then
				keyword = B
				count = 1
			elseif A == 'debug' then
			else
				table.insert (lines, line)
			end
		end
	end

	script.non_globals = lines
end

-- Reads the JASS script specified by `path (string)`, returning a `table`
-- with the following structure.
--
-- ```
-- {
--     path = 'path/to/script.j',
--     globals = {
--         -- Lines of the globals block.
--     },
--     non_globals = {
--         -- All other lines in the script.
--     }
-- }
-- ```
--
-- Note that the keywords used to open and close the globals declaration block
-- are preserved.
--
-- If an error is encountered, `nil` is returned.
function JASS.read (path)
	local globals = {}
	local non_globals = {}

	local file = io.open (path, 'rb')

	if not file then
		return nil
	end

	local in_globals = false

	for line in file:lines () do
		if line:match ('^%s*globals.*$') then
			in_globals = true
		end

		if in_globals then
			table.insert (globals, line)
		else
			table.insert (non_globals, line)
		end

		if line:match ('^%s*endglobals.*$') then
			in_globals = false
		end
	end

	file:close ()

	return {
		path = path,
		globals = globals,
		non_globals = non_globals
	}
end

return JASS
