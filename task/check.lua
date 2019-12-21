local Tasks = require ('map.tasks')

return function (state)
	local tasks = {
		'environment.setup'
	}

	if state.settings.build then
		table.insert (tasks, 'build.user-files')
	end

	table.insert (tasks, 'check.load-modules')
	table.insert (tasks, 'check.run')

	Tasks.add (state, tasks)

	return true
end
