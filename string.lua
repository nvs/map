local String = {}

-- Returns a `string` where contents matching the specified pattern of
-- `characters (string)` have been stripped from the end of `text (string)`.
function String.strip_trailing (text, characters)
	local pattern = '^[' .. characters .. ']'

	for index = #text, 1, -1 do
		if not text:find (pattern, index) then
			return text:sub (1, index)
		end
	end

	return ''
end

return String
