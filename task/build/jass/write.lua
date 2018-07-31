local Wurst = require ('map.tool.wurst')

return function (state)
	local script_path = state.settings.output.file .. '.j'
	local status, message = Wurst.run (state.settings.java,
		state.settings.wurst and state.settings.wurst.directory,
		'-out', script_path, state.settings.patch, state.settings.scripts)

	if not status then
		return nil, message
	end

	io.stdout:write ('- ', script_path, '\n')

	return true
end
