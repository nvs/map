local Path = require ('map.path')
local Shell = require ('map.shell')

local Wurst = {}

function Wurst.run (...)
	local stdout_path = Path.temporary_path ()

	local status = Shell.execute {
		command = Shell.escape (...),
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
