-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Jass = require ('map.file.jass')
local String = require ('map.string')

-- Valid non-escaped characters are the ASCII printable characters (i.e.
-- codes `[32, 126]`) minus that of `'` (code `39`) and `\` (code `92`).
local character = '[ -&(-[%]^-~]'

local constants = {
	boolean = {
		{ pattern = '^(true)$' },
		{ pattern = '^(false)$' }
	},

	string = {
		{ pattern = '^"(.*)"$' }
	},

	integer = {
		{
			subtype = 'character',
			pattern = '^([+-]?\'' .. character .. '\')$'
		},
		{
			subtype = 'character',
			pattern = '^([+-]?\'\\[btnfr"\\]\')$'
		},
		{
			subtype = 'code',
			pattern = '^([+-]?\'' .. character:rep (4) .. '\')$'
		},
		{
			subtype = 'hexadecimal',
			pattern = '^([+-]?$%x+)$'
		},
		{
			subtype = 'hexadecimal',
			pattern = '^([+-]?0x%x+)$',
		},
		{
			subtype = 'octal',
			pattern = '^([+-]?0[0-7]+)$'
		},
		{
			subtype = 'decimal',
			pattern = '^([+-]?%d+)$'
		}
	},

	real = {
		{ pattern = '^([+-]?%d+%.?%d*)$' },
		{ pattern = '^([+-]?%.?%d+)$' }
	}
}


local function is_literal_constant (line)
	line = Jass.strip_comment (line)
	line = String.trim_right (line)

	local type, name, value = line:match (
		'^%s*constant%s+([%w_]+)%s+([%w_]+)%s*=%s*(.*)$')

	if not type or not constants [type] then
		return nil
	elseif type == 'string' then
		-- Count the number of string delimiters on the line.  The presence
		-- of more than two invalidates the string for our purposes.
		local count = select (2, value:gsub ('[^\\]?"', ''))

		if count > 2 then
			return nil
		end
	end

	for _, constant in ipairs (constants [type]) do
		local match = value:match (constant.pattern)

		if match then
			if type == 'boolean' then
				value = match == 'true'
			elseif type == 'string' then
				value = match
			elseif constant.subtype == 'character' then
				value = string.unpack ('B', match:sub (2, -2))
			elseif constant.subtype == 'code' then
				value = string.unpack ('>I4', match:sub (2, -2))
			else
				if constant.subtype == 'hexadecimal' then
					match = match:gsub ('^([+-]?)%$', '%10x')
				end

				value = tonumber (match)
			end

			return name, value
		end
	end
end

local function read_jass (files, state, is_script)
	for _, path in ipairs (files) do
		local file = assert (io.open (path, 'rb'))
		local in_globals = false

		for line in file:lines () do
			if line:find ('^%s*globals') then
				in_globals = true
			elseif line:find ('^%s*endglobals') then
				in_globals = false
			elseif in_globals then
				if is_script then
					state.jass.globals [#state.jass.globals + 1] = line
				end

				local name, value = is_literal_constant (line)

				if name then
					state.environment.globals [name] = value
				end
			elseif is_script then
				state.jass.non_globals [#state.jass.non_globals + 1] = line
			end
		end
	end
end

return function (state)
	state.environment.globals = {}
	state.jass = {
		globals = {},
		non_globals = {}
	}

	read_jass (state.settings.patch, state, false)
	read_jass (state.settings.scripts, state, true)

	return true
end
