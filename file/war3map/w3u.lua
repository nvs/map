local Objects = require ('map.file.objects')

local W3U = {}

local options = {
	has_variations = false
}

function W3U.unpack (input, position)
	return Objects.unpack (input, position, options)
end

function W3U.pack (input)
	return Objects.pack (input, options)
end

return W3U
