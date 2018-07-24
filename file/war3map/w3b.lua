local Objects = require ('map.file.war3map.objects')

-- Deals with the `war3map.w3b` (Destructables).
local W3B = {}

function W3B.unpack (io)
	return Objects.unpack (io)
end

function W3B.pack (io, input)
	return Objects.pack (io, input)
end

function W3B.packsize (input)
	return Objects.packsize (input)
end

return W3B
