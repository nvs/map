-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Shell = require ('map.shell')

local function find_requires (path)
	local command = Shell.escape ('luac', '-p', '-l', path)
	local process = assert (io.popen (command))

	local requires = {}
	local state
	local name

	-- This is a rather naive check, and will fail if the user does anything
	-- clever with `require`.  In short, use literal `string` if possible.
	-- Nothing else is guaranteed to work properly.
	for line in process:lines () do
		local number, opcode, value = line:match (
			'^%s+[0-9]+%s+%[([0-9]+)]%s+([A-Z]+)%s+[-0-9%s]+(.*)')

		if not opcode then
			state = nil
		elseif not state then
			if opcode == 'GETTABUP' and value:match ('"require"$')
				or opcode == 'GETGLOBAL' and value:match ('^; require')
			then
				state = 'require'
			end
		elseif state == 'require' then
			state = nil

			if opcode == 'LOADK' then
				name = value:match ('^; "(.*)"%s*$')

				if name then
					state = 'load'
				end
			end
		elseif state == 'load' then
			state = nil

			if opcode == 'CALL' then
				table.insert (requires, { name, number })
			end
		end
	end

	process:close ()

	return requires
end

local Errors = {}
Errors.__index = Errors

function Errors:__tostring ()
	return 'error:\n\t' .. table.concat (self, '\n\t')
end

function Errors:error (message, ...)
	local prefix = select (2, ...) and '%s:%d:' or 'map:'
	message = prefix .. ' module \'%s\' ' .. message

	table.insert (self, string.format (message, ...))
end

local function find_module (name, package_path)
	local path = package.searchpath (name, package_path)
	local message

	if not path then
		message = 'not found or uses C loader'
	end

	return path, message
end

local function find_modules (path, package_path, modules, errors)
	local requires = find_requires (path)

	for _, module in ipairs (requires) do
		local name, line = table.unpack (module)
		local found, message = find_module (name, package_path)

		if found then
			if not modules [name] then
				modules [name] = found
				find_modules (found, package_path, modules, errors)
			elseif found ~= modules [name] then
				message = 'duplicate found'
			end
		end

		if message then
			errors:error (message, path, line, name)
		end
	end
end

local Modules = {}

function Modules.load (state)
	if state.modules then
		return state.modules
	end

	local modules = {}
	local errors = setmetatable ({}, Errors)

	find_modules (
		state.settings.script.input,
		state.settings.script.package_path or package.path,
		modules, errors)

	if #errors > 0 then
		return nil, tostring (errors)
	end

	state.modules = modules

	return modules
end

return Modules
