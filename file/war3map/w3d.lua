local Objects = require ('map.file.objects')

local W3D = {}

local options = {
	has_variations = true
}

function W3D.unpack (input, position)
	return Objects.unpack (input, position, options)
end

function W3D.pack (input)
	return Objects.pack (input, options)
end

return W3D
