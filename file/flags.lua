local Flags = {}

function Flags.pack (flags, input)
	assert (type (flags) == 'table')
	assert (type (input) == 'table')

	local output = 0

	for value, flag in pairs (flags) do
		if input [flag] then
			output = output + value
		end
	end

	return output
end

function Flags.unpack (flags, input)
	assert (type (flags) == 'table')
	assert (type (input) == 'number')

	local output = {}

	for value, flag in pairs (flags) do
		output [flag] = input % (value + value) >= value
	end

	return output
end

return Flags
