local Utils = require ('map.utils')

return function (state)
	-- Input.
	do
		local input = state.settings.input or {}
		input.source = input.source or {}

		state.settings.input = input
	end

	-- Output.
	do
		local output = state.settings.output or {}
		state.settings.output = output
	end

	-- Options.
	do
		local options = state.settings.options or {
			debug = false
		}

		state.settings.options = options
	end

	-- Prepare the `package.path`.
	do
		local directory = state.settings.input.source.directory

		if directory then
			package.path = package.path .. string.format (
				';%s/?.lua;%s/?/init.lua', directory, directory)
		end
	end

	return true
end
