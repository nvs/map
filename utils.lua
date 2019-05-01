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

local function process_entry (path, extension, list, exists)
	if exists [path] then -- luacheck: ignore 542
		-- Do not process an entry multiple times.
	elseif Path.is_directory (path) then
		local entries = {}

		for entry in LFS.dir (path) do
			if entry ~= '.' and entry ~= '..' then
				table.insert (entries, entry)
			end
		end

		table.sort (entries)

		for _, entry in ipairs (entries) do
			process_entry (Path.join (path, entry), extension, list, exists)
		end
	elseif Path.is_file (path)
		and Path.extension (path) == extension
	then
		list [#list + 1] = path
		exists [path] = true
	end
end

function Utils.load_files (paths, extension)
	local list = {}
	local exists = {}

	for _, path in ipairs (paths) do
		process_entry (path, extension, list, exists)
	end

	return list
end

return Utils
