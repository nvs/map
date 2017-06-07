local Path = require ('map.path')
local Shell = require ('map.shell')

local PJass = {}

PJass.executable = Path.join ('map', 'external', 'pjass', 'pjass.exe')

-- Runs PJass with the provided `options (table)`. If provided, the `prefix
-- (string)` will be prepended to the command line. All other arguments (the
-- scripts) will be appended to the command line.
--
-- Returns the status of the command, as either `true (boolean)` or `nil`,
-- along with the `output (string)`.
function PJass.check (prefix, options, ...)
	local output_log_path = '.' .. os.tmpname ()

	-- The pjass command outputs to `stdout` regardless of its exit status.
	local status = Shell.execute {
		command = Shell.escape_arguments (prefix,
			PJass.executable, options, ...),
		stdout = Shell.escape_argument (output_log_path)
	}

	local output = ''
	local output_log = io.open (output_log_path, 'rb')

	if output_log then
		output = output_log:read ('*a')
		output_log:close ()

		os.remove (output_log_path)
	end

	return status, output
end

return PJass
