local Path = require ('map.path')
local Wurst = require ('map.tool.wurst')

return function (state)
	if state.settings.source.directory ~= 'wurst' then
		-- Note that LFS cannot accurately detect a symbolic link on
		-- Windows.  As such, we only attempt to remove directories.
		if Path.is_directory ('wurst') then
			assert (os.remove ('wurst'))
		end

		assert (Path.create_link (
			state.settings.source.directory, 'wurst', true))
	end

	local dependencies = state.settings.wurst
		and state.settings.wurst.dependencies

	if dependencies and #dependencies > 0 then
		local file = assert (io.open ('wurst.dependencies', 'w'))

		for _, path in ipairs (dependencies) do
			if Path.is_relative (path) then
				path = Path.join (Path.current_directory (), path)
			end

			file:write (path, '\n')
		end

		file:close ()
	end

	local script_path = state.settings.output.files.build .. '.j'
	local status, message = Wurst.run (state.settings.java,
		state.settings.wurst and state.settings.wurst.directory,
		'-out', script_path, state.settings.source.jass,
		state.settings.source.directory, '-runcompiletimefunctions')

	if not status then
		return nil, message
	end

	io.stdout:write ('- ', script_path, '\n')

	return true
end
