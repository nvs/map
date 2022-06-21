local Objects = require ('map.file.objects')

local W3Q = {}

local options = {
	has_variations = true
}

function W3Q.unpack (input, position)
	return Objects.unpack (input, position, options)
end

function W3Q.pack (input)
	return Objects.pack (input, options)
end

return W3Q
