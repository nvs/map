local Path = require ('map.path')
local W3X = require ('map.file.w3x')
local Wurst = require ('map.tool.wurst')

local defaults = {
	optimize = {
		'-opt',
		'-inline',
		'-localOptimizations'
	}
}

return function (state)
	io.stdout:write ('Optimizing...\n')

	local map = state.settings.output.file
	local optimized = map:gsub ('%.w3x$', '-optimized.w3x')
	local optimized_script = optimized .. '.j'

	local optimize = defaults.optimize

	if type (state.settings.wurst) == 'table' then
		optimize = state.settings.wurst.optimize or optimize
	end

	assert (type (optimize) == 'table')

	local status, message = Wurst.run (state.settings.java,
		state.settings.wurst and state.settings.wurst.directory,
		'-out', optimized_script, state.settings.source.jass,
		state.settings.source.directory, optimize)

	if not status then
		return nil, message
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
