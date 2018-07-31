local Path = require ('map.path')
local Wurst = require ('map.tool.wurst')

return function (state)
	local output = Path.temporary_path ()
	local status, message = Wurst.run (state.settings.java,
		state.settings.wurst and state.settings.wurst.directory,
		'-out', output, state.settings.scripts)

	os.remove (output)

	if not status then
		return nil, message
	end

	return true
end
