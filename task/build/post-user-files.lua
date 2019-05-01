local Path = require ('map.path')

return function (state)
	-- Output.
	do
		local output = state.settings.output
		local directory = output.directory
		local name = output.name

		output.file = Path.join (directory, name)
		Path.create_directories (directory)
	end

	return true
end
