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
		os.remove (destination_path)
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

return Path
