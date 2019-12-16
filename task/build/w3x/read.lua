local INI = require ('map.file.ini')
local W3C = require ('map.file.war3map.w3c')
local W3I = require ('map.file.war3map.w3i')
local W3R = require ('map.file.war3map.w3r')
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

local default_version = {
	major = 0,
	minor = 0,
	patch = 0,
	build = 0
}

return function (state)
	local w3x = assert (W3X.open (state.settings.map.input))

	do
		local file = assert (w3x:open ('war3map.w3i'))
		local contents = file:read ('*a')
		state.environment.information = assert (W3I.unpack (contents))
		file:close ()
	end

	local version = state.environment.information.version or default_version
	state.environment.information.version = version
	state.environment.objects = {}

	for extension, name in pairs (objects) do
		local path = 'war3map.' .. extension

		if w3x:has (path) then
			local library = require ('map.file.' .. path)
			local file = assert (w3x:open (path))
			local contents = file:read ('*a')
			local category = assert (library.unpack (contents))
			file:close ()

			for id, object in pairs (category) do
				object.type = name
				state.environment.objects [id] = object
			end
		end
	end

	state.environment.constants = {}

	for path, name in pairs (constants) do
		if w3x:has (path) then
			local file = assert (w3x:open (path))
			local contents = file:read ('*a')
			state.environment.constants [name] =
				assert (INI.unpack (contents))
			file:close ()
		else
			state.environment.constants [name] = {}
		end
	end

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

	state.environment.imports = {}
	state.environment.strings = {}

	if w3x:has ('war3map.wts') then
		local file = assert (w3x:open ('war3map.wts'))
		local contents = file:read ('*a')
		state.environment.strings = assert (WTS.unpack (contents))
		file:close ()
	end

	state.environment.regions = {}

	if w3x:has ('war3map.w3r') then
		local file = assert (w3x:open ('war3map.w3r'))
		local contents = file:read ('*a')
		state.environment.regions = assert (W3R.unpack (contents))
		file:close ()
	end

	state.environment.cameras = {}

	if w3x:has ('war3map.w3c') then
		local file = assert (w3x:open ('war3map.w3c'))
		local contents = file:read ('*a')
		state.environment.cameras = assert (W3C.unpack (contents, version))
		file:close ()
	end

	w3x:close ()

	return true
end
