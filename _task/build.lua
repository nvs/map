local Task = require ('map._task')

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
		tasks [#tasks + 1] = 'build.process-imports'
		tasks [#tasks + 1] = 'environment.teardown'
		tasks [#tasks + 1] = 'build.w3x'
	end

	Task.add (state, tasks)

	return true
end
