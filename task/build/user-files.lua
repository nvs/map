local Path = require ('map.path')
local Utils = require ('map.utils')

return function (state)
	local build = Utils.load_files ({ state.settings.input.build }, '.lua')
	state.settings.build = nil

	-- Load settings into environment.  Clear what shouldn't be altered.
	state.environment.settings = Utils.deep_copy (state.settings)
	state.environment.settings.input = nil
	state.environment.settings.source = nil

	-- Run user build scripts.
	do
		local messages = {}

		for _, file in ipairs (build) do
			if Path.is_file (file) then
				local chunk, message = loadfile (file)

				if chunk then
					chunk (state.environment)
				else
					table.insert (messages, message)
				end
			end
		end

		if #messages > 0 then
			table.insert (messages, 1, 'error:')
			return nil, table.concat (messages, '\n\t')
		end
	end

	-- Process environment settings.
	do
		local output = state.environment.settings.output
		local directory = output.direcdtory
		local name = output.name

		state.settings.output = {
			directory = directory,
			name = name,
			file = Path.join (directory, name)
		}

		Path.create_directory (directory)
	end

	state.environment.settings = nil

	return true
end
