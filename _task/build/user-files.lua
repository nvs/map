local Utils = require ('map.utils')

return function (state)
	local build = Utils.load_files (
		state.settings.build.directory, '%.lua$')

	local messages = {}
	local original = {}
	local environment = {
		path = state.settings.build.package.path or package.path,
		cpath = state.settings.build.package.cpath or package.cpath,
		preload = {},
		loaded = {}
	}

	for _, file in ipairs (build) do
		local chunk, message = loadfile (file)

		if chunk then
			for key, value in pairs (environment) do
				original [key] = value
				package [key] = value
			end

			chunk (state.environment)

			for key, value in pairs (original) do
				package [key] = value
			end
		else
			table.insert (messages, message)
		end
	end

	if #messages > 0 then
		table.insert (messages, 1, 'error:')
		return nil, table.concat (messages, '\n\t')
	end

	return true
end
