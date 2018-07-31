local Path = require ('map.path')
local Shell = require ('map.shell')

local Wurst = {}

local defaults = {
	java = 'java',
	wurst = Path.join (Path.home_directory (), '.wurst')
}

function Wurst.run (java, wurst, ...)
	java = java or defaults.java
	wurst = wurst or defaults.wurst

	assert (type (java) == 'string')
	assert (Path.is_directory (wurst))

	local jar = Path.join (wurst, 'wurstscript.jar')
	assert (Path.is_file (jar))

	local stdout_path = Path.temporary_path ()

	local status = Shell.execute {
		command = Shell.escape (java, '-jar', jar, ...),
		stdout = Shell.escape (stdout_path),
		stderr = '&1'
	}

	local output = ''
	local stdout = io.open (stdout_path, 'rb')

	if stdout then
		output = stdout:read ('*a')
		stdout:close ()

		os.remove (stdout_path)
	end

	return status, output
end

return Wurst
