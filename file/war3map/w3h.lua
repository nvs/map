local Objects = require ('map.file.objects')

local W3H = {}

function W3H.unpack (input)
	return Objects.unpack (input)
end

function W3H.pack (input)
	return Objects.pack (input)
end

return W3H
