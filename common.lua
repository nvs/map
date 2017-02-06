local JASS = require ('map.jass')
local Path = require ('map.path')
local PJass = require ('map.tools.pjass')

local Map = {}

function Map.files_exist (pair)
	local files = {}
	local missing = {}

	for _, file in ipairs (pair.files) do
		file = Path.join (pair.directory, file)

		if Path.is_readable (file) then
			table.insert (files, file)
		else
			if #missing == 0 then
				table.insert (missing, 'Error:')
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

function Map.check_scripts (settings)
	local patch_scripts, message = Map.files_exist (settings.patch)

	if not patch_scripts then
		return nil, nil, message
	end

	local map_scripts, message = Map.files_exist (settings.scripts)

	if not map_scripts then
		return nil, nil, message
	end

	local status, output = PJass.check (settings.prefix,
		settings.pjass.options, patch_scripts, map_scripts)

	return patch_scripts, map_scripts, output
end

-- Takes the provided `list (table)` of JASS scripts, processing each, and
-- returning a `table` preserving the `list` order, where each script is
-- represented by a `table` with the structure specified in `JASS.read ()`.
function Map.parse_scripts (list, settings)
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

return Map
