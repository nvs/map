local Objects = require ('map.file.objects')

local W3D = {}

function W3D.unpack (input)
	return Objects.unpack (input, true)
end

function W3D.pack (input)
	return Objects.pack (input, true)
end

return W3D
