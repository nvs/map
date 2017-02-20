local Grimex = require ('map.tools.grimex')
local MPQEditor = require ('map.tools.mpqeditor')
local String = require ('map.string')

local WTS = {}

-- Returns a `table` containing the contents of the trigger strings data from
-- the specified `map (string)`. The contents are accessed by their
-- cooresponding index. If a matching string object was found, then the
-- `string` text will be available. Otherwise, `false` will be returned.
-- Comments are strictly ignored. Returns `nil` if an error was encountered.
function WTS.process (map, directory, prefix)
	local file_path = MPQEditor.export (map, 'war3map.wts', directory, prefix)

	if not file_path then
		return nil
	end

	local file = io.open (file_path, 'rb')

	if not file then
		return nil
	end

	-- The World Editor adds a UTF-8 BOM upon exporting strings. Skip it.
	if file:read (3) ~= '\239\187\191' then
		file:seek ('set', 0)
	end

	local strings = {}
	local count = 0

	local text
	local index

	-- A trigger string has the following format.
	--
	-- ```
	-- STRING 0
	-- // A comment.
	-- {
	-- Text
	-- }
	-- ```
	for line in file:lines () do
		line = String.strip_trailing (line, '\r')

		if count > 0 then
			if line:match ('^%s*{.*$') then
				count = count + 1
			elseif line:match ('^%s*}.*$') then
				count = count - 1
			else
				table.insert (text, line)
			end

			if count == 0 then
				strings [index] = table.concat (text, '\n')
				text = nil
			end
		elseif text and line:match ('^%s*{.*') then
			count = count + 1
		elseif not text then
			index = tonumber (line:match ('^%s*STRING%s*(%d+).*$'))

			if index then
				while #strings < index - 1 do
					strings [#strings + 1] = false
				end

				count = 0
				text = {}
			end
		end
	end

	file:close ()
	os.remove (file_path)

	return strings
end

-- Takes the provided `strings (table)` and updates the trigger string data
-- for the specified `map (string)`. Returns `nil` if an error is encountered.
function WTS.write (map, strings, prefix)
	local file_path = os.tmpname ()
	local file = io.open (file_path, 'wb')

	local status

	if file then
		for index, object in ipairs (strings) do
			if object then
				-- Although only necessary after the string index, carriage
				-- returns are added before every line feed. This ensures better
				-- consistency with the strings exported by the World Editor.
				file:write (string.format ('STRING %d\r\n{\r\n%s\r\n}\r\n\r\n',
					index, object:gsub ('([^\r])\n', '%1\r\n')))
			end
		end

		file:close ()

		status = Grimex.imports (prefix, map, file_path, 'war3map.wts')

		os.remove (file_path)
	end

	return status
end

return WTS
