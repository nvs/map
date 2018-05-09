local Objects = require ('map.file.war3map.objects')

-- Deals with the `war3map.w3u` (Units).
local W3U = {}

function W3U.unpack (io)
	return Objects.unpack (io)
end

function W3U.pack (io, input)
	return Objects.pack (io, input)
end

function W3U.packsize (input)
	return Objects.packsize (input)
end

return W3U
