local LFS = require ('lfs')
local Path = require ('map.path')

local Utils = {}

function Utils.merge_options (input, default)
	local output = Utils.copy (default)

	if input then
		for key in pairs (output) do
			if input [key] ~= nil then
				output [key] = input [key]
			end
		end
	end

	return output
end

function Utils.copy (input)
	local output = {}

	for key, value in pairs (input) do
		output [key] = value
	end

	return output
end

local function deep_copy (input, cache)
	if type (input) ~= 'table' then
		return input
	end

	cache = cache or {}
	local cached = cache [input]

	if cached then
		return cached
	end

	local output = {}
	cache [input] = output

	for key, value in next, input do
		output [deep_copy (key, cache)] = deep_copy (value, cache)
	end

	return setmetatable (output, deep_copy (getmetatable (input), cache))
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
