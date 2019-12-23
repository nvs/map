local Objects = require ('map.file.objects')

local W3T = {}

function W3T.unpack (input)
	return Objects.unpack (input)
end

function W3T.pack (input)
	return Objects.pack (input)
end

return W3T
