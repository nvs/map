local Objects = require ('map.file.war3map.objects')

-- Deals with the `war3map.w3h` (Buffs).
local W3H = {}

function W3H.unpack (io)
	return Objects.unpack (io)
end

function W3H.pack (io, input)
	return Objects.pack (io, input)
end

function W3H.packsize (input)
	return Objects.packsize (input)
end

return W3H
