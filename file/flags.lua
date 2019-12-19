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

function Flags.unpack (flags, input, ignore)
	assert (type (flags) == 'table')
	assert (type (input) == 'number')

	local output = {}

	for value, flag in pairs (flags) do
		local result = input % (value + value) >= value
		output [flag] = result

		if result then
			input = input - value
		end
	end

	assert (ignore or input == 0)

	return output
end

return Flags
