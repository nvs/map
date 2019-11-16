local LFS = require ('lfs')
local String = require ('map.string')

local Path = {}
Path.separator = package.config:sub (1, 1)

local is_windows = Path.separator == '\\'

if is_windows then
	Path.__index = require ('map.path._windows')
else
	Path.__index = require ('map.path._unix')
end

setmetatable (Path, Path)

-- `Path.separators (path)`
--
-- Returns the directory separators (`string`) for the specified `path`
-- (`string`).  The intended purpose of this result is for it to be used
-- within a set of characters in a pattern.
assert (type (Path.separators) == 'function')

local function attributes (path, mode)
	local pattern = '([' .. Path.separators (path) .. '])$'

	-- On Windows, `stat ()` is 'bugged' with respect to trailing slashes.
	-- Rather than strip them, we just add a dot.  This will work if the
	-- path is a directory.  If not, failure is expected anyway.
	path = path:gsub (pattern, '%1.')

	return LFS.attributes (path, mode)
end

-- Returns a `boolean` indicating whether `path` (`string`) exists.
function Path.exists (path)
	return not not attributes (path, 'mode')
end

-- Returns a `boolean` indicating whether `path` (`string`) is a direcory.
function Path.is_directory (path)
	return attributes (path, 'mode') == 'directory'
end

-- Returns a `boolean` indicating whether `path` (`string`) is a file.
function Path.is_file (path)
	return attributes (path, 'mode') == 'file'
end

-- Returns a `boolean` indicating whether `path` (`string`) contains all
-- permissions listed in `mode` (`string`).  Valid `mode` permissions are
-- `r`, `w`, and `x`.
function Path.has_permissions (path, mode)
	assert (type (mode) == 'string'
		and mode:gsub ('[rxw]', '') == '')

	local permissions = attributes (path, 'permissions')

	if not permissions then
		return false
	end

	for index = 1, #mode do
		local permission = mode:sub (index, index)

		if not permissions:find (permission) then
			return false
		end
	end

	return true
end

-- `Path.root_length (path)`
--
-- Returns the root length (`number`) for the `path` (`string`).  Returns
-- `0` if `path` is not rooted.
assert (type (Path.root_length) == 'function')

-- Returns the root (`string`) for `path` (`string`).  If `path` is not
-- rooted, then the empty string is returned.
function Path.root (path)
	return path:sub (1, Path.root_length (path))
end

-- `Path.is_rooted (path)`
--
-- Returns a `boolean` indicating whether `path` (`string`) has a root.
assert (type (Path.is_rooted) == 'function')

-- `Path.is_relative (path)`
--
-- Returns a `boolean` indicating whether `path` (`string`) is relative.
assert (type (Path.is_relative) == 'function')

-- Returns a `boolean` indicating whther `path` (`string`) is absolute.
function Path.is_absolute (path)
	return not Path.is_relative (path)
end

-- Returns a path (`string`) where all provided `string` components have
-- been joined together.  If a path component is absolute, it truncates the
-- preceding components.  If a path component is the emptry string, it is
-- ignored.  If there are no path components, then the empty string is
-- returned.
function Path.join (...)
	local components = {}

	for index = 1, select ('#', ...) do
		local component = select (index, ...)
		assert (type (component) == 'string')

		if Path.is_absolute (component) then
			components = {}
		elseif component == '' then
			component = nil
		end

		components [#components + 1] = component
	end

	return table.concat (components, Path.separator)
end

-- Attempts to copy the file at `source` (`string`) to `destination`
-- (`string`). Returns 'true' upon success, and `nil` otherwise.
--
-- Note that this function will overwrite existing files, even in failure.
-- And upon failure, no file will be written to `destination`.
function Path.copy (source, destination)
	assert (type (source) == 'string')
	assert (type (destination) == 'string')

	if source == destination then
		return nil
	end

	source = assert (io.open (source, 'rb'))

	if not source then
		return nil
	end

	local destination_path = destination
	destination = assert (io.open (destination, 'wb'))

	if not destination then
		source:close ()
		return nil
	end

	local bytes
	local result

	while true do
		bytes = source:read (512)

		if not bytes then
			result = true
			break
		end

		if not destination:write (bytes) then
			break
		end
	end

	if not destination:close () then
		result = nil
	end

	if not source:close () then
		result = nil
	end

	if not result then
		os.remove (destination_path)
	end

	return result
end

-- Splits the provided `path` (`string`), returning two `string` values that
-- represent the directory and base components.  If `path` contains a root,
-- then it shall always be included as part of the directory component.  In
-- the event that a component does not exist (e.g. `path` terminates in a
-- root or there is no directory compontent), the empty string shall be
-- returned in that compontent's place.
--
-- Note that before processing, all trailing slashes are removed.  And that
-- neither result will contain trailing slashes.  Using `Path.join ()` on
-- the results should yield the original `path` (with trailing slashes
-- removed).
function Path.split (path)
	local root = Path.root (path)

	if path == root then
		return path, ''
	end

	local pattern = '()([' .. Path.separators (root) .. ']+)'
	path = String.trim_right (path:sub (#root + 1), pattern)
	local index, match = path:reverse ():match (pattern)

	if not index then
		index = 1
		match = ''
	else
		index = #path - index  + 2
	end

	return root .. path:sub (1, index - #match - 1), path:sub (index)
end

-- Returns a `string` without the final component of `path` (`string`), if
-- there is one.  If `path` is empty, then `"."` is returned.  Returns
-- `path` if `path` terminates in a root.
function Path.parent (path)
	local directory = Path.split (path)

	if directory == '' then
		directory = '.'
	end

	return directory
end

-- Returns a `string` containing the final component of `path` (`string`),
-- if there is one.  If `path` is empty, then `"."` is returned.  Returns
-- the empty string if `path` terminates in a root.
function Path.base (path)
	local _, base = Path.split (path)

	if base == '' then
		base = '.'
	end

	return base
end

-- Returns the extension (`string`) of the provided `path` (`string`).  This
-- is the suffix beginning at the final period in the final element of the
-- path.  If there is no extension, then the empty string is returned.
function Path.extension (path)
	assert (type (path) == 'string')

	path = Path.base (path)

	if path == '.' or path == '..' then
		return ''
	end

	local index = path:reverse ():find ('.', 1, true)

	if not index then
		return ''
	end

	return path:sub (#path - index + 1)
end

-- `Path.home_directory ()`
--
-- Returns the path (`string`) for the current user's home directory.
-- Returns `nil` if the home directory cannot be discerened.
assert (type (Path.home_directory) == 'function')

-- Returns the path (`string`) for the current working directory.  Returns
-- `nil` upon error.
function Path.current_directory ()
	return LFS.currentdir ()
end

-- Returns a `boolean` indicating whether the current working directory was
-- successfully changed to `path` (`string`).  Returns `nil` upon failure.
function Path.change_directory (path)
	return LFS.chdir (path)
end

-- Returns a `boolean` indicating whether the directory named `path`
-- (`string`) was successfully created.  Returns `nil` upon failure.
function Path.create_directory (path)
	return LFS.mkdir (path)
end

-- Returns a `boolean` indicating whether the directory named `path`
-- (`string`), along with any necessary parents, was successfully created.
-- Returns `nil` upon failure.
function Path.create_directories (path)
	if Path.is_directory (path) then
		return true
	elseif Path.exists (path) then
		return nil, 'invalid argument'
	end

	local status, message, code =
		Path.create_directories (Path.parent (path))

	if not status then
		return nil, message, code
	end

	if Path.is_directory (path) then
		return true
	elseif Path.exists (path) then
		return nil, 'invalid argument'
	end

	return Path.create_directory (path)
end

-- Returns a `boolean` indicating whether the file or directory named `path`
-- (`string`) was successfully removed.  Optionally, takes a flag indicating
-- whether to remove directories and their contents in a `recursive`
-- fashion.  Defaults to not performing recursion.  Returns `nil`, an error
-- message, and a system-dependent error code in case of failure.
function Path.remove (path, recursive)
	if not Path.exists (path)
		or Path.is_file (path)
		or not recursive
	then
		return os.remove (path)
	end

	for entry in LFS.dir (path) do
		if entry ~= '.' and entry ~= '..' then
			entry = Path.join (path, entry)
			Path.remove (entry, true)
		end
	end

	os.remove (path)

	return true
end

-- Returns a `boolean` indicating whether the a link named `name` (`string`)
-- was successfully created referencing the `source` (`string`) object.
-- Optionally, takes a flag indicating whether to create a `symbolic` link.
-- Defaults to creating a hard link.  Returns `nil` upon failure.
function Path.create_link (source, name, symbolic)
	return LFS.link (source, name, symbolic)
end

-- Returns the path (`string`) to a new temporary file.  In general, this
-- function behaves exactly the same as `os.tmpname ()`.
--
-- On Windows, the path will make use of the `TEMP` environment variable.
function Path.temporary_path ()
	local path = os.tmpname ()

	-- Ensure that the returned path is within the `TEMP` environment
	-- variable.  Lua compiled on Windows using MSVC14 will already do this.
	if is_windows and Path.is_relative (path) then
		path = os.getenv ('TEMP') .. path
	end

	return path
end

-- Returns the path (`string`) to a new temporary file.  This function
-- behaves exactly the same as `Path.temporary_path ()`, except that is also
-- attempts to ensure that the file exists.  Returns `nil` upon failure.
--
-- Note that this function provides no security guarantees and is merely
-- provided as a convenience.
function Path.temporary_file ()
	local path = Path.temporary_path ()

	if not Path.exists (path) then
		local file = io.open (path, 'w')

		if file then
			file:close ()
		else
			path = nil
		end
	end

	return path
end

-- Returns the path (`string`) to a new temporary directory.  This function
-- is analogous to `Path.temporary_file ()`, except that it returns a
-- directory and attempts to ensure that it exists.  Returns `nil` upon
-- failure.
--
-- Note that this function provides no security guarantees and is merely
-- provided as a convenience.
function Path.temporary_directory ()
	local path = Path.temporary_path ()

	if Path.exists (path) then
		os.remove (path)
	end

	return Path.create_directory (path) and path or nil
end

return Path
