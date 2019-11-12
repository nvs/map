local Null = require ('map.io.null')
local String = require ('map.string')

local WTS = {}

function WTS.unpack (io)
	local output = {}

	local count = 0
	local text
	local index

	for line in io:lines () do
		if count > 0 then
			if line:find ('^%s*{%s*$') then
				count = count + 1
			elseif line:find ('^%s*}%s*$') then
				count = count - 1
			end

			if count > 0 then
				text [#text + 1] = String.trim_right (line, '[\r\n]+')
			else
				output [index] = table.concat (text, '\n')
				text = nil
			end
		elseif text and line:find ('^%s*{%s*') then
			count = count + 1
		elseif not text then
			index = tonumber (line:match ('^%s*STRING%s*(%d+)%s*$'))

			if index then
				count = 0
				text = {}
			end
		end
	end

	return output
end

function WTS.pack (io, input)
	assert (type (input) == 'table')

	local indices = {}

	for index in pairs (input) do
		indices [#indices + 1] = index
	end

	table.sort (indices)

	for _, index in ipairs (indices) do
		io:write (string.format ('STRING %d\r\n{\r\n%s\r\n}\r\n\r\n',
			index, input [index]:gsub ('([^\r])\n', '%1\r\n')))
	end

	return true
end

function WTS.packsize (input)
	assert (type (input) == 'table')

	local io = Null.open ()

	if not WTS.pack (io, input) then
		return nil
	end

	return io:seek ('end')
end

return WTS
