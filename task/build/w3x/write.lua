local DOO_Doodads = require ('map.file.war3map.doo')
local DOO_Units = require ('map.file.war3mapUnits.doo')
local INI = require ('map.file.ini')
local Path = require ('map.path')
local W3C = require ('map.file.war3map.w3c')
local W3I = require ('map.file.war3map.w3i')
local W3R = require ('map.file.war3map.w3r')
local WTS = require ('map.file.war3map.wts')
local W3X = require ('map.file.w3x')

local objects = {
	unit = 'w3u',
	item = 'w3t',
	destructable = 'w3d',
	doodad = 'w3b',
	ability = 'w3a',
	buff = 'w3h',
	upgrade = 'w3q'
}

local constants = {
	interface = 'war3mapSkin.txt',
	gameplay = 'war3mapMisc.txt',
	extra = 'war3mapExtra.txt'
}

local import_bytes = {
	[0x1C] = 0x15,
	[0x1F] = 0x1D
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

	local version = state.environment.information.version
	local options = {}
	do
		local format = state.environment.information.format
		options.import_byte = import_bytes [format]
	end

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
	local w3x = output

	do
		local contents = W3I.pack (state.environment.information)
		local size = #contents
		local file = assert (w3x:open ('war3map.w3i', 'w', size))
		file:write (contents)
		file:close ()
	end

	do
		local categories = {}

		for name in pairs (objects) do
			categories [name] = {}
		end

		-- Split the unified objects table into its respective categories.
		for id, object in pairs (state.environment.objects) do
			categories [object.type] [id] = object
		end

		for name, extension in pairs (objects) do
			local category = categories [name]
			local path = 'war3map.' .. extension
			local library = require ('map.file.' .. path)
			local contents = assert (library.pack (category))
			local size = #contents

			-- Size of a file with empty original and custom tables.
			if size > 12 then
				local file = assert (w3x:open (path, 'w', size))
				file:write (contents)
				file:close ()
			else
				w3x:remove (path)
			end
		end
	end

	for name, path in pairs (constants) do
		local constant = state.environment.constants [name]

		if constant then
			local contents = INI.pack (constant)
			local size = #contents

			if size > 0 then
				local file = assert (w3x:open (path, 'w', size))
				file:write (contents)
				file:close ()
			else
				w3x:remove (path)
			end
		end
	end

	do
		assert (state.environment.information.is_lua)

		w3x:remove ('war3map.j')
		assert (w3x:add (map .. '.lua', 'war3map.lua'))
	end

	do
		local imports = state.environment.imports

		if type (imports) ~= 'table' then
			imports = {}
		end

		for path, name in pairs (imports) do
			assert (w3x:add (path, name))
		end
	end

	do
		local strings = state.environment.strings

		if type (strings) ~= 'table' then
			strings = {}
		end

		local contents = WTS.pack (strings)
		local size = #contents
		local file = w3x:open ('war3map.wts', 'w', size)
		file:write (contents)
		file:close ()
	end

	do
		local regions = state.environment.regions

		if type (regions) ~= 'table' then
			regions = {}
		end

		local contents = W3R.pack (regions)
		local size = #contents
		local file = w3x:open ('war3map.w3r', 'w', size)
		file:write (contents)
		file:close ()
	end

	do
		local cameras = state.environment.cameras

		if type (cameras) ~= 'table' then
			cameras = {}
		end

		local contents = W3C.pack (cameras, version)
		local size = #contents
		local file = w3x:open ('war3map.w3c', 'w', size)
		file:write (contents)
		file:close ()
	end

	do
		local doodads = state.environment.doodads

		if type (doodads) ~= 'table' then
			doodads = {}
		end

		local contents = DOO_Doodads.pack (doodads, version)
		local size = #contents
		local file = w3x:open ('war3map.doo', 'w', size)
		file:write (contents)
		file:close ()
	end

	do
		local units = state.environment.units

		if type (units) ~= 'table' then
			units = {}
		end

		local contents = DOO_Units.pack (units, version)
		local size = #contents
		local file = w3x:open ('war3mapUnits.doo', 'w', size)
		file:write (contents)
		file:close ()
	end

	w3x:close (true)
	io.stdout:write ('Output: ', map, '\n')

	return true
end
