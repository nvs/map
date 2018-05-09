local Objects = require ('map.file.war3map.objects')

-- Deals with the `war3map.w3t` (Items).
local W3T = {}

function W3T.unpack (io)
	return Objects.unpack (io)
end

function W3T.pack (io, input)
	return Objects.pack (io, input)
end

function W3T.packsize (input)
	return Objects.packsize (input)
end

return W3T
