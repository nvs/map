local LFS = require ('lfs')
local Path = require ('map.path')

local Utils = {}

local function deep_copy (old, ignore_metatable)
	local new

	if type (old) == 'table' then
		new = {}

		for key, value in pairs (old) do
			new [deep_copy (key)] = deep_copy (value)
		end

		if not ignore_metatable then
			setmetatable (new, deep_copy (getmetatable (old)))
		end
	else
		new = old
	end

	return new
end
Utils.deep_copy = deep_copy

local function process_entry (path, pattern, plain, list, exists)
	if exists [path] then
		return
	elseif Path.is_directory (path) then
		local entries = {}

		for entry in LFS.dir (path) do
			if entry ~= '.' and entry ~= '..' then
				entries [#entries + 1] = entry
			end
		end

		table.sort (entries)

		for _, entry in ipairs (entries) do
			process_entry (Path.join (path, entry), pattern, plain, list, exists)
		end
	elseif Path.is_file (path)
		and (not pattern or path:find (pattern, 1, plain))
	then
		list [#list + 1] = path
		exists [path] = true
	end
end

function Utils.load_files (paths, pattern, plain)
	local list = {}
	local exists = {}

	if type (paths) == 'string' then
		paths = { paths }
	end

	for _, path in ipairs (paths) do
		process_entry (path, pattern, plain, list, exists)
	end

	return list
end

do
	local proxies = setmetatable ({}, { __mode = 'k' })

	function Utils.read_only (input)
		if type (input) ~= 'table' then
			return input
		end

		local proxy = proxies [input]

		if not proxy then
			proxy = setmetatable ({}, {
				__index = function (_, key)
					return Utils.read_only (input [key])
				end,

				__newindex = function ()
					error ('table is read-only', 2)
				end,

				__pairs = function ()
					local key, value, real_key

					return function ()
						key, value = next (input, real_key)
						real_key = key

						key = Utils.read_only (key)
						value = Utils.read_only (value)

						return key, value
					end
				end,

				__metatable = false
			})

			proxies [input] = proxy
		end

		return proxy
	end
end

return Utils
