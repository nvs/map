local Utils = require ('map.utils')

return function (state)
	state.settings.map = state.settings.map or {}
	state.settings.map.options = state.settings.map.options or {}

	state.settings.build = state.settings.build or {}
	state.settings.build.options = state.settings.build.options or {}

	state.settings.script = state.settings.script or {}
	state.settings.script.options = state.settings.script.options or {}

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

	return true
end
