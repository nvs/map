local WTS = {}

function WTS.unpack (input)
	assert (type (input) == 'string')

	local output = {}
	local pattern = 'STRING (%d+).-{\r?\n?(.-)\r?\n?}'

	for index, text in input:gmatch (pattern) do
		output [tonumber (index)] = text:gsub ('\r\n', '\n')
	end

	return output
end

function WTS.pack (input)
	assert (type (input) == 'table')

	local output = {}
	local indices = {}

	for index in pairs (input) do
		indices [#indices + 1] = index
	end

	table.sort (indices)

	for _, index in ipairs (indices) do
		output [#output + 1] = string.format (
			'STRING %d\r\n{\r\n%s\r\n}\r\n\r\n',
			index, input [index]:gsub ('([^\r])\n', '%1\r\n'))
	end

	return table.concat (output, '\r\n')
end

return WTS
