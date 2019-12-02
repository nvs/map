local wc3_globals = {
	read_globals = {},
	globals = {}
}

local empty = {}

-- Add globals provided by Warcraft III (i.e. the `common.j`, the
-- `blizzard.j`, and natives from the `common.ai`).  Also includes globals
-- not present within these files.
do
	local ids = require ('map.wc3.ids')

	local read_globals = {
		ids.ai.natives,
		ids.common.constants,
		ids.common.natives,
		ids.blizzard.constants,
		ids.blizzard.functions,
		ids.unknown.dzapi,
		ids.unknown.other
	}

	for _, list in ipairs (read_globals) do
		for _, id in ipairs (list) do
			wc3_globals.read_globals [id] = empty
		end
	end

	local globals = {
		ids.blizzard.variables
	}

	for _, list in ipairs (globals) do
		for _, id in ipairs (list) do
			wc3_globals.globals [id] = empty
		end
	end
end

-- Add globals expected by Warcraft III in every `war3map.lua`.
do
	wc3_globals.globals.main = empty
	wc3_globals.globals.config = empty
end

return wc3_globals
