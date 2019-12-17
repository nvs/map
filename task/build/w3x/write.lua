local Path = require ('map.path')
local W3X = require ('map.file.w3x')

local files = {
	information = 'war3map.w3i',

	strings = 'war3map.wts',
	regions = 'war3map.w3r',
	cameras = 'war3map.w3c',
	doodads = 'war3map.doo',
	units = 'war3mapUnits.doo',

	unit = 'war3map.w3u',
	item = 'war3map.w3t',
	destructable = 'war3map.w3d',
	doodad = 'war3map.w3b',
	ability = 'war3map.w3a',
	buff = 'war3map.w3h',
	upgrade = 'war3map.w3q',

	interface = 'war3mapSkin.txt',
	gameplay = 'war3mapMisc.txt',
	extra = 'war3mapExtra.txt'
}

local objects = {
	'unit',
	'item',
	'destructable',
	'doodad',
	'ability',
	'buff',
	'upgrade'
}

local constants = {
	'interface',
	'gameplay',
	'extra'
}

-- TODO: Remove this table upon release of 1.32.
local import_bytes = {
	[28] = 21,
	[31] = 29
}

return function (state)
	local map = state.settings.map.output

	Path.remove (map, true)
	do
		local directories = Path.parent (map)
		Path.create_directories (directories)
	end

	if state.settings.map.options.directory then
		Path.create_directory (map)
	end

	local environment = state.environment
	local version = environment.information.version
	local options = {
		import_byte = import_bytes [environment.information.format]
	}

	local input = assert (W3X.open (state.settings.map.input, 'r'))
	local output = assert (W3X.open (map, 'w+', options))

	for name in input:list () do
		if not name:find ('^%(.*%)$') then
			local source = assert (input:open (name))
			local size = source:seek ('end')
			source:seek ('set')
			local destination = assert (output:open (name, 'w', size))

			while true do
				local bytes = source:read (512)

				if not bytes or not destination:write (bytes) then
					break
				end
			end

			assert (source:close ())

			local status, message, code = destination:close ()

			if not status then
				print (status, message, code)
			end
		end
	end

	assert (input:close ())

	do
		for name in pairs (objects) do
			environment [name] = {}
		end

		for id, object in pairs (environment.objects) do
			environment [object.type] [id] = object
		end
	end

	for _, name in ipairs (constants) do
		environment [name] = environment.constants [name]
	end

	for name, path in pairs (files) do
		local library = require ('map.file.' .. path)
		local contents = assert (library.pack (environment [name], version))
		local file = output:open (path, 'w', #contents)
		file:write (contents)
		file:close ()
	end

	do
		assert (environment.information.is_lua)

		output:remove ('war3map.j')
		assert (output:add (state.settings.script.output, 'war3map.lua'))
	end

	for path, name in pairs (environment.imports) do
		assert (output:add (path, name))
	end

	output:close (true)
	io.stdout:write ('Output: ', map, '\n')

	return true
end
