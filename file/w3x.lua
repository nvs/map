local Imports = require ('map.file.war3map.imp')
local LFS = require ('lfs')
local Path = require ('map.path')
local Storm = require ('stormlib')

-- Deals with `*.w3m` and `*.w3x` files.
local W3X = {}

-- Contains the methods for the W3X metatable (which is basically a wrapper
-- for a [lua-stormlib] MPQ object).
local MPQ = {}
MPQ.__index = MPQ

-- _The returned object provides functionality that differs from that
-- provided by [lua-stormlib].  Refer to that library's documentation for
-- details.  Any differences will be listed, and have been introduced to
-- improve behavior with respect to Warcraft III maps._
--
-- These are the extensions to the Storm MPQ object that have been done for
-- all methods:
--
-- - When referencing files within the archive, names will be internalized.
--   That is, forward slashes will be converted to backslashes.
-- - Management of imports (i.e. files listed in the `war3map.imp`) will be
--   handled automatically, and an updated list will be pushed to the map
--   upon closure.
--
-- Changes specific to a function that are not already covered above will be
-- explicitly listed.
--
-- [lua-stormlib]: https://github.com/nvs/lua-stormlib
function W3X.open (path, mode)
	local mpq, message, code = Storm.open (path, mode)

	if not mpq then
		return nil, message, code
	end

	local imports

	if mpq:has ('war3map.imp') then
		local file
		file, message, code = mpq:open ('war3map.imp')

		if not file then
			return nil, message, code
		end

		imports = Imports.unpack (file)

		if not imports then
			return nil
		end

		file:close ()
	else
		imports = {
			version = 1,
			files = {}
		}
	end

	local self = {
		_mpq = mpq,
		_mode = mode,
		_imports = imports,
		_updated = false
	}

	return setmetatable (self, MPQ)
end

local function to_internal (name)
	return (name:gsub ('/', '\\'))
end

local function to_external (name)
	return (name:gsub ('\\', Path.separator))
end

function MPQ:__tostring ()
	return tostring (self._mpq):gsub ('Storm MPQ', 'Warcraft III: W3X')
end

function MPQ:has (name)
	return self._mpq:has (to_internal (name))
end

function MPQ:list (mask)
	return self._mpq:list (mask and to_internal (mask))
end

-- `w3x:open (name [, mode [, size [, import]]])`
--
-- _This function differs from the one provided by [lua-stormlib]._
--
-- A new optional `import` (`boolean`) argument is now accepted.  This only
-- applies to files opened in `"w"` mode.  Passing `import` indicates that
-- the opened file, if succesfully finished and closed, should be inserted
-- into the `war3map.imp` as an import.
function MPQ:open (name, mode, size, import)
	name = to_internal (name)
	local file, message, code = self._mpq:open (name, mode, size)

	if not file then
		return nil, message, code
	end

	if mode == 'w' and import then
		self._updated = true
		self._imports.files [name] = true
	end

	return file
end

local function add_file (self, path, name, import)
	name = to_internal (name)

	local status, message, code = self._mpq:add (path, name)

	if not status then
		return nil, message, code
	end

	if import then
		self._updated = true
		self._imports.files [name] = true
	end

	return status
end

local function add_directory (self, path, import)
	for entry in LFS.dir (path or '.') do
		if entry ~= '.' and entry ~= '..' then
			local status, message, code

			entry = Path.join (path or '', entry)

			if Path.is_directory (entry) then
				status, message, code = add_directory (self, entry, import)
			else
				status, message, code =
					add_file (self, entry, entry, import)
			end

			if not status then
				return nil, message, code
			end
		end
	end

	return true
end

-- `w3x:add (path [, name_or_import [, import]])`
--
-- _This function differs from the one provided by [lua-stormlib]._
--
-- This function adds the file(s) specified at `path` (`string`) to the
-- map.  Exact behavior depends on the arguments provided.
--
-- If `path` is a file, then it will be added to the map.  If
-- `name_or_import` is provided and is a `string`, then it will repesent the
-- name of the file being added.  If `name_or_import` is a `boolean`, then
-- it is taken to be indicative of the `import` setting, and there is no
-- name argument.  If name is absent, then the default value for name will
-- be `path`.
--
-- If `path` is a directory, then the function will recurse through the
-- files and subdirectories in `path`, adding all files it finds to the
-- map.  The name used for each file will be the relative path in relation
-- to `path`.
--
-- If the optional `import` (`boolean`) is provided the file(s) being added
-- will be inserted into the `war3map.imp`.  This will cause the World
-- Editor to recognize them as imports.  By default, any added file(s) will
-- not be considered imports.
--
-- In case of success, this function returns `true`.  Otherwise, it returns
-- `nil`, a `string` describing the error, and a `number` indicating the
-- error code.
function MPQ:add (path, name_or_import, import)
	local status, message, code

	if Path.is_directory (path) then
		local original = Path.current_directory ()
		status, message, code = Path.change_directory (path)

		if not status then
			return nil, message, code
		end

		import = name_or_import
		status, message, code = add_directory (self, nil, import)

		Path.change_directory (original)
	elseif Path.is_file (path) then
		local name

		if type (name_or_import) == 'string' then
			name = name_or_import
		else
			name = path
			import = name_or_import
		end

		status, message, code = add_file (self, path, name, import)
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
function MPQ:extract (name, path)
	name = to_internal (name)
	local status, message, code = self._mpq:has (name)

	if status == nil then
		return nil, message, code
	elseif not status then
		return nil, 'no such file or directory'
	end

	if not path or Path.is_directory (path) then
		path = Path.join (path or '.', to_external (name))
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

	status, message, code = self._mpq:extract (name, path)

	if not status then
		return nil, message, code
	end

	return path
end

function MPQ:rename (old, new)
	old = to_internal (old)
	new = to_internal (new)

	local status, message, code = self._mpq:rename (old, new)

	if not status then
		return nil, message, code
	end

	if self._imports.files [old] then
		self._updated = true
		self._imports.files [old] = nil
		self._imports.files [new] = true
	end

	return status
end

function MPQ:remove (name)
	name = to_internal (name)

	local status, message, code = self._mpq:remove (name)

	if not status then
		return nil, message, code
	end

	if self._imports.files [name] then
		self._updated = true
		self._imports.files [name] = nil
	end

	return status
end

function MPQ:compact ()
	return self._mpq:compact ()
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
function MPQ:close (compact)
	if not self._mpq then
		return
	end

	if self._mode == 'r' then
		return self._mpq:close ()
	end

	local status, message, code

	if self._updated then
		for name in pairs (self._imports.files) do
			self._imports.files [name] = self._mpq:has (name) or nil
		end

		local file
		local size = Imports.packsize (self._imports)
		file, message, code = self._mpq:open ('war3map.imp', 'w', size)

		if not file then
			return nil, message, code
		end

		if not Imports.pack (file, self._imports) then
			return nil
		end

		file:close ()

		self._updated = false
	end

	if compact then
		status, message, code = self._mpq:compact ()

		if not status then
			return nil, message, code
		end
	end

	return self._mpq:close ()
end

-- Garbage collection will call `map:close ()`.  However, the `compact`
-- argument will not be passed (as no arguments are passed to the `__gc ()`
-- metamethod).
MPQ.__gc = MPQ.close

return W3X
