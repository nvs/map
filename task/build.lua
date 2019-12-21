local Tasks = require ('map.tasks')

return function (state)
	local tasks = {
		'check'
	}

	table.insert (tasks, 'build.script')

	if state.settings.map then
		if state.settings.map.input == state.settings.map.output then
			return nil, [[
map: `settings.map.input` and `settings.map.output` must differ]]
		end

		table.insert (tasks, 'build.process-imports')
		table.insert (tasks, 'environment.teardown')
		table.insert (tasks, 'build.w3x.write')
	end

	Tasks.add (state, tasks)

	return true
end
