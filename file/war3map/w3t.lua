local Objects = require ('map.file.objects')

local W3T = {}

local options = {
	has_variations = false
}

function W3T.unpack (input, position)
	return Objects.unpack (input, position, options)
end

function W3T.pack (input)
	return Objects.pack (input, options)
end

return W3T
