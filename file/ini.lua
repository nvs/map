local INI = {}

function INI.unpack (input)
	assert (type (input) == 'string')

	local output = {}
	local current

	if input:sub (1, 3) == '\239\187\191' then
		input = input:sub (4)
	end

	for line in input:gmatch ('[^\r\n]+') do
		line = line:find ('^%s*//') and '' or line
		local section = line:match ('^%[([^%]]+)%]$')

		if section then
			current = output [section] or {}
			output [section] = current

		elseif not current then -- luacheck: ignore 542
			-- Do nothing.  All key/value pairs must be in a section.

		else
			local index = line:find ('=', 1, true)

			if index then
				local key = line:sub (1, index - 1)
				local value = line:sub (index + 1)

				-- Double quotes only apply if the first character of the
				-- value (i.e. that immediately after the equals sign) is
				-- one.  If so, the value is considered to be that which
				-- extends to the first closing double quote or the end of
				-- the line, whichever comes first.
				if value:sub (1, 1) == '"' then
					value = value:match ('^"([^"]*)"?')

				-- Otherwise, we remove any trailing comments.
				else
					value = value:match ('^(.-)//') or value
				end

				current [key] = value
			end
		end
	end

	return output
end

function INI.pack (input)
	assert (type (input) == 'table')

	local output = {}

	for section, contents in pairs (input) do
		output [#output + 1] = '[' .. section .. ']'

		for key, value in pairs (contents) do
			-- Remove trailing comments.  If the user wishes to include `//`
			-- in their value, then they should use double quotes.
			value = value:match ('^(.-)//') or value

			output [#output + 1] = key .. '=' .. value .. ''
		end

		output [#output + 1] = ''
	end

	return table.concat (output, '\r\n')
end

return INI
