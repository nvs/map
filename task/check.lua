local Tasks = require ('map.tasks')

return function (state)
	local tasks = {
		'check.load-modules',
		'check.run'
	}

	Tasks.add (state, tasks)

	return true
end
