local Shell = {}

local is_windows = package.config:sub (1, 1) == '\\'

-- Returns a `string` where the provided `argument (string)` has been
-- escaped for use when passed to `os.execute ()` or `Shell.execute ()`.
function Shell.escape_argument (argument)

	-- Quoting command line arguments the 'right' way:
	--
	-- https://blogs.msdn.microsoft.com/twistylittlepassagesallalike/2011/04/23/everyone-quotes-command-line-arguments-the-wrong-way/
	if is_windows then
		if argument == '' then
			argument = '""'

		-- Deviate from the pattern used in the article by matching against
		-- forward slashes as well. This resolves an issue where the first
		-- argument (likely a command) contains forward slashes and is passed
		-- to `cmd.exe`.
		elseif argument:find ('[ \t\n\v"/]') then
			argument = '"' .. argument:gsub ('(\\*)"', '%1%1\\"') ..
				(argument:match ('\\+$') or '') .. '"'
		end

		argument = argument:gsub ('[()%%!^"<>&|]', '^%0')
	else
		if argument == '' then
			argument = '\'\''
		else
			argument = '\'' .. argument:gsub ('\'', '\'\\\'\'') .. '\''
		end
	end

	return argument
end

-- Takes the provided arguments (which can be any Lua value) and processes
-- them in the following fashion:
--
-- - Any `string` arguments are escaped.
-- - Any `table` arguments are examined and have their contents processed.
--   Nesting of `table` elements is allowed.
-- - Arguments which are not `string` or `table` are ignored.
--
-- Returns a `string` where all matching arguments have been joined together
-- with a space as a delimiter. This value is safe to pass to `os.execute ()`
-- or `Shell.execute ()`.
function Shell.escape_arguments (...)
	local arguments

	if select ('#', ...) == 1
		and type (...) == 'table'
	then
		arguments = ...
	else
		arguments = { ... }
	end

	local output = {}

	for index = 1, #arguments do
		argument = arguments [index]

		if type (argument) == 'table' then
			table.insert (output, Shell.escape_arguments (argument))
		elseif type (argument) == 'string' then
			table.insert (output, Shell.escape_argument (argument))
		end
	end

	return table.concat (output, ' ')
end

-- Takes the provided `command (string)` and executes it in the same fashion
-- as `os.execute ()`. Optionally, takes `stdout (string)` and `stderr
-- (string)` (in that order) to allow redirection of those file descriptors to
-- the provided locations.
--
-- Also, can take the above inputs as a single `table`, using named parameters
-- instead.
--
-- Returns the same results that `os.execute ()` would give in Lua 5.2 or
-- higher, regardless of the version used.
function Shell.execute (...)
	local command, stdout, stderr

	if type (...) == 'table' then
		local arguments = ...

		command = arguments.command
		stdout = arguments.stdout
		stderr = arguments.stderr
	else
		command, stdout, stderr = ...
	end

	if stdout then
		command = command .. ' >' .. stdout
	end

	if stderr then
		command = command .. ' 2>' .. stderr
	end

	-- We determine the version of Lua by examining the results of the
	-- `os.execute ()` function.
	local status_or_code, exit_or_signal, code = os.execute (command)

	-- Lua 5.1 or LuaJIT without 5.2 compatibility:
	if type (status_or_code) == 'number' then
		if status_or_code == 0 then
			return true, 'exit', status_or_code
		else
			if is_windows then
				code = status_or_code

			-- This apparently is only correct on Linux and/or Posix systems.
			else
				code = status_or_code / 256
			end

			return nil, 'exit', code
		end

	-- Lua 5.2, Lua 5.3, or LuaJIT with 5.2 compatibility:
	else
		return status_or_code, exit_or_signal, code
	end
end

return Shell
