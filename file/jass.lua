local Jass = {}

-- Remove Jass comments from the lines of `text` (`string`) and returns the
-- resultant `string`.  If there are no comments, then `text` is returned
-- unmodified.
function Jass.strip_comment (text)
	local output = {}

	for line in text:gmatch ('[^\n]*') do
		local match
		local index = 1

		while index < #line do
			match, index = line:match ('([/\'"])()', index)

			if not match then
				index = #line
				break
			end

			if match == '/' then
				if line:sub (index, index) == '/' then
					index = index - 2
					break
				end
			elseif match then
				local next = line:match ('[^\\]' .. match .. '()', index)

				if not next then
					index = #line
					break
				end

				index = next
			end
		end

		-- As of Lua 5.3.3, the semantics of empty matches has changed.  In
		-- earlier versions, we need to ignore a trailing empty match.
		if #line > 0 then
			output [#output + 1] = line:sub (1, index)
		end
	end

	return table.concat (output, '\n')
end

return Jass
