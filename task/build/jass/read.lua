-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Jass = require ('map.file.jass')
local Path = require ('map.path')
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

local function literal_constant (type, value)
	if type == 'string' then
		-- Count the number of string delimiters on the line.  The presence
		-- of more than two invalidates the string for our purposes.
		local count = select (2, value:gsub ('\\"', ''):gsub ('"', ''))

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

			return value
		end
	end
end

local ignore = {
	['true'] = true,
	['false'] = true,
	['null'] = true
}

local function process_global (line)
	line = Jass.strip_comment (line)
	line = String.trim_right (line)

	if #line == 0 then
		return nil
	end

	local _
	local constant, array
	local type, name, value

	type, array, name = line:match ('^%s*(%l+)%s*(array)%s*([%w_]+)')

	if not array then
		constant, type, name, value = line:match (
			'^%s*(constant)%s*(%l*)%s*([%w_]+)%s*=%s*(.*)$')
	end

	if not constant then
		type, name, _, value = line:match (
			'^%s*(%l*)%s*([%w_]+)%s*(=?%s*(.*))$')
	end

	if not name then
		return nil
	end

	local identifiers = {}
	local literal

	if constant and constants [type] then
		literal = literal_constant (type, value)
	end

	if not array then
		if type == 'string' then
			value = value:gsub ('\\"', ''):gsub ('%b""', '')
		elseif type == 'integer' then
			value = value:gsub ('%b\'\'', '')
		end

		for identifier in value:gmatch ('%a[%w_]+') do
			if not ignore [identifier] then
				table.insert (identifiers, identifier)
			end
		end
	end

	return name, identifiers, literal
end

local function read_jass (files, literals)
	local paths = {}
	local ids = {}

	for _, path in ipairs (files) do
		if Path.is_file (path) then
			paths [path] = {}

			local file = assert (io.open (path, 'rb'))
			local in_globals = false

			for line in file:lines () do
				if line:find ('^%s*globals') then
					in_globals = true
				elseif line:find ('^%s*endglobals') then
					in_globals = false
				elseif in_globals then
					local name, identifiers, literal = process_global (line)

					if name then
						ids [name] = {
							name = name,
							path = path,
							is_global = true,
							identifiers = identifiers
						}

						literals [name] = literal
					end
				else
					local name = line:match ('^%s*function%s+([%w_]+)')

					if not name then
						name = line:match ('^%s*%l*%s*native%s+([%w_]+)')
					end

					if name then
						ids [name] = {
							name = name,
							path = path
						}
					end
				end
			end
		end
	end

	-- Setup the paths for topological sorting.  We cannot do this above, as
	-- we do not have knowledge of where all identifiers are located.  Note
	-- that only files with globals are considered as nodes.
	for _, id in pairs (ids) do
		if id.is_global then
			for _, name in pairs (id.identifiers) do
				local other = ids [name]

				if other and id.path ~= other.path
					and not paths [id.path] [other.path]
				then
					paths [id.path] [other.path] = true
					table.insert (paths [id.path], other.path)
				end
			end
		end
	end

	-- Topological sorting (DFS):
	-- - https://en.wikipedia.org/wiki/Topological_sorting
	local added = {}
	local sorted = {}
	local cycles = {}

	-- Returning `true` indicates a permanent node.  Returning `nil`
	-- indicates a cycle was encountered.
	local function visit (path)
		if not paths [path] then
			return true
		end

		if paths [path] == true then
			return nil
		end

		local edges = paths [path]
		paths [path] = true

		for _, other in ipairs (edges) do
			if not visit (other) then
				table.insert (cycles, { path, other })
			end
		end

		paths [path] = nil

		if not added [path] then
			table.insert (sorted, path)
			added [path] = true
		end

		return true
	end

	-- Going through files in alphanumeric ordering ensures the same
	-- ordering for the `war3map.j` produced by Wurst.
	for _, path in ipairs (files) do
		if paths [path] then
			visit (path)
		end
	end

	if #cycles > 0 then
		local messages = { 'error: circular dependencies in globals:' }

		for _, cycle in ipairs (cycles) do
			table.insert (messages, string.format (
				'in files \'%s\' and \'%s\'', table.unpack (cycle)))
		end

		return nil, table.concat (messages, '\n\t')
	end

	-- Add files without globals to the end of the list.
	for _, path in ipairs (files) do
		if not added [path] then
			table.insert (sorted, path)
			added [path] = true
		end
	end

	return sorted
end

return function (state)
	local globals = {}

	local sorted, message = read_jass (state.settings.source.jass, globals)

	if sorted then
		state.environment.globals = globals
		state.settings.source.jass = sorted
	end

	return not not sorted, message
end
