local Utils = require ('map.utils')

return function (state)
	local build = Utils.load_files (
		state.settings.build.directory, '%.lua$')

	local settings = Utils.deep_copy (state.settings)
	state.environment.settings = Utils.read_only (settings)

	local messages = {}

	for _, file in ipairs (build) do
		local chunk, message = loadfile (file)

		if chunk then
			local original = package.path
			package.path = state.settings.build.package.path
			chunk (state.environment)
			package.path = original
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
