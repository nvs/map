local String = {}

local function trim (text, left, right, pattern)
	assert (type (text) == 'string')

	if pattern == nil then
		pattern = '%s+'
	end

	assert (type (pattern) == 'string')

	if text == '' then
		return ''
	end

	pattern = '^' .. pattern

	if left then
		local _, index = text:find (pattern)

		if index and index > 0 then
			text = text:sub (index + 1)
		end
	end

	if right and text ~= '' then
		local _, index = text:reverse ():find (pattern)

		if index and index > 0 then
			text = text:sub (1, #text - index)
		end
	end

	return text
end

-- Removes leading characters from `text` (`string`) that match an optional
-- non-anchored `pattern` (`string`) and returns the resultant `string`.  If
-- `pattern` is not provided, then white space (i.e. `%s+`) is removed.
function String.trim_left (text, pattern)
	return trim (text, true, false, pattern)
end

-- Removes trailing characters from `text` (`string`) that match an optional
-- non-anchored `pattern` (`string`) and returns the resultant `string`.  If
-- `pattern` is not provided, then white space (i.e. `%s+`) is removed.
function String.trim_right (text, pattern)
	return trim (text, false, true, pattern)
end

-- Removes leading and trailing characters from `text` (`string`) that match
-- an optional non-anchored `pattern` (`string`) and returns the resultant
-- `string`.  If `pattern` is not provided, then white space (i.e. `%s+`) is
-- removed.
function String.trim (text, pattern)
	return trim (text, true, true, pattern)
end

return String
