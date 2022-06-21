local Objects = require ('map.file.objects')

local W3B = {}

local options = {
	has_variations = false
}

function W3B.unpack (input, position)
	return Objects.unpack (input, position, options)
end

function W3B.pack (input)
	return Objects.pack (input, options)
end

return W3B
