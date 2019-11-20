local Objects = require ('map.file.objects')

-- Deals with the `war3map.w3h` (Buffs).
local W3H = {}

function W3H.unpack (input)
	return Objects.unpack (input)
end

function W3H.pack (input)
	return Objects.pack (input)
end

return W3H
