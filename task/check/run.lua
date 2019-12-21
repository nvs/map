local Path = require ('map.path')
local Shell = require ('map.shell')

return function (state)
	local paths = {
		state.settings.script.input
	}

	for _, path in pairs (state.modules) do
		table.insert (paths, path)
	end

	local skip_checks = state.settings.script.options.skip_checks
	local result = true

	if skip_checks ~= true and skip_checks ~= 'check' then
		result = os.execute (Shell.escape (
			'luacheck', '--default-config',
			Path.join ('map', 'luacheck', 'luacheckrc'), paths))
	end

	return result
end
