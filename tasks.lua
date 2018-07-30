local Tasks = {}

-- Added tasks are represented as a queue.  However, tasks are internally
-- represented by a stack.
function Tasks.add (state, tasks)
	repeat
		local task = table.remove (tasks)
		table.insert (state.tasks, task)
	until #tasks == 0
end

function Tasks.run (input)
	local state = {
		tasks = {}
	}

	Tasks.add (state, input.tasks)

	if not input.arguments then
		input.arguments = {}
	end

	if #input.arguments == 0 then
		table.insert (input.arguments, '--help')
	end

	local status
	local message
	local configuration

	for _, argument in ipairs (input.arguments) do
		local option = argument:match ('^(%-%-.*)')

		-- The first non-option argument is the configuration file.
		if not option then
			configuration = configuration or argument

		-- Display and exit if we have an option.
		elseif option == '--version' then
			status = true
			message = require ('map.version')
			break
		elseif option == '--help' then
			status = true
			message = input.help
			break
		else
			status = nil
			message = 'error: unknown option `' .. option .. '`'
			break
		end
	end

	local settings

	if configuration then
		local chunk
		chunk, message = loadfile (configuration)

		if chunk then
			settings = chunk ()
		else
			message = 'error: ' .. message
		end
	end

	if settings then
		table.insert (state.tasks, 'settings')
		state.settings = settings

		while #state.tasks > 0 do
			local name = table.remove (state.tasks)
			local task = require ('map.task.' .. name)
			status, message = task (state)

			if not status then
				break
			end
		end
	end

	if message then
		local stream = status == nil and io.stderr or io.stdout
		stream:write (message, '\n')
	end

	if not status then
		-- Use of `error ()` with no arguments in Lua 5.2 and below
		-- (including LuaJIT) will return `EXIT_FAILURE` and clean up the
		-- Lua state.  This is analogous to using `os.exit ()` with the
		-- optional parameter in Lua 5.2+ (as well as LuaJIT).
		if _VERSION < 'Lua 5.3' then
			error ()
		else
			os.exit (false, true)
		end
	end
end

return Tasks
