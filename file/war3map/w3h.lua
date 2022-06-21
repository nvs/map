local Objects = require ('map.file.objects')

local W3H = {}

local options = {
	has_variations = false
}

function W3H.unpack (input, position)
	return Objects.unpack (input, position, options)
end

function W3H.pack (input)
	return Objects.pack (input, options)
end

return W3H
