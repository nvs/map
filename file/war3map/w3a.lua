local Objects = require ('map.file.war3map.objects')

-- Deals with the `war3map.w3u` (Abilities).
local W3A = {}

function W3A.unpack (io)
	return Objects.unpack (io, true)
end

function W3A.pack (io, input)
	return Objects.pack (io, input, true)
end

function W3A.packsize (input)
	return Objects.packsize (input, true)
end

return W3A
