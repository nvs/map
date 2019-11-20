local Objects = require ('map.file.objects')

-- Deals with the `war3map.w3a` (Abilities).
local W3A = {}

function W3A.unpack (input)
	return Objects.unpack (input, true)
end

function W3A.pack (input)
	return Objects.pack (input, true)
end

return W3A
