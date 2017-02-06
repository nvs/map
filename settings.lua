local Path = require ('map.path')

local Settings = {}

-- Reads and processes the configuration file specified within `arg [1]`, then
-- returns the settings `table`.
function Settings.read ()
	local chunk, message = loadfile (arg [1])

	if not chunk then
		return chunk, message
	end

	local settings = chunk ()

	-- If prefix is an empty string, we set it to `nil`. This is necessary to
	-- ensure the first command line argument is not an empty string.
	if settings.prefix == '' then
		settings.prefix = nil
	end

	-- Setup the output files.
	settings.output.map = Path.join (
		settings.output.directory, settings.name .. '.w3x')
	settings.output.script = join (
		settings.output.directory, settings.name .. '.j')
	settings.output.globals = Path.join (
		settings.output.directory, 'globals.lua')

	-- Adds patch files to accompany the provided directory, making a 'pair'.
	configuration.patch.files = {
		'common.j',
		'blizzard.j'
	}

	return settings
end

return Settings
