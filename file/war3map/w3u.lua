local Objects = require ('map.file.objects')

local W3U = {}

function W3U.unpack (input)
	return Objects.unpack (input)
end

function W3U.pack (input)
	return Objects.pack (input)
end

return W3U
