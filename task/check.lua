local Tasks = require ('map.tasks')

return function (state)
	local tasks = {}

	tasks [#tasks + 1] = 'environment.setup'

	if state.settings.build then
		local disable = state.settings.build.options.disable

		if disable ~= true and disable ~= 'check' then
			tasks [#tasks + 1] = 'build.user-files'
		end
	end

	tasks [#tasks + 1] = 'check.load-modules'
	tasks [#tasks + 1] = 'check.run'

	Tasks.add (state, tasks)

	return true
end
