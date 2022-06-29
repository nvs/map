local Objects = require ('map.file.objects')

local W3Q = {}

function W3Q.unpack (input)
	return Objects.unpack (input, true)
end

function W3Q.pack (input)
	return Objects.pack (input, true)
end

return W3Q
