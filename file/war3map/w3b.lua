local Objects = require ('map.file.war3map.objects')

-- Deals with the `war3map.w3b` (Destructables).
local W3B = {}

function W3B.unpack (input)
	return Objects.unpack (input)
end

function W3B.pack (input)
	return Objects.pack (input)
end

return W3B
