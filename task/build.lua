local Tasks = require ('map.tasks')

return function (state)
	local tasks = {
		'check'
	}

	table.insert (tasks, 'build.script')

	if state.settings.map then
		table.insert (tasks, 'build.w3x.write')
	end

	Tasks.add (state, tasks)

	return true
end
