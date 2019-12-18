local Imports = require ('map.file.war3map.imp')
local LFS = require ('lfs')
local Path = require ('map.path')

local Directory = require ('map.file.w3x._directory')
local MPQ = require ('map.file.w3x._mpq')

local Class = {}

local W3X = {}
W3X.__index = W3X

local default_options = {
	-- This remains `nil`, as the `war3map.imp` already provides default
	-- handling when unspecified.
	import_byte = nil
}

-- Files to be ignored and not inserted into the `war3map.imp` as of 1.32.
local ignored = {
	['conversation.json'] = true,
	['war3map.doo'] = true,
	['war3map.j'] = true,
	['war3map.imp'] = true,
	['war3map.lua'] = true,
	['war3map.mmp'] = true,
	['war3map.shd'] = true,
	['war3map.w3a'] = true,
	['war3map.w3b'] = true,
	['war3map.w3c'] = true,
	['war3map.w3d'] = true,
	['war3map.w3e'] = true,
	['war3map.w3h'] = true,
	['war3map.w3i'] = true,
	['war3map.w3q'] = true,
	['war3map.w3r'] = true,
	['war3map.w3s'] = true,
	['war3map.w3t'] = true,
	['war3map.w3u'] = true,
	['war3map.wct'] = true,
	['war3map.wpm'] = true,
	['war3map.wtg'] = true,
	['war3map.wts'] = true,
	['war3mapExtra.txt'] = true,
	['war3mapMap.blp'] = true,
	['war3mapMisc.txt'] = true,
	['war3mapSkin.txt'] = true,
	['war3mapUnits.doo'] = true
}
Class.ignored = ignored

-- _The returned object provides functionality that differs from that
-- provided by [lua-stormlib].  Refer to that library's documentation for
-- details.  Any differences will be listed, and have been introduced to
-- improve behavior with respect to Warcraft III maps._
--
-- These are the extensions to the Storm W3X object that have been done for
-- all methods:
--
-- - When opening an archive, if the specified path is a directory then the
--   returned object will target a directory based W3X.  Otherwise, it will
--   reference a MPQ based object.
-- - When referencing files within the archive, names will be internalized.
--   That is, potential path separators (i.e. `\` and `/`) will be
--   convereted to the operating system dependent path separator for
--   directory archives and to backslashes for MPQ archives.
-- - Management of imports (i.e. files listed in the `war3map.imp`) will be
--   handled automatically, and an updated list will be pushed to the map
--   upon closure.
--
-- Changes specific to a function that are not already covered above will be
-- explicitly listed.
--
-- [lua-stormlib]: https://github.com/nvs/lua-stormlib
function Class.open (path, mode, options)
	local format = Path.is_directory (path) and Directory or MPQ
	local w3x, message, code = format.new (path, mode)

	if not w3x then
		return nil, message, code
	end

	options = options or {}

	for key, value in pairs (default_options) do
		options [key] = options [key] or value
	end

	local self = {
		_w3x = w3x,
		_mode = mode,
		_options = options,
		_updated = false
	}

	return setmetatable (self, W3X)
end

function W3X:__tostring ()
	return tostring (self._w3x):gsub ('Storm W3X', 'Warcraft III: W3X')
end

function W3X:has (name)
	return self._w3x:has (name)
end

function W3X:list (mask)
	return self._w3x:list (mask)
end

function W3X:open (name, mode, size)
	local file, message, code = self._w3x:open (name, mode, size)

	if not file then
		return nil, message, code
	end

	if mode == 'w' and not ignored [name] then
		self._updated = true
	end

	return file
end

local function add_file (self, path, name)
	local status, message, code = self._w3x:add (path, name)

	if not status then
		return nil, message, code
	end

	if not ignored [name or path] then
		self._updated = true
	end

	return status
end

local function add_directory (self, root, path)
	for entry in LFS.dir (path or '.') do
		if entry ~= '.' and entry ~= '..' then
			local status, message, code

			entry = Path.join (path or '', entry)

			if Path.is_directory (entry) then
				status, message, code = add_directory (self, root, entry)
			else
				local name = entry:sub (#root + 2)
				status, message, code = add_file (self, entry, name)
			end

			if not status then
				return nil, message, code
			end
		end
	end

	return true
end

-- `w3x:add (path [, name])`
--
-- _This function differs from the one provided by [lua-stormlib]._
--
-- This function adds the file(s) specified at `path` (`string`) to the
-- map.  Exact behavior depends on the arguments provided.
--
-- If `path` is a file, then it will be added to the map.  If `name` is
-- provided and is a `string`, then it will repesent the name of the file
-- being added.  If name is absent, then the default value for name will be
-- `path`.
--
-- If `path` is a directory, then the function will recurse through the
-- files and subdirectories in `path`, adding all files it finds to the
-- map.  The name used for each file will be the relative path in relation
-- to `path`.
--
-- In case of success, this function returns `true`.  Otherwise, it returns
-- `nil`, a `string` describing the error, and a `number` indicating the
-- error code.
function W3X:add (path, name)
	local status, message, code

	if Path.is_directory (path) then
		status, message, code = add_directory (self, path, path)
	elseif Path.is_file (path) then
		status, message, code = add_file (self, path, name or path)
	else
		status = nil
		message = 'no such file or directory'
	end

	if not status then
		return nil, message, code
	end

	return status
end

-- `w3x:extract (name, [path])`
--
-- _This function differs from the one provided by [lua-stormlib]._
--
-- The argument `path` is now optional.  If absent, it will default to
-- `name` and extract the file to the current directory.  If `path` is a
-- directory, then the file specified by `name` will be extracted within it.
-- If the destination exists and is found to be a file, it will be replaced.
--
-- In case of success, this function will return the path (`string`) of the
-- extracted file.  Otherwise, it returns `nil`, a `string` describing the
-- error, and a `number` indicating the error code.
function W3X:extract (name, path)
	local status, message, code = self._w3x:has (name)

	if status == nil then
		return nil, message, code
	elseif not status then
		return nil, 'no such file or directory'
	end

	if not path or Path.is_directory (path) then
		path = Path.join (path or '.', name:gsub ('\\', Path.separator))
	end

	if Path.is_file (path) then
		os.remove (path)
	end

	if Path.exists (path) then
		return nil, 'invalid argument'
	end

	local directory = Path.parent (path)
	status, message, code = Path.create_directories (directory)

	if not status then
		return nil, message, code
	end

	status, message, code = self._w3x:extract (name, path)

	if not status then
		return nil, message, code
	end

	return path
end

function W3X:rename (old, new)
	local status, message, code = self._w3x:rename (old, new)

	if not status then
		return nil, message, code
	end

	if not ignored [old] then
		self._updated = true
	end

	return status
end

function W3X:remove (name)
	local status, message, code = self._w3x:remove (name)

	if not status then
		return nil, message, code
	end

	if not ignored [name] then
		self._updated = true
	end

	return status
end

function W3X:compact ()
	return self._w3x:compact ()
end

-- `w3x:close ([compact])`
--
-- _This function differs from the one provided by [lua-stormlib]._
--
-- In addition to closing the map, it will push an updated `war3map.imp`
-- that contains all the latest imports.  However, as this is done
-- immediately before closure, it is not possible to cleanup the newly
-- created file.
--
-- Due to this, it takes an optional `compact` (`boolean`) argument, which
-- indicates whether the map should be compacted before closing.  See
-- [lua-stormlib] documentation on `mpq:compact ()`.
function W3X:close (compact)
	if not self._w3x then
		return
	end

	if self._mode == 'r' then
		return self._w3x:close ()
	end

	if self._updated then
		local imports = {
			version = 1,
			files = {}
		}

		for name in self._w3x:list () do
			if not ignored [name] then
				imports.files [name] = self._options.import_byte or true
			end
		end

		local contents = Imports.pack (imports)
		local size = #contents
		local file, message, code =
			self._w3x:open ('war3map.imp', 'w', size)

		if not file then
			return nil, message, code
		end

		file:write (contents)
		file:close ()

		self._updated = false
	end

	if compact then
		local status, message, code = self._w3x:compact ()

		if not status then
			return nil, message, code
		end
	end

	return self._w3x:close ()
end

-- Garbage collection will call `w3x:close ()`.  However, the `compact`
-- argument will not be passed (as no arguments are passed to the `__gc ()`
-- metamethod).
W3X.__gc = W3X.close

return Class
