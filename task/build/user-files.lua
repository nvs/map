local Path = require ('map.path')

return function (state)
	state.settings.build = state.settings.build or {}

	-- Load state settings into environment.
	state.environment.settings = {
		output = {
			directory = state.settings.output.directory,
			name = state.settings.output.name
		}
	}

	-- Run user build scripts.
	do
		local messages = {}

		for _, file in ipairs (state.settings.build) do
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

	-- Load environment settings into state.  Nothing should be accessing
	-- environment settings directly.
	state.settings.output.directory =
		state.environment.settings.output.directory
	state.settings.output.name = state.environment.settings.output.name
	state.settings.output.file = Path.join (
		state.settings.output.directory, state.settings.output.name)

	state.environment.settings = nil

	return true
end
