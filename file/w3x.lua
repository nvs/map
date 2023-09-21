local Imports = require ('map.file.war3map.imp')
local Path = require ('map.path')

local Directory = require ('map.file.w3x._directory')
local MPQ = require ('map.file.w3x._mpq')

local Class = {}

local W3X = {}
W3X.__index = W3X

-- Options are only for the creation of a new archive (i.e. `w+` mode).
local default_options = {
	-- Can be either `directory` or `mpq`.
	type = nil,

	-- This is the value for 1.31.
	import_byte = 21
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

local modes = {
	['r'] = true,
	['w+'] = true,
	['r+'] = true
}

-- _The returned object provides an API similar to that provided by
-- [lua-stormlib].  However, there are differences._
--
-- These are the extensions that have been done for all methods:
--
-- - When opening an archive, if the specified path is a directory then the
--   returned object will target a directory based archive.  Otherwise, it
--   will reference a MPQ based one.  Note that an option can be passed that
--   will override this detection.
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
	mode = mode or 'r'

	if not modes [mode] then
		return nil, 'invalid mode'
	end

	options = options or {}

	for key, value in pairs (default_options) do
		options [key] = options [key] or value
	end

	local is_directory

	if options.type == 'directory' then
		is_directory = true
	elseif options.type == 'mpq' then
		is_directory = false
	else
		is_directory = Path.is_directory (path)
	end

	local format = is_directory and Directory or MPQ
	local w3x, message, code = format.new (path, mode)

	if not w3x then
		return nil, message, code
	end

	local self = {
		_w3x = w3x,
		_mode = mode,
		_options = options,
		_updated = false
	}

	return setmetatable (self, W3X)
end

function W3X:files (...)
	return self._w3x:files (...)
end

function W3X:open (name, mode, size)
	mode = mode or 'r'
	local file, message, code = self._w3x:open (name, mode, size)

	if not file then
		return nil, message, code
	end

	if mode:find ('^w') and not ignored [name] then
		self._updated = true
	end

	return file
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

	local w3x = self._w3x
	self._w3x = nil

	if self._mode == 'r' then
		return w3x:close ()
	end

	if self._updated then
		local imports = {
			format = 1,
			files = {}
		}

		for name in w3x:files () do
			if not ignored [name] then
				imports.files [name] = self._options.import_byte
			end
		end

		local contents = Imports.pack (imports)
		local size = #contents
		local file, message, code = w3x:open ('war3map.imp', 'wb', size)

		if not file then
			return nil, message, code
		end

		file:write (contents)
		file:close ()

		self._updated = false
	end

	if compact then
		local status, message, code = w3x:compact ()

		if not status then
			return nil, message, code
		end
	end

	return w3x:close ()
end

-- Garbage collection will call `w3x:close ()`.  However, the `compact`
-- argument will not be passed (as no arguments are passed to the `__gc ()`
-- metamethod).
W3X.__gc = W3X.close

return Class
