local Objects = require ('map.file.objects')

local W3B = {}

function W3B.unpack (input)
	return Objects.unpack (input)
end

function W3B.pack (input)
	return Objects.pack (input)
end

return W3B
