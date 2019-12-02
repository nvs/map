local Utils = require ('map.utils')

local wc3_lua = require ('map.luacheck.wc3.lua')
local wc3_globals = require ('map.luacheck.wc3.globals')
local wc3 = Utils.deep_copy (wc3_lua)

for key, value in pairs (wc3_globals.read_globals) do
	if not wc3.read_globals [key] then
		wc3.read_globals [key] = value
	end
end

for key, value in pairs (wc3_globals.globals) do
	if not wc3.globals [key] then
		wc3.globals [key] = value
	end
end

return wc3
