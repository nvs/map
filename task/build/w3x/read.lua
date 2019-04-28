local INI = require ('map.file.ini')
local W3I = require ('map.file.war3map.w3i')
local WTS = require ('map.file.war3map.wts')
local W3X = require ('map.file.w3x')

local objects = {
	w3u = 'unit',
	w3t = 'item',
	w3d = 'destructable',
	w3b = 'doodad',
	w3a = 'ability',
	w3h = 'buff',
	w3q = 'upgrade'
}

local constants = {
	['war3mapSkin.txt'] = 'interface',
	['war3mapMisc.txt'] = 'gameplay',
	['war3mapExtra.txt'] = 'extra'
}

return function (state)
	local w3x = assert (W3X.open (state.settings.input))

	-- Information.
	do
		local file = assert (w3x:open ('war3map.w3i'))
		state.environment.information = assert (W3I.unpack (file))
		file:close ()
	end

	-- Objects.
	state.environment.objects = {}

	for extension, name in pairs (objects) do
		local path = 'war3map.' .. extension

		if w3x:has (path) then
			local library = require ('map.file.' .. path)
			local file = assert (w3x:open (path))
			local category = assert (library.unpack (file))
			file:close ()

			for id, object in pairs (category) do
				object.type = name
				state.environment.objects [id] = object
			end
		end
	end

	-- Constants.
	state.environment.constants = {}

	for path, name in pairs (constants) do
		if w3x:has (path) then
			local file = assert (w3x:open (path))
			state.environment.constants [name] = assert (INI.unpack (file))
			file:close ()
		else
			state.environment.constants [name] = {}
		end
	end

	-- Load default constants tables.
	do
		local interface = state.environment.constants.interface
		interface.FrameDef = interface.FrameDef or {}
		interface.CustomSkin = interface.CustomSkin or {}
		interface.Errors = interface.Errors or {}

		local gameplay = state.environment.constants.gameplay
		gameplay.Misc = gameplay.Misc or {}

		local extra = state.environment.constants.extra
		extra.MapExtraInfo = extra.MapExtraInfo or {}
	end

	-- Imports.
	state.environment.imports = {}

	-- Strings.
	if w3x:has ('war3map.wts') then
		local file = assert (w3x:open ('war3map.wts'))
		state.strings = assert (WTS.unpack (file))
		file:close ()
	end

	w3x:close ()

	return true
end
