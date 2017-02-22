local Globals = require ('map.globals')
local JASS = require ('map.jass')
local Path = require ('map.path')
local PJass = require ('map.tools.pjass')
local Settings = require ('map.settings')

local Map = {}

-- Takes the configuration setting `pair (table)` (i.e. `pair.directory
-- (string)` and `pair.files (table)`) and ensures that all files exist.
-- Returns a `table` containing the files with the directory appended upon
-- success. Otherwise, `nil` with an error message `string`.
function Map.load_files (pair)
	local files = {}
	local missing = {}

	for _, file in ipairs (pair.files) do
		file = Path.join (pair.directory, file)

		if Path.is_readable (file) then
			table.insert (files, file)
		else
			if #missing == 0 then
				table.insert (missing, 'error:')
			end

			table.insert (missing, string.format (	'\tno file \'%s\'', file))
		end
	end

	if #missing > 0 then
		return nil, table.concat (missing, '\n') .. '\n'
	else
		return files
	end
end

-- Goes over the scripts specified in `settings (table)` (i.e. those in
-- `settings.patch` and `settings.scripts`), ensuring they exist and are valid
-- JASS syntax.
--
-- Upon success, returns a `table` containing the patch scripts, a `table`
-- containing the map scripts, and a `string` containing the parse results. On
-- parse failure, returns `false` twice, followed by a `string` containing the
-- parse results. On error, returns `nil` twice, followed by a `string`
-- containing an error message.
function Map.check_scripts (settings)
	local patch_scripts, message = Map.load_files (settings.patch)

	if not patch_scripts then
		return nil, nil, message
	end

	local map_scripts, message = Map.load_files (settings.scripts)

	if not map_scripts then
		return nil, nil, message
	end

	local status, output = PJass.check (settings.prefix,
		settings.pjass.options, patch_scripts, map_scripts)

	if status then
		return patch_scripts, map_scripts, output
	else
		return false, false, output
	end
end

-- Takes the provided `list (table)` of JASS scripts, processing each, and
-- returning a `table` preserving the `list` order, where each script is
-- represented by a `table` with the structure specified in `JASS.read ()`.
function Map.parse_scripts (list)
	local scripts = {}

	for _, path in ipairs (list) do
		local script = JASS.read (path)

		if script then
			table.insert (scripts, script)
		end
	end

	return scripts
end

-- Manges the 'debug' keyword for each of the JASS scripts listed in `scripts
-- (table)`, according to the flag provided in `settings (table)`.
function Map.debug_scripts (scripts, settings)
	for _, script in ipairs (scripts) do
		JASS.debug (script, settings.flags.debug)
	end
end

-- Combines the JASS scripts listed in `scripts (table)`, according to the
-- values provided in `settings (table)`. Returns `true (boolean)` upon
-- success, and `nil` otherwise.
function Map.build_script (scripts, settings)
	os.remove (settings.output.script)
	local script = io.open (settings.output.script, 'wb')

	if not script then
		return nil
	end

	script:write ('globals', '\n')

	for index = 1, #scripts do
		-- Skip the keywords 'globals' and 'endglobals'.
		for line_index = 2, #scripts [index].globals - 1 do
			script:write (scripts [index].globals [line_index], '\n')
		end
	end

	script:write ('endglobals', '\n')

	for index = 1, #scripts do
		for _, line in ipairs (scripts [index].non_globals) do
			script:write (line, '\n')
		end
	end

	script:close ()

	return true
end

-- Takes the provided `map (table)` environment and attempts to load
-- environment plugins provided by the user via the `environment` setting.
local function load_environment (map)
	local files = Map.load_files (map.settings.environment)
	local messages = {}

	for _, file in ipairs (files) do
		local chunk, message = loadfile (file)

		if chunk then
			chunk (map)
		else
			table.insert (messages, message)
		end
	end

	if #messages > 0 then
		table.insert (messages, 1, 'parse error:')

		return nil, table.concat (messages, '\n\t')
	end

	-- Ensure that any changes will pass basic validation.
	local is_valid, message = Settings.validate (map.settings)

	if not is_valid then
		return nil, message
	end

	return true
end

-- Takes the provided `options (table)`, where keys represent command otions,
-- and each cooresponding value is a `function` to execute. By default, will
-- run `options ['--help']` if no arguments are passed to the command.
--
-- Then it attempts to initialize a map environment. This involves loading
-- settings, parsing scripts, and loading globals. Upon success, returns a
-- `table` with the following structure, along with the output `string` of a
-- successful parse.
--
-- ```
-- {
--     command = '', -- The executed command.
--     settings = {
--         -- The results of `Settings.read ()`.
--     },
--     patch = {
--         -- The results of `Map.parse_scripts ()` upon the patch files.
--     },
--     scripts = {
--         -- The results of `Map.parse_scripts ()` upon the map scripts.
--     },
--     globals = {
--         -- The results of `Globals.process ()` upon the map scripts.
--     }
-- }
-- ```
--
-- Upon parse failure, returns `false` along with a `string` containing the
-- parse results. Upon error, returns `nil` followed by a `string` containing
-- an error message.
function Map.initialize (options)
	if #arg == 0 then
		if options ['--help'] then
			options ['--help'] ()
		else
			return nil, 'command has no `--help` option\n'
		end
	end

	local index = 1

	while arg [index] and options [arg [index]] do
		options [arg [index]] ()
		index = index + 1
	end

	local map = {
		command = Path.base_name (arg [0])
	}

	local settings, message = Settings.read (arg [index])

	if settings then
		map.settings = settings
	else
		return nil, message .. '\n'
	end

	local patch_scripts, map_scripts, output = Map.check_scripts (settings)

	if patch_scripts then
		map.patch = Map.parse_scripts (patch_scripts, settings)
		map.scripts = Map.parse_scripts (map_scripts, settings)
		map.globals = Globals.process (unpack (map.scripts))

		local status, message = load_environment (map)

		if not status then
			return nil, message .. '\n'
		end

		Settings.finalize (map.settings)

		return map, output
	else
		return patch_scripts, output
	end
end

-- Displays the current version of the map tools for the command being
-- executed, then exits successfully.
function Map.version ()
	local Version = require ('map.version')

	io.stdout:write (string.format ([[
map %s %d.%d.%d
]], Path.base_name (arg [0]), Version.major, Version.minor, Version.patch))

	os.exit (0)
end

return Map
