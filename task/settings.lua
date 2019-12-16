return function (state)
	state.settings.map = state.settings.map or {}
	state.settings.map.options = state.settings.map.options or {}

	state.settings.build = state.settings.build or {}
	state.settings.build.package = state.settings.build.package or {}
	state.settings.build.options = state.settings.build.options or {}

	state.settings.script = state.settings.script or {}
	state.settings.script.package = state.settings.script.package or {}
	state.settings.script.options = state.settings.script.options or {}

	return true
end
