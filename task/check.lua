local Modules = require ('map.modules')
local Path = require ('map.path')
local Shell = require ('map.shell')

return function (state)
	local modules, message = Modules.load (state)

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
