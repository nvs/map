local Modules = require ('map.modules')

return function (state)
	local modules, message = Modules.load (
		state.settings.script.input,
		state.settings.script.package.path)

	if not modules then
		return nil, message
	end

	state.modules = modules

	return true
end
