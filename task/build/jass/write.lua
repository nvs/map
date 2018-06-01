local PJass = require ('map.tools.pjass')

return function (state)
	local script_path = state.settings.output.file .. '.j'
	local script = assert (io.open (script_path, 'wb'))

	script:write ('globals\n')

	for _, line in ipairs (state.jass.globals) do
		script:write (line, '\n')
	end

	script:write ('endglobals\n')

	for _, line in ipairs (state.jass.non_globals) do
		script:write (line, '\n')
	end

	script:write ('\n')
	script:close ()

	local status, output = PJass.run (state.settings.pjass,
		state.settings.patch, script_path)

	if not status then
		return nil, output
	end

	io.stdout:write ('- ', script_path, '\n')

	return true, output
end
