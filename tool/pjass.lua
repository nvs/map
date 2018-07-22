local Path = require ('map.path')
local Shell = require ('map.shell')
local String = require ('map.string')

local PJass = {}

function PJass.run (...)
	local stdout_path = Path.temporary_path ()

	-- PJass outputs to `stdout` regardless of its exit status.
	local status = Shell.execute {
		command = Shell.escape (...),
		stdout = Shell.escape (stdout_path)
	}

	local output = ''
	local stdout = io.open (stdout_path, 'rb')

	if stdout then
		output = stdout:read ('*a')
		stdout:close ()

		os.remove (stdout_path)
	end

	return status, String.trim_right (output)
end

return PJass
