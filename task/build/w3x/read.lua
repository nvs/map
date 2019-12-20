local W3I = require ('map.file.war3map.w3i')
local W3X = require ('map.file.w3x')

local files = {
	strings = 'war3map.wts',
	regions = 'war3map.w3r',
	sounds = 'war3map.w3s',
	cameras = 'war3map.w3c',
	doodads = 'war3map.doo',
	units = 'war3mapUnits.doo',
	terrain = 'war3map.w3e',
	pathing = 'war3map.wpm',

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

local ignored = {
	['war3map.j'] = true,
	['war3map.lua'] = true
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

local default_version = {
	major = 0,
	minor = 0,
	patch = 0,
	build = 0
}

return function (state)
	local input = assert (W3X.open (state.settings.map.input))
	local environment = state.environment

	do
		local file = assert (input:open ('war3map.w3i'))
		local contents = file:read ('*a')
		environment.information = assert (W3I.unpack (contents))
		file:close ()
	end

	environment.imports = {}

	for name in input:list () do
		if not ignored [name] and not name:find ('^%(.*%)$') then
			environment.imports [name] = true
		end
	end

	local version = environment.information.version or default_version
	environment.information.version = version

	for name, path in pairs (files) do
		environment.imports [path] = nil

		if input:has (path) then
			local library = require ('map.file.' .. path)
			local file = assert (input:open (path))
			local contents = file:read ('*a')
			environment [name] = assert (library.unpack (contents, version))
			file:close ()
		else
			environment [name] = {}
		end
	end

	environment.objects = {}

	for _, name in ipairs (objects) do
		local category = environment [name]
		environment [name] = nil

		for id, object in pairs (category) do
			object.type = name
			environment.objects [id] = object
		end
	end

	environment.constants = {}

	for _, name in ipairs (constants) do
		environment.constants [name] = environment [name]
		environment [name] = nil
	end

	do
		local interface = environment.constants.interface
		interface.FrameDef = interface.FrameDef or {}
		interface.CustomSkin = interface.CustomSkin or {}
		interface.Errors = interface.Errors or {}

		local gameplay = environment.constants.gameplay
		gameplay.Misc = gameplay.Misc or {}

		local extra = environment.constants.extra
		extra.MapExtraInfo = extra.MapExtraInfo or {}
	end

	input:close ()

	return true
end
