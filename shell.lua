-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	-- For enhanced `os.execute ()` return code.
	require ('compat53')
end

local Path = require ('map.path')

local Shell = {}

local is_windows = Path.separator == '\\'

-- Returns an escaped `string` that is safe to pass to `os.execute ()` or
-- `Shell.execute ()`.  A variable number of arguments are processed in the
-- following fashion:
--
-- - Any `string` arguments are escaped and joined together with a space as
--   a delimiter.
-- - Any `table `arguments are examined and have their contents processed in
--   order.  Nesting of `table` elements is allowed.
-- - All other types are ignored.
function Shell.escape (...)
	local arguments
	local size = select ('#', ...)

	if size == 1 and type (...) == 'table' then
		arguments = ...
		size = nil
	else
		arguments = { ... }
	end

	local output = {}

	-- Do not use `ipairs ()` so that we may support `nil` arguments.
	for index = 1, size or #arguments do
		local argument = arguments [index]
		local result

		if type (argument) == 'table' then
			result = Shell.escape (argument)
		elseif type (argument) == 'string' then
			-- [Quoting command line arguments the 'right' way].
			if is_windows then
				if argument == '' then
					argument = '""'

				-- Deviate from the pattern used in the article by matching
				-- against forward slashes as well.  This resolves an issue
				-- where the first argument (likely a command) contains
				-- forward slashes and is passed to `cmd.exe`.
				elseif argument:find ('[ \t\n\v"/]') then
					argument = '"' .. argument:gsub ('(\\*)"', '%1%1\\"') ..
						(argument:match ('\\+$') or '') .. '"'
				end

				argument = argument:gsub ('[()%%!^"<>&|]', '^%0')
			else
				argument = '\'' .. argument:gsub ('\'', '\'\\\'\'') .. '\''
			end

			result = argument
		end

		output [#output + 1] = result
	end

	return table.concat (output, ' ')
end

-- Takes the provided `arguments (table)` and executes the contained
-- `command (string)` in the same fashion as `os.execute ()`.  Optionally,
-- takes `stdout (string)` and `stderr (string)` to allow redirection of
-- those file descriptors to the provided locations.
--
-- Returns the same results that `os.execute ()` would give in Lua 5.2 or
-- higher (with some notable limitations in Lua 5.1).  See [compat-5.3]
-- documentation for details.
function Shell.execute (arguments)
	assert (type (arguments) == 'table')
	assert (type (arguments.command) == 'string')

	local command = arguments.command

	if arguments.stdout then
		assert (type (arguments.stdout) == 'string')

		command = command .. ' >' .. arguments.stdout
	end

	if arguments.stderr then
		assert (type (arguments.stderr) == 'string')

		command = command .. ' 2>' .. arguments.stderr
	end

	return os.execute (command)
end

return Shell

-- luacheck: ignore 631
--
-- [compat-5.3]: https://github.com/keplerproject/lua-compat-5.3
-- [Quoting command line arguments the 'right' way]: https://blogs.msdn.microsoft.com/twistylittlepassagesallalike/2011/04/23/everyone-quotes-command-line-arguments-the-wrong-way
