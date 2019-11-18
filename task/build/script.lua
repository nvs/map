local Modules = require ('map.modules')
local Path = require ('map.path')
local Shell = require ('map.shell')
local String = require ('map.string')

local function write_header (output)
	assert (output:write ([[
local package = {
	loaded = {},
	preload = {}
}

function require (name) -- luacheck: globals require
	if package.loaded [name] == nil then
		local preload = package.preload [name]

		if preload == nil then
			error (string.format ("module '%s' not found: no field"
				.. " package.preload['%s']", name, name))
		end

		package.loaded [name] = preload ()
	end

	return package.loaded [name]
end

]]))
end

local function read_contents (path)
	local file = assert (io.open (path, 'rb'))
	local contents = String.trim (assert (file:read ('*a')), '[\r\n]+')
	file:close ()

	return contents
end

local function write_module (output, path, name, debug)
	local contents = read_contents (path)

	if debug then
		debug = debug .. (debug == '@' and path or name)
	end

	if debug then
		assert (output:write (string.format ([[
do -- %s
	package.preload [%q] = assert (load (

%q

	, %q))
end -- %s

]], name, name, contents, debug, name)))
	else
		assert (output:write (string.format ([[
do -- %s
	local _ENV = _ENV
	-- luacheck: ignore 212
	package.preload [%q] = function (...)
	-- luacheck: enable 212
		_ENV = _ENV

%s

	end
end -- %s

]], name, name, contents, name)))
	end
end

local function write_footer (output, path)
	assert (output:write (read_contents (path)))
end

return function (state)
	local modules, message = Modules.load (state)

	if not modules then
		error (message)
	end

	local names = {}

	for name in pairs (modules) do
		table.insert (names, name)
	end

	table.sort (names)

	local debug = state.settings.script.options.debug

	if debug then
		if debug == true then
			debug = 'path'
		end

		if debug == 'path' then
			debug = '@'
		elseif debug == 'name' then
			debug = '='
		else
			error ('invalid `debug` mode specified')
		end
	end

	local path = state.settings.script.output
	do
		local directories = Path.parent (path)
		Path.create_directories (directories)
	end
	local output = assert (io.open (path, 'wb'))

	write_header (output)

	for _, name in ipairs (names) do
		write_module (output, modules [name], name, debug)
	end

	write_footer (output, state.settings.script.input)

	output:close ()

	if not state.settings.script.options.skip_check then
		local status = Shell.execute {
			command = Shell.escape (
				'luacheck', '--default-config',
				Path.join ('map', 'luacheck', 'luacheckrc'),
				'--quiet', path)
		}

		if not status then
			return
		end
	end

	io.stdout:write ('\nOutput: ', path, '\n')

	return true
end
