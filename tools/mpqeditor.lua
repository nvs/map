local Path = require ('map.path')
local Shell = require ('map.shell')

local MPQEditor = {}

MPQEditor.executable = Path.join (
	'map', 'external', 'mpqeditor', 'MPQEditor.exe')

-- Exports `file (string)` from the specified `map (string)` into the
-- provided `directory (string)`. Optionally takes a `prefix (string)` to
-- place before the executed command. Returns `true (boolean)` upon success,
-- or `nil` upon failure.
function MPQEditor.export (map, file, directory, prefix)
	local path = Path.join (directory, file)

	os.remove (path)

	-- The MPQ Editor never seems to return a status other than success, nor
	-- does it seem to write to either 'stdout' or 'stderr'.
	Shell.execute {
		command = Shell.escape_arguments (prefix, MPQEditor.executable,
			'extract', map, file, directory, '/fp')
	}

	if Path.is_readable (path) then
		return path
	else
		return nil
	end
end

function MPQEditor.flush (map, prefix)
	Shell.execute {
		command = Shell.escape_arguments (
			prefix, MPQEditor.executable, 'flush', map)
	}

	return true
end

return MPQEditor
