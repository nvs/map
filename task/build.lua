local Tasks = require ('map.tasks')

return function (state)
	local tasks = {
		'check',
		'build.environment'
	}

	if state.settings.map then
		table.insert (tasks, 'build.w3x.read')
	end

	if state.settings.build then
		table.insert (tasks, 'build.user-files')
	end

	-- The script was checked.  We can attempt to compile.
	table.insert (tasks, 'build.script')

	if state.settings.map then
		table.insert (tasks, 'build.w3x.write')
	end

	Tasks.add (state, tasks)

	return true
end
