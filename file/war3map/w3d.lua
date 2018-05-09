local Objects = require ('map.file.war3map.objects')

-- Deals with the `war3map.w3d` (Doodads).
local W3D = {}

function W3D.unpack (io)
	return Objects.unpack (io, true)
end

function W3D.pack (io, input)
	return Objects.pack (io, input, true)
end

function W3D.packsize (input)
	return Objects.packsize (input, true)
end

return W3D
