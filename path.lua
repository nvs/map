local String = require ('map.string')

local Path = {}

-- Returns a path (`string`) where all provided `string` arguments have been
-- joined together. All other arguments types are ignored.
function Path.join (...)
	local elements = { ... }

	for index, element in ipairs (elements) do
		if type (element) ~= 'string' then
			elements [index] = ''
		end
	end

	return table.concat (elements, '/')
end

-- Returns a `boolean` indicating whether or not the specified `path (string)`
-- is readable.
function Path.is_readable (path)
	local file = io.open (path, 'rb')

	if not file then
		return false
	end

	file:close ()

	return true
end

-- Attempts to copy the file at `source_path (string)` to `destination_path
-- (string)`. Returns 'true (boolean)' upon success, and `nil` otherwise.
function Path.copy (source_path, destination_path)
	local status
	local source = io.open (source_path, 'rb')

	if source then
		local destination = io.open (destination_path, 'wb')

		if destination then
			destination:write (source:read ('*a'))
			destination:close ()

			status = true
		end

		source:close ()
	end

	return status
end

local directory_separator = package.config:sub (1, 1)

-- Returns the directory (`string`) portion of a `path (string)`. Optionally
-- takes `levels (integer)`, indicating the number levels to remove from the
-- `path` (defaults to `1`).
--
-- Based upon the POSIX.1-2008 utility `dirname ()`; however, the directory
-- separator specified within Lua is used.
function Path.directory_name (path, levels)
	levels = levels or 1

	if type (path) ~= 'string'
		or type (levels) ~= 'number'
	then
		return nil
	end

	if path == '' then
		return '.'
	end

	path = String.strip_trailing_character (path, directory_separator)

	if path == '' then
		return directory_separator
	end

	path = path:sub (1, String.last_index_of (path, directory_separator))

	if path == '' then
		return '.'
	end

	path = String.strip_trailing_character (path, directory_separator)

	if path == '' then
		return directory_separator
	end

	if levels <= 1 then
		return path
	else
		return Path.directory_name (path, levels - 1)
	end
end

-- Returns the non-directory portion (`string`) of a `path (string)`. If
-- provided, an attempt is made to strip a `suffix (string)` from the `path`.
--
-- Based upon the POSIX.1-2008 utility `basename ()`; however, the directory
-- separator specified within Lua is used.
function Path.base_name (path, suffix)
	if type (path) ~= 'string'
		or suffix and type (suffix) ~= 'string'
	then
		return nil
	end

	if path == '' then
		return '.'
	end

	path = String.strip_trailing_character (path, directory_separator)

	if path == '' then
		return directory_separator
	end

	path = path:sub (String.last_index_of (path, directory_separator) + 1)

	if suffix and #suffix > 0
		and path ~= suffix
		and path:sub (-#suffix) == suffix
	then
		return path:sub (1, -#suffix - 1)
	else
		return path
	end
end

return Path
