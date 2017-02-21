local Path = require ('map.path')
local Shell = require ('map.shell')

local Optimizer = {}

Optimizer.executable = Path.join (
	'map', 'external', 'optimizer', 'VXJWTSOPT.exe')

-- Runs Vexorian's Optimizer upon the provided `map (string)` with the
-- provided `tweaks (string)`. The resultant map/script will be placed in
-- `output (string)` If provided, the `prefix (string)` will be prepended to
-- the command line.
--
-- Returns the status of the command, as either `true (boolean)` or `nil`.
function Optimizer.optimize (prefix, map, output, tweaks)
	-- The optimizer will fail if the destination already exists.
	os.remove (output)
	os.remove (output .. '.j')

	-- It never writes to either 'stdout' or 'stderr'.
	local status = Shell.execute {
		command = Shell.escape_arguments (prefix,
			Optimizer.executable, map, '--do', output, '--checkall',
			tweaks and '--tweak', tweaks, '--exit')
	}

	-- Remove output upon failure.
	if not status then
		os.remove (output)
		os.remove (output .. '.j')
	end

	return status
end

return Optimizer
