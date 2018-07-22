local Path = require ('map.path')
local PJass = require ('map.tool.pjass')
local W3X = require ('map.file.w3x')
local Wurst = require ('map.tool.wurst')

local defaults = {
	java = 'java',
	wurst = {
		directory = Path.join (Path.home_directory (), '.wurst'),
		optimize= {
			'-opt',
			'-inline',
			'-localOptimizations'
		}
	}
}

local function optimize (state, input, output)
	local java = state.settings.java or defaults.java
	local wurst = state.settings.wurst or defaults.wurst

	if wurst ~= defaults.wurst then
		for key, value in pairs (defaults.wurst) do
			wurst [key] = wurst [key] or value
		end
	end

	assert (type (java) == 'string')
	assert (type (wurst) == 'table')
	assert (Path.is_directory (wurst.directory))
	assert (type (wurst.optimize) == 'table')

	local jar = Path.join (wurst.directory, 'wurstscript.jar')
	assert (Path.is_file (jar))

	-- We do a check on the optimized script with the user specified version
	-- of PJass, not the one provided by Wurst.
	local command = {
		java, '-jar', jar, '-out', output,
		state.settings.patch, input,
		'-noPJass', wurst.optimize
	}

	local status, message = Wurst.run (command)

	if not status then
		return nil, message
	end

	return true
end

return function (state)
	io.stdout:write ('Optimizing...\n')

	local map = state.settings.output.file
	local map_script = map .. '.j'

	local optimized = map:gsub ('%.w3x$', '-optimized.w3x')
	local optimized_script = optimized .. '.j'

	local status, output = optimize (state, map_script, optimized_script)

	if not status then
		return nil, output
	end

	status, output = PJass.run (state.settings.pjass,
		state.settings.patch, optimized_script)

	if not status then
		return nil, output
	end

	io.stdout:write ('- ', optimized_script, '\n')

	assert (Path.copy (map, optimized))

	local w3x = assert (W3X.open (optimized, 'r+'))
	assert (w3x:add (optimized_script, 'war3map.j'))

	-- Close and compact.
	w3x:close (true)

	io.stdout:write ('- ', optimized, '\n')

	return true
end
