local Tasks = require ('map.tasks')

return function (state)
	local tasks = {
		'build.environment'
	}

	if state.settings.map then
		table.insert (tasks, 'build.w3x.read')
	end

	if state.settings.build then
		table.insert (tasks, 'build.user-files')
	end

	table.insert (tasks, 'check')
	table.insert (tasks, 'build.script')

	if state.settings.map then
		table.insert (tasks, 'build.w3x.write')
	end

	Tasks.add (state, tasks)

	return true
end
