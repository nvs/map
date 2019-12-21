local Tasks = require ('map.tasks')

return function (state)
	local tasks = {}

	tasks [#tasks + 1] = 'environment.setup'

	if state.settings.build then
		local disable = state.settings.build.options.disable

		if disable ~= true and disable ~= 'build' then
			tasks [#tasks + 1] = 'build.user-files'
		end
	end

	if state.settings.script then
		tasks [#tasks + 1] = 'check.load-modules'
		tasks [#tasks + 1] = 'check.run'
		tasks [#tasks + 1] = 'build.script'
	end

	if state.settings.map then
		if state.settings.map.input == state.settings.map.output then
			return nil, [[
map: `settings.map.input` and `settings.map.output` must differ]]
		end

		tasks [#tasks + 1] = 'build.process-imports'
		tasks [#tasks + 1] = 'environment.teardown'
		tasks [#tasks + 1] = 'build.w3x.write'
	end

	Tasks.add (state, tasks)

	return true
end
