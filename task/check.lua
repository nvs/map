local Modules = require ('map.modules')
local Path = require ('map.path')
local Shell = require ('map.shell')

return function (state)
	local root = state.settings.input.source
	local modules, message = Modules.find (root)

	if not modules then
		error (message)
	end

	local paths = {}

	for _, path in pairs (modules) do
		table.insert (paths, path)
	end

	local status = Shell.execute {
		command = Shell.escape ('luacheck', '--default-config',
			Path.join ('map', 'luacheck', 'luacheckrc'), '--quiet', paths)
	}

	return status
end
