local String = require ('map.string')

local Globals = {}

local patterns = {
	boolean = {
		'^(true)$',
		'^(false)$'
	},

	string = {
		'^"(.*)"$'
	},

	real = {
		'^(-?%.%d+)$',
		'^(-?%d+%.%d*)$'
	},

	integer = {
		{ 'literal', '^(\'.\')$' },
		{ 'code', '^(\'....\')$' },
		{ 'hexadecimal', '^(-?%$%x+)$' },
		{ 'hexadecimal', '^(-?0x%x+)$' },
		{ 'octal', '^(-?0[0-7]+)$' },
		{ 'decimal', '^(-?%d+)$' }
	}
}

-- Returns a `string` after processing the provided `text (string)`. This
-- removes any comment that is present, and invalidates the text (i.e.
-- returns an empty string) if it contains more than one JASS string
-- constant.
local function validate_and_strip_comment (text)
	local current
	local previous

	local count = 0

	for index = 1, #text do
		previous = current
		current = text:sub (index, index)

		-- Unescaped double quotes.
		if current == '"' and previous ~= '\\' then
			count = count + 1

			-- The presence of a second string on the line, albeit valid JASS,
			-- strictly renders the global invalid for our purposes.
			if count > 2 then
				return ''
			end

		-- Comment does not start inside a string. Strip it and finish.
		elseif current == '/' and previous == '/' and count ~= 1 then
			return text:sub (1, index - 2)
		end
	end

	return text
end

-- Takes the specified `line (string)`, expected to be a global declaration,
-- and determines if it meets the needed criteria to be exposed as a
-- constant global. If so, returns the following 'string' values: the
-- global's name, its JASS type, and its value.
local function process (line)
	local value_type, name, value = line:match (
		'^%s*constant%s+(%w+)%s+([%w_]+)%s*=%s*(.*)$')

	for _, pattern in ipairs (patterns [value_type] or {}) do
		local jass_type = value_type

		value = validate_and_strip_comment (value)
		value = String.strip_trailing (value, '%s')

		if type (pattern) == 'table' then
			jass_type = jass_type .. '.' .. pattern [1]
			pattern = pattern [2]
		end

		local match = value:match (pattern)

		if match then
			return name, jass_type, match
		end
	end
end

-- Takes any number of script `table` objects (see `JASS.read ()` for the
-- `table` specification) and returns a `table` containing all globals
-- contained within that meet specific crteria. For details, see the
-- [globals documentation] (docs/globals.md).
function Globals.process (...)
	local scripts = { ... }
	local globals = {}

	for _, script in ipairs (scripts) do
		for _, line in ipairs (script.globals) do
			local name, jass_type, value = process (line)

			if name then
				globals [name] = {
					jass_type = jass_type,
					value = value
				}
			end
		end
	end

	return globals
end

-- Takes the provided `globals (table)` and writes each global into the
-- specified `file (string)`. This will create a Lua file that sets a global
-- `table` named 'globals' when loaded.
function Globals.write (path, globals)
	os.remove (path)
	local file = io.open (path, 'wb')

	if not file then
		return nil
	end

	file:write ('globals = {', '\n')

	for name, contents in pairs (globals) do
		file:write (string.format ([=[
	[%q] = {
		jass_type = %q,
		value = %q
	},
]=], name, contents.jass_type, contents.value))
	end

	file:write ('}', '\n')
	file:close ()

	return true
end

return Globals
