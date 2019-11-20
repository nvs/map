local Path = require ('map.path')
local Shell = require ('map.shell')

return function (state)
	local paths = {
		state.settings.script.input
	}

	for _, path in pairs (state.modules) do
		table.insert (paths, path)
	end

	local status = Shell.execute {
		command = Shell.escape ('luacheck', '--default-config',
			Path.join ('map', 'luacheck', 'luacheckrc'), '--quiet', paths)
	}

	return status
end
