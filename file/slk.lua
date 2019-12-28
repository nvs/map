local SLK = {}

-- Excel errors found in the Warcraft III SLK files.
local errors = {
	['#VALUE!'] = true,
	['#REF!'] = true
}

local is_boolean = {
	FALSE = true,
	TRUE = true
}

local to_boolean = {
	FALSE = false,
	TRUE = true
}

function SLK.unpack (input)
	assert (type (input) == 'string')

	local output = {}

	assert (input:sub (1, 11) == 'ID;PWXL;N;E')

	local row, column
	local _, B = input:find ('[\r\n]+', 12)
	B = B + 1

	while true do
		local record = input:sub (B, B)
		B = B + 2

		if record == 'C' then
			while true do
				local field, value
				_, B, field, value = input:find (
					'([XYK])([^;\r\n]+)[;\r\n]+', B)
				B = B + 1

				if field == 'X' then
					column = tonumber (value)
				elseif field == 'Y' then
					value = tonumber (value)

					row = output [value] or {}
					output [value] = row
				elseif field == 'K' then
					if value:sub (1, 1) == '"' then
						value = tostring (value:sub (2, -2))
					elseif is_boolean [value] then
						value = to_boolean [value]
					elseif errors [value] then -- luacheck: ignore 542
					else
						value = tonumber (value)
					end

					row [column] = value
					break
				end
			end
		elseif record == 'B' then
			while true do
				local field, value
				_, B, field, value = input:find (
					'([XYD])([^;\r\n]+)[;\r\n]+', B)
				B = B + 1

				if field == 'X' then
					output.columns = tonumber (value)
				elseif field == 'Y' then
					output.rows = tonumber (value)
				elseif field == 'D' then
					break
				end
			end
		elseif record == 'E' then
			break
		end
	end

	return output
end

function SLK.pack (input)
	assert (type (input) == 'table')

	local output = {}
	output [#output + 1] = 'ID;PWXL;N;E\r\n'
	output [#output + 1] =
		'B;X' .. input.columns .. ';Y' .. input.rows .. ';D0\r\n'

	local previous_row

	for row = 1, input.rows do
		local rows = input [row]

		if rows then
			for column = 1, input.columns do
				local value = rows [column]

				if value ~= nil then
					local type = type (value)

					if type == 'number' then
						value = ('%.15g'):format (value)
					elseif type == 'string' then
						if not errors [value] then
							value = '"' .. value .. '"'
						end
					elseif type == 'boolean' then
						value = tostring (value):upper ()
					end

					output [#output + 1] = 'C;X'
					output [#output + 1] = column

					if row ~= previous_row then
						previous_row = row

						output [#output + 1] = ';Y'
						output [#output + 1] = row
					end

					output [#output + 1] = ';K'
					output [#output + 1] = value
					output [#output + 1] = '\r\n'
				end
			end
		end
	end

	output [#output + 1] = 'E\r\n'

	return table.concat (output)
end

return SLK
