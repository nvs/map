local INI = require ('map.file.ini')
local Path = require ('map.path')
local W3I = require ('map.file.war3map.w3i')
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

return function (state)
	local map = state.settings.output.file
	assert (Path.copy (state.settings.input.map, map))

	local w3x = assert (W3X.open (map, 'r+'))

	-- Information.
	do
		local size = W3I.packsize (state.environment.information)
		local file = assert (w3x:open ('war3map.w3i', 'w', size))
		assert (W3I.pack (file, state.environment.information))
		file:close ()
	end

	-- Objects.
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
			local size = library.packsize (category)

			-- Size of a file with empty original and custom tables.
			if size > 12 then
				local file = assert (w3x:open (path, 'w', size))
				assert (library.pack (file, category))
				file:close ()
			else
				w3x:remove (path)
			end
		end
	end

	-- Constants.
	for name, path in pairs (constants) do
		local constant = state.environment.constants [name]

		if constant then
			local size = INI.packsize (constant)

			if size > 0 then
				local file = assert (w3x:open (path, 'w', size))
				assert (INI.pack (file, constant))
				file:close ()
			else
				w3x:remove (path)
			end
		end
	end

	-- Script.
	do
		assert (state.environment.information.is_lua)

		w3x:remove ('war3map.j')
		assert (w3x:add (map .. '.lua', 'war3map.lua'))
	end

	-- Imports.
	do
		local imports = state.environment.imports

		if type (imports) ~= 'table' then
			imports = {}
		end

		for path, name in pairs (imports) do
			assert (w3x:add (path, name, true))
		end
	end

	-- Strings.
	do
		local strings = state.strings

		if type (strings) ~= 'table' then
			strings = {}
		end

		local size = WTS.packsize (strings)
		local file = w3x:open ('war3map.wts', 'w', size)
		assert (WTS.pack (file, strings))
		file:close ()
	end

	-- Close and compact.
	w3x:close (true)

	-- Report success.
	io.stdout:write ('Output: ', map, '\n')

	return true
end
