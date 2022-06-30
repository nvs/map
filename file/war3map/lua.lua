local Utils = require ('map.utils')

local Lua = {
	unpack = function () end
}

local default_options = {
	debug = false
}

local debug_sources = {
	name = '=',
	path = '@'
}

-- Expected format:
--
-- ```lua
-- local modules = {
--     {
--         name = 'module.name',
--         path = 'path/to/module/name.lua',
--         contents = 'Module Contents'
--     },
--     -- Additional modules.
-- }
--
-- Modules are expected to be iterable via `ipairs` (i.e. `[1, N]`).  Note
-- that `modules [0]` will represent the 'root' object, and will be included
-- at the end of the output file.  This should probably contain `main` and
-- `config`.
--
-- Note that the output of `Modules.load` using the default options can be
-- passed directly to this function to produce a usable `war3map.lua`.
-- ```
function Lua.pack (input, options)
	options = Utils.merge_options (options, default_options)
	local debug = debug_sources [options.debug]

	local output = {
		[[
package = { -- luacheck: globals package
	loaded = {},
	preload = {}
}

function require (name) -- luacheck: globals require
	if package.loaded [name] == nil then
		local preload = package.preload [name]

		if preload == nil then
			error (string.format ("module '%s' not found: no field"
				.. " package.preload['%s']", name, name))
		end

		package.loaded [name] = preload ()
	end

	return package.loaded [name]
end

]]
	}

	for _, module in ipairs (input) do
		if debug then
			output [#output + 1] = string.format ([[
do -- %s
	package.preload [
		%q
	] = assert (load (

%q

	, %q))
end -- %s

]], module.name, module.name, module.contents,
	debug and debug .. module.path, module.name)
		else
			output [#output + 1] = string.format ([[
do -- %s
	local _ENV = _ENV
	package.preload [
		%q
	] = function (...) -- luacheck: ignore 212
		_ENV = _ENV

%s

	end
end -- %s

]], module.name, module.name, module.contents, module.name)
		end
	end

	output [#output + 1] = input [0].contents
	return table.concat (output)
end

return Lua
