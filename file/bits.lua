-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Bits = {}

local bits = {}

local function prepare (size)
	if #bits >= size - 1 then
		return
	end

	for bit = #bits, size - 1 do
		bits [bit] = math.floor (2 ^ bit)
	end
end

function Bits.pack (input)
	assert (type (input) == 'table')

	local size = #input
	prepare (size)
	local output = 0

	for index = 1, size do
		if input [index] then
			output = output + bits [index - 1]
		end
	end

	return output
end

function Bits.unpack (option, input)
	assert (type (input) == 'number')

	local size = string.packsize (option) * 8
	prepare (size)
	local output = {}

	for index = 1, size do
		local value = bits [index - 1]

		output [index] = input % (value + value) >= value
	end

	return output
end

return Bits
