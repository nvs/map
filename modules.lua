-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local grammar

do
	local LPeg = require ('lpeg')
	local Re = require ('re')

	local P = LPeg.P
	local S = LPeg.S
	local B = LPeg.B

	local space = ' \f\n\r\t\v'
	local line

	local definitions = {
		eol = P ('\r\n') + P ('\n\r') + S ('\r\n'),
		space = S (space),
		before = B (S ('[({,=' .. space)),

		init = function ()
			line = 1
		end,

		increment = function ()
			line = line + 1
		end,

		peek = function ()
			return line
		end,

		ignore = function ()
		end
	}

	-- This does not represent the complete syntax of Lua.  It does,
	-- however, accurately represent Lua strings and comments.  This allows
	-- finding uses of `require`, without unnecessary false positives.
	--
	-- This is a rather naive check, and will fail if the user does anything
	-- clever with `require`.  In short, use literal `string` if possible.
	-- Nothing else is guaranteed to work properly.
	grammar = Re.compile ([[
		lua <- {} -> init shebang? {| ({| require |} / skip)* |} eof
		skip <- (comment / string / eol / space / .) -> ignore

		eof <- !.
		eol <- %eol {} -> increment
		space <- %space
		shebang <- '#!' (!eol .)*

		open <- '[' {:equals: '='* :} '[' eol?
		close <- ']' =equals ']' / eof
		bracket <- open { (eol / !close .)* } close

		comment <- '--' (bracket / (!eol .)*)

		esc <- '\' ['"]
		string <- bracket
			/ "'" { (esc / !eol !"'" .)* } "'"
			/ '"' { (esc / !eol !'"' .)* } '"'

		before <- %before
		args <- '(' space* string space* ')' / string
		require <- before 'require' space* args {} -> peek
	]], definitions)
end

local function find_requires (path)
	local file = io.open (path, 'rb')
	local contents = file:read ('*a')
	file:close ()

	return grammar:match (contents)
end

local Errors = {}
Errors.__index = Errors

function Errors:__tostring ()
	return 'error:\n\t' .. table.concat (self, '\n\t')
end

function Errors:error (message, ...)
	local prefix = select (2, ...) and '%s:%d:' or 'map:'
	message = prefix .. ' module \'%s\' ' .. message

	self [#self + 1] = string.format (message, ...)
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

function Modules.load (path, package_path)
	local modules = {}
	local errors = setmetatable ({}, Errors)

	find_modules (path, package_path or package.path, modules, errors)

	if #errors > 0 then
		return nil, tostring (errors)
	end

	return modules
end

return Modules
