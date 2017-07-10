local Path = require ('map.path')
local Shell = require ('map.shell')

local Grimex = {}

do
	local directory = Path.join ('map', 'external', 'grimex')

	Grimex.file_importer = Path.join (directory, 'FileImporter.exe')
	Grimex.constant_merger = Path.join (directory, 'ConstantMerger.exe')
	Grimex.object_merger = Path.join (directory, 'ObjectMerger.exe')
end

-- This function takes the `output (string)` of the executed Grimex command,
-- and writes it into the file specified by `output_log_path (string)`.
-- Additionally, it appends the contents of the default Grimex log. Returns
-- `true (boolean)` upon success, and `nil` otherwise.
function Grimex.log (output_log_path, output)
	os.remove (output_log_path)
	local output_log = io.open (output_log_path, 'wb')

	if not output_log then
		return nil
	end

	output_log:write (output, '\n')

	local input_log = io.open ('logs/grimex.txt', 'rb')

	if input_log then
		output_log:write (input_log:read ('*a'))
		input_log:close ()
	end

	output_log:close ()

	os.remove ('logs/grimex.txt')
	os.remove ('logs')

	return true
end

-- Runs the Grimex command specified by `executable (string)` upon the
-- provided `map (string)`. If provided, the `prefix (string)` will be
-- prepended to the command line. All other arguments (via `...`) will be
-- appeneded to the command line.
--
-- Returns the status of the command, as either `true (boolean)` or `nil`,
-- along with the `output (string)`.
local function grimex_command (prefix, executable, map, ...)
	local output_log_path = Path.temporary_name ()

	-- Need to capture both 'stdout' and `stderr'.
	local status = Shell.execute {
		command = Shell.escape_arguments (prefix,
			executable, map, 'lookuppaths', ...),
		stdout = Shell.escape_argument (output_log_path),
		stderr = '&1'
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

function Grimex.imports (prefix, map, ...)
	return grimex_command (prefix, Grimex.file_importer, map, ...)
end

function Grimex.constants (prefix, map, ...)
	return grimex_command (prefix, Grimex.constant_merger, map, ...)
end

function Grimex.objects (prefix, map, ...)
	return grimex_command (prefix, Grimex.object_merger, map, ...)
end

return Grimex
