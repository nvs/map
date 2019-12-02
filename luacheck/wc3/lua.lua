local Luacheck = {
	builtin_standards = require ('luacheck.builtin_standards')
}
local Utils = require ('map.utils')

local wc3 = Utils.deep_copy (Luacheck.builtin_standards.lua53)
wc3.read_globals = wc3.read_globals or {}
wc3.globals = wc3.globals or {}

-- Remove Lua 5.3 features not supported by Warcraft III.
do
	wc3.read_globals.collectgarbage = nil
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

-- Add globals introduced by Map.
do
	wc3.read_globals.require = empty
	wc3.read_globals.package = {
		fields = {
			loaded = {
				other_fields = true,
				read_only = false
			},
			preload = {
				other_fields = true,
				read_only = false
			}
		}
	}
end

return wc3
