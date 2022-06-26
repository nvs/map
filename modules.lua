-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local LPeg = require ('lpeg')
local Re = require ('re')
local String = require ('map._string')
local Utils = require ('map.utils')

local Modules = {}

local grammar
do
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
		end
	}

	-- This does not represent the complete syntax of Lua.  It should,
	-- however, accurately represent Lua strings and comments.  This allows
	-- finding uses of `require`, without unnecessary false positives.
	--
	-- This is a rather naive check, and will fail if the user does anything
	-- clever with `require`.  In short, use literal `string` if possible.
	-- Nothing else is guaranteed to work properly.
	grammar = Re.compile ([[
		lua <- {} -> init shebang?
			{| require? (before require / skip)* eof |}
		skip <- (comment / string / eol / space / .) -> 0

		eof <- !.
		eol <- %eol -> increment
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
		require <- {| 'require' space* args {} -> peek |}
	]], definitions)
end

local function load_requires (path, options)
	local file = io.open (path)
	local contents = String.trim_right (file:read ('*a'))
	file:close ()

	return grammar:match (contents), options.keep_contents and contents
end

local function load_modules (input, package_path, modules, errors, options)
	local results
	results, input.contents = load_requires (input.path, options)

	for _, result in ipairs (results) do
		local name = result [1]
		local line = result [2]
		local path = package.searchpath (name, package_path)

		if not path then
			errors [#errors + 1] = {
				name = name,
				path = input.path,
				line = line
			}
		elseif not modules [name] then
			local module = {
				name = name,
				path = path
			}

			modules [name] = module
			modules [#modules + 1] = module
			load_modules (module, package_path, modules, errors, options)
		end
	end
end

local function sort_by_name (A, B)
	return A.name < B.name
end

local function format_errors (errors)
	for index, error in ipairs (errors) do
		errors [index] = string.format (
			'%s:%d: %s', error.path, error.line, error.name)
	end

	errors [0] = 'modules not found or using C loader:'
	return table.concat (errors, '\n\t', 0)
end

local default_options = {
	keep_contents = true
}

function Modules.load (name, package_path, options)
	options = Utils.merge_options (options, default_options)
	package_path = package_path or package.path
	local path = package.searchpath (name, package_path)

	if not path then
		return nil, 'module \'' .. name .. '\' not found or uses C loader'
	end

	local root = {
		name = name,
		path = path
	}
	local modules = {
		[0] = root
	}
	local errors = {}

	load_modules (root, package_path, modules, errors, options)

	if #errors > 0 then
		return nil, format_errors (errors)
	end

	for key in pairs (modules) do
		if type (key) == 'string' then
			modules [key] = nil
		end
	end

	table.sort (modules, sort_by_name)
	return modules
end

return Modules
