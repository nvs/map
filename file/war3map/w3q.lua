local Objects = require ('map.file.war3map.objects')

-- Deals with the `war3map.w3q` (Upgrades).
local W3Q = {}

function W3Q.unpack (io)
	return Objects.unpack (io, true)
end

function W3Q.pack (io, input)
	return Objects.pack (io, input, true)
end

function W3Q.packsize (input)
	return Objects.packsize (input, true)
end

return W3Q
