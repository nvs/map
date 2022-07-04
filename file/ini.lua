local LPeg = require ('lpeg')
local Re = require ('re')

local INI = {}

local grammar
do
	local P = LPeg.P

	local definitions = {
		eol = P ('\r\n') + P ('\n'),
        bom = P ('\xEF\xBB\xBF'),
		set = rawset
	}

	grammar = Re.compile ([[
		INI <- bom? ({||} contents*) ~> set eof {}
		contents <- eol / comment / section / skip

		section <- {: header ({||} body*) ~> set :}
		header <- '[' name ']'
		name <- { (!']' !eol .)+ }
		body <- eol / comment / pair

		pair <- {: key '=' value :}
		key <- { (!'=' !eol .)+ }
		value <- quoted / unquoted

		quoted <- { singles / doubles } skip*
		unquoted <- { (!eol .)* }

		singles <- single (',' single)*
		single <- "'" (!"'" !eol .)* "'"

		doubles <- double (',' double)*
		double <- '"' (!'"' !eol .)* '"'

		comment <- '//' (!eol . )*
		skip <- !eol .
		bom <- %bom
		eol <- %eol
		eof <- !.
	]], definitions)
end

function INI.unpack (input, position)
	return grammar:match (input, position)
end

function INI.pack (input)
	local output = {}

	for section, contents in pairs (input) do
		output [#output + 1] = '[' .. section .. ']'

		for key, value in pairs (contents) do
			output [#output + 1] = key .. '=' .. value
		end

		output [#output + 1] = ''
	end

	return table.concat (output, '\r\n')
end

return INI
