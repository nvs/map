local Path = require ('map.path')
local PJass = require ('map.tool.pjass')

local function check_existence (paths, missing)
	for _, path in ipairs (paths) do
		if not Path.is_file (path) then
			table.insert (missing, ('\tno file \'%s\''):format (path))
		end
	end
end

return function (state)
	local missing = {}

	check_existence (state.settings.patch, missing)
	check_existence (state.settings.scripts, missing)

	if #missing > 0 then
		table.insert (missing, 1, 'error:')
		return nil, table.concat (missing, '\n')
	end

	local status, output = PJass.run (state.settings.pjass,
		state.settings.patch, state.settings.scripts)

	-- Filter out successfully parsed files.  If all files parse
	-- successfully, then there is no output to display.
	if status then
		output = nil
	else
		output = output:gsub ('Parse successful:.-\n', '')
	end

	return status == true, output
end
