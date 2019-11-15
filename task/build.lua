local Tasks = require ('map.tasks')

return function (state)
	local map = state.settings.input.map
	local build = state.settings.input.build

	local tasks = {
		'check'
	}

	if map then
		table.insert (tasks, 'build.w3x.read')
	end

	if build then
		table.insert (tasks, 'build.user-files')
	end

	-- This step is done regardless of whether user files were handled.
	table.insert (tasks, 'build.post-user-files')

	-- The script was checked.  We can attempt to compile.
	table.insert (tasks, 'build.script')

	if map then
		table.insert (tasks, 'build.w3x.write')
	end

	Tasks.add (state, tasks)

	return true
end
