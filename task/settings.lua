local LFS = require ('lfs')
local Path = require ('map.path')

local function process_entry (path, extension, list, exists)
	if exists [path] then -- luacheck: ignore 542
		-- Do not process an entry multiple times.
	elseif Path.is_directory (path) then
		for entry in LFS.dir (path) do
			if entry ~= '.' and entry ~= '..' then
				process_entry (Path.join (path, entry),
					extension, list, exists)
			end
		end
	elseif Path.is_file (path)
		and Path.extension (path) == extension
	then
		list [#list + 1] = path
		exists [path] = true
	end
end

local function load_files (paths, extension)
	local list = {}
	local exists = {}

	for _, path in ipairs (paths) do
		process_entry (path, extension, list, exists)

		-- Include any directories, as these will be passed to Wurst.
		if Path.is_directory (path) and not exists [path] then
			exists [path] = true
			list [#list + 1] = path
		end
	end

	return list
end

return function (state)
	state.settings.patch = load_files (state.settings.patch, '.j')
	state.settings.scripts = load_files (state.settings.scripts, '.j')
	state.settings.build = load_files (state.settings.build, '.lua')

	return true
end
