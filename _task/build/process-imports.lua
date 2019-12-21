local Utils = require ('map.utils')

return function (state)
	local environment = state.environment
	local directories = {}

	for key in pairs (environment.imports) do
		if type (key) == 'number' then
			directories [#directories + 1] = key
		end
	end

	table.sort (directories)

	for _, key in ipairs (directories) do
		local directory = environment.imports [key]
		environment.imports [key] = nil
		local paths = Utils.load_files (directory)
		local index = #directory + 2

		for _, file in ipairs (paths) do
			environment.imports [file:sub (index)] = file
		end
	end

	return true
end
