local Utils = require ('map.utils')
local W3X = require ('map.file.w3x')

local files = {
	information = 'war3map.w3i',

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
	extra = 'war3mapExtra.txt',
}

local function load_file (self, path)
	local input = assert (W3X.open (self.settings.map.input))
	local unpacked

	if input:has (path) then
		local library = require ('map.file.' .. path)
		local file = assert (input:open (path))
		local packed = file:read ('*a')
		local version = path ~= 'war3map.w3i' and self.information.version
		unpacked = assert (library.unpack (packed, version))
		assert (file:close ())
	else
		unpacked = {}
	end

	assert (input:close ())

	return unpacked
end

local default_version = {
	major = 0,
	minor = 0,
	patch = 0,
	build = 0
}

local function setup_information (self)
	local information = load_file (self, files.information)
	information.version = information.version or default_version
	return information
end

local function setup_imports (self)
	local imports = {}
	local input = assert (W3X.open (self.settings.map.input))

	for name in input:list () do
		if not name:find ('^%(.*%)$') then
			imports [name] = true
		end
	end

	return imports
end

local objects = {
	'unit',
	'item',
	'destructable',
	'doodad',
	'ability',
	'buff',
	'upgrade'
}

local function setup_objects (self)
	local _objects = {}

	for _, name in ipairs (objects) do
		local category = load_file (self, files [name])

		for id, object in pairs (category) do
			object.type = name
			_objects [id] = object
		end
	end

	return _objects
end

local constants = {
	'interface',
	'gameplay',
	'extra'
}

local function setup_constants (self)
	local _constants = {}

	for _, name in ipairs (constants) do
		_constants [name] = load_file (self, files [name])
	end

	local interface = _constants.interface
	interface.FrameDef = interface.FrameDef or {}
	interface.CustomSkin = interface.CustomSkin or {}
	interface.Errors = interface.Errors or {}

	local gameplay = _constants.gameplay
	gameplay.Misc = gameplay.Misc or {}

	local extra = _constants.extra
	extra.MapExtraInfo = extra.MapExtraInfo or {}

	return _constants
end

local function setup (self, name)
	return load_file (self, files [name])
end

local loaders = {
	information = setup_information,
	imports = setup_imports,
	objects = setup_objects,
	constants = setup_constants,

	strings = setup,
	regions = setup,
	sounds = setup,
	cameras = setup,
	doodads = setup,
	units = setup,
	terrain = setup,
	pathing = setup
}

local environment = {
	__index = function (self, key)
		local loader = loaders [key]
		local value

		if loader then
			value = loader (self, key)
			rawset (self, key, value)
		else
			value = rawget (self, key)
		end

		return value
	end
}

return function (state)
	state.loaded_files = files
	state.environment = {
		settings = Utils.read_only (Utils.deep_copy (state.settings))
	}

	if state.settings.map then
		setmetatable (state.environment, environment)
		local _ = state.environment.information
	end

	return true
end
