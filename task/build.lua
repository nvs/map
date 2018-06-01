local Tasks = require ('map.tasks')

return function (state)
	io.stdout:write ('Building...\n')

	local tasks = {
		'build.environment',
		'build.w3x.read',
		'build.jass.read',
		'build.inline-strings',
		'build.user-files',
		'build.jass.write',
		'build.w3x.write'
	}

	Tasks.add (state, tasks)

	return true
end
