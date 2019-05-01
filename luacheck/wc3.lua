local Luacheck = {
	builtin_standards = require ('luacheck.builtin_standards')
}
local Utils = require ('map.utils')

local wc3 = Utils.deep_copy (Luacheck.builtin_standards.lua53)
wc3.read_globals = wc3.read_globals or {}
wc3.globals = wc3.globals or {}

-- Remove Lua 5.3 features not supported by Warcraft III.
do
	wc3.read_globals.debug = nil
	wc3.read_globals.dofile = nil
	wc3.read_globals.io = nil
	wc3.read_globals.loadfile = nil
	wc3.read_globals.os.fields.execute = nil
	wc3.read_globals.os.fields.exit = nil
	wc3.read_globals.os.fields.getenv = nil
	wc3.read_globals.os.fields.remove = nil
	wc3.read_globals.os.fields.rename = nil
	wc3.read_globals.os.fields.setlocale = nil
	wc3.read_globals.os.fields.tmpname = nil
	wc3.read_globals.string.fields.dump = nil
	wc3.read_globals.package = nil
	wc3.read_globals.require = nil
end

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
			wc3.read_globals [id] = empty
		end
	end

	local globals = {
		ids.blizzard.variables
	}

	for _, list in ipairs (globals) do
		for _, id in ipairs (list) do
			wc3.globals [id] = empty
		end
	end
end

-- Add globals expected by Warcraft III in every `war3map.lua`.
do
	wc3.globals.main = empty
	wc3.globals.config = empty
end

-- Add globals introduced by Map.
do
	wc3.read_globals.require = empty
end

return wc3
