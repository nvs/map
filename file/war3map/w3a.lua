local Objects = require ('map.file.objects')

local W3A = {}

local options = {
	has_variations = true
}

function W3A.unpack (input, position)
	return Objects.unpack (input, position, options)
end

function W3A.pack (input)
	return Objects.pack (input, options)
end

return W3A
