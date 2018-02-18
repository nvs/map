local Path = require ('map.path')
local Shell = require ('map.shell')

local Wurst = {}

local defaults = {
	java = 'java',
	wurst = Path.join (Path.home_directory (), '.wurst')
}

local function execute (java, wurst, ...)
	java = java or defaults.java
	wurst = wurst or defaults.wurst

	assert (type (java) == 'string')
	assert (Path.is_readable (wurst))

	wurst = Path.join (wurst, 'wurstscript.jar')

	local output_path = Path.temporary_name ()

	local status = Shell.execute {
		command = Shell.escape_arguments (java, '-jar', wurst, ...),
		stdout = Shell.escape_argument (output_path),
		stderr = '&1'
	}

	local output = ''
	local output_file = io.open (output_path)

	if output_file then
		output = output_file:read ('*a')
		output_file:close ()

		os.remove (output_path)
	end

	return status, output
end

function Wurst.optimize (java, wurst, script, ...)
	assert (type (script) == 'string')

	return execute (java, wurst, '-out', script,
		'-opt', '-inline', '-localOptimizations', ...)
end

return Wurst
