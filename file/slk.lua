local LPeg = require ('lpeg')
local Re = require ('re')

local SLK = {}

local grammar
do
	local P = LPeg.P
	local row, column, output

	local definitions = {
		eol = P ('\r\n'),
		to_number = tonumber,
		to_boolean = {
			FALSE = false,
			TRUE = true,
		},

		init = function (columns, rows)
			row = nil
			column = nil
			output = {
				rows = tonumber (rows),
				columns = tonumber (columns),
			}
		end,

		output = function ()
			return output
		end,

		row = function (value)
			row = tonumber (value)
			output [row] = output [row] or {}
		end,

		column = function (value)
			column = tonumber (value)
		end,

		data = function (value)
			output [row] [column] = value
		end,

		unsupported = function (value)
			error ('unsupported value "' .. value .. '"')
		end,
	}

	grammar = Re.compile ([[
		SYLK <- ID B -> init C* E eof -> output {}

		ID <- 'ID;PWXL;N;E' eol
		B <- 'B;' X Y 'D0' eol
		C <- 'C;' (X -> column)? (Y -> row)? K eol
		E <- 'E' eol

		X <- 'X' { [0-9]+ } ';'
		Y <- 'Y' { [0-9]+ } ';'
		K <- 'K' (string / number / boolean / error / unsupported) -> data

		string <- '"' { (!'"' .)* } '"'
		number <- ('-'? [0-9]+ ('.' [0-9]*)?) -> to_number
		boolean <- ('TRUE' / 'FALSE') -> to_boolean
		error <- '#VALUE!' / '#REF!'
		unsupported <- (!eol .)* -> unsupported

		eol <- %eol
		eof <- !.
	]], definitions)
end

function SLK.unpack (input, position)
	return grammar:match (input, position)
end

local errors = {
	['#VALUE!'] = true,
	['#REF!'] = true
}

local from_boolean = {
	[true] = 'TRUE',
	[false] = 'FALSE'
}

function SLK.pack (input)
	local output = {
		'ID;PWXL;N;E',
		'B;X' .. input.columns .. ';Y' .. input.rows .. ';D0'
	}

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
						value = from_boolean [value]
					end

					local C

					if row then
						C = 'C;X' .. column .. ';Y' .. row .. ';K' .. value
						row = nil
					else
						C = 'C;X' .. column .. ';K' .. value
					end

					output [#output + 1] = C
				end
			end
		end
	end

	output [#output + 1] = 'E\r\n'
	return table.concat (output, '\r\n')
end

return SLK
