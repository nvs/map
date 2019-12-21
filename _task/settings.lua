local Path = require ('map.path')

return function (state)
	if state.settings.map then
		local map = state.settings.map
		map.options = map.options or {}

		assert (Path.exists (map.input))

		if map.input == map.otput then
			return nil, [[
map: `settings.map.input` and `settings.map.output` must differ]]
		end
	end

	if state.settings.build then
		local build = state.settings.build
		build.package = build.package or {}
		build.options = build.options or {}

		assert (Path.is_directory (build.directory))
	end

	if state.settings.script then
		local script = state.settings.script
		script.package = script.package or {}
		script.options = script.options or {}

		assert (Path.is_file (script.input))
	end

	return true
end
