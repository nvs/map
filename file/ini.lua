local Null = require ('map.io.null')
local String = require ('map.string')

-- Details with `*.ini` files.
--
-- Provides very basic and limited functionality.  The purpose is to read
-- the following INI files used within Warcraft III maps:
--
-- - `war3mapSkin.txt`
-- - `war3mapMisc.txt`
-- - `war3mapExtra.txt`
local INI = {}

function INI.unpack (io)
	if not io then
		return nil
	end

	local output = {}
	local current

	local section
	local key, value

	for line in io:lines () do
		line = String.trim_right (line)

		section = line:match ('^%[([^%]]+)%]$')

		if section then
			current = output [section] or {}
			output [section] = current

		elseif not current then -- luacheck: ignore 542
			-- Do nothing.  All key/value pairs must be in a section.

		else
			key, value = line:match ('^([%w_]+)%s-=%s-(.+)$')

			if key and value then
				current [key] = value
			end
		end
	end

	return output
end

function INI.pack (io, input)
	assert (type (input) == 'table')

	if not io then
		return nil
	end

	for section, contents in pairs (input) do
		local count = 0

		-- Increment count only for sections.
		if type (contents) == 'table' then
			for _ in pairs (contents) do
				count = count + 1
			end
		end

		-- Do not write empty sections.
		if count > 0 then
			io:write (('[%s]\r\n'):format (section))

			for key, value in pairs (contents) do
				io:write (('%s=%s\r\n'):format (key, value))
			end

			io:write ('\r\n')
		end
	end

	return true
end

function INI.packsize (input)
	assert (type (input) == 'table')

	local io = Null.open ()

	if not INI.pack (io, input) then
		return nil
	end

	return io:seek ('end')
end

return INI
