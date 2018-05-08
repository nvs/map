-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Bits = {}

function Bits.pack (option, input)
	assert (type (input) == 'table')

	local output = 0
	local size = string.packsize (option) * 8

	for index = 1, size do
		if input [index] then
			output = output + 2 ^ (index - 1)
		end
	end

	return math.floor (output)
end

function Bits.unpack (option, input)
	assert (type (input) == 'number')

	local output = {}
	local size = string.packsize (option) * 8

	for index = 1, size do
		local value = 2 ^ (index - 1)

		output [index] = input % (value + value) >= value
	end

	return output
end

return Bits
