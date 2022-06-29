local WTS = {}

local BOM = '\xEF\xBB\xBF'

function WTS.unpack (input, position)
	if position then
		input = input:sub (position)
	end

	local output = {}
	local pattern = 'STRING (%d+)\r\n(.-){\r\n([^}]-)\r\n}'

	for index, comment, value in input:gmatch (pattern) do
		output [tonumber (index)] = {
			comment = comment:match ('// (.*)\r\n'),
			value = value
		}
	end

	return output, #input + 1
end

function WTS.pack (input)
	local output = {}
	local indices = {}

	for index in pairs (input) do
		indices [#indices + 1] = index
	end

	table.sort (indices)

	for _, index in ipairs (indices) do
		local string = input [index]
		output [#output + 1] = 'STRING ' .. index

		if string.comment then
			output [#output + 1] = '// ' .. string.comment
		end

		output [#output + 1] = '{\r\n' .. string.value .. '\r\n}\r\n'
	end

	return BOM .. table.concat (output, '\r\n') .. '\r\n'
end

return WTS
