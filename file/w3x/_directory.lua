local Path = require ('map.path')
local Utils = require ('map.utils')

-- Provides a wrapper around a specific directory, exposing an API to match
-- that provided by [lua-stormlib] for MPQ objects.
--
-- [lua-stormlib]: https://github.com/nvs/lua-stormlib
local Directory = {}
Directory.__index = Directory

local directory_modes = {
	['r'] = true,
	['w+'] = true,
	['r+'] = true
}

function Directory.new (path, mode)
	mode = mode or 'r'
	assert (directory_modes [mode])

	if mode == 'w+' then
		Path.remove (path, true)
		assert (Path.create_directory (path))
	else
		assert (Path.is_directory (path))
	end

	local self = {
		_path = path,
		_read_only = mode == 'r'
	}

	return setmetatable (self, Directory)
end

local function to_internal (name)
	return (name:gsub ('[\\/]+', Path.separator))
end

function Directory:files (pattern, plain)
	local paths = Utils.load_files (self._path, pattern, plain)

	for index, path in ipairs (paths) do
		paths [index] = path:sub (#self._path + 2)
	end

	local index = 0

	return function ()
		index = index + 1
		return paths [index]
	end
end

local file_modes = {
	['r'] = true,
	['rb'] = true,
	['w'] = true,
	['wb'] = true
}

function Directory:open (name, mode)
	mode = mode or 'r'
	assert (file_modes [mode])

	if self._read_only and mode == 'w' then
		return nil, 'permission denied'
	end

	local path = Path.join (self._path, to_internal (name))

	if mode == 'w' or mode == 'wb' then
		local directories = Path.parent (path)
		assert (Path.create_directories (directories))
	end

	return io.open (path, mode)
end

function Directory:remove (name)
	if self._read_only then
		return nil, 'permission denied'
	end

	local path = Path.join (self._path, to_internal (name))

	return os.remove (path)
end

function Directory:rename (old, new)
	if self._read_only then
		return nil, 'permission denied'
	end

	local source = Path.join (self._path, to_internal (old))
	local destination = Path.join (self._path, to_internal (new))

	return os.rename (source, destination)
end

function Directory:compact () -- luacheck: ignore 212
	if self._read_only then
		return nil, 'permission denied'
	end

	return true
end

function Directory:close () -- luacheck: ignore 212
	return true
end

return Directory
