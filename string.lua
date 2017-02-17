local String = {}

-- Returns the `integer` index within `text (string)` of the last occurrence
-- of the specified `character (string)`.
function String.last_index_of (text, character)
	local character_byte = string.byte (character)

	for index = #text, 1, -1 do
		if text:byte (index) == character_byte then
			return index
		end
	end

	return 0
end

-- Returns a `string` where the specified `character (string`) has been
-- stripped from the end of the `text (string)`.
function String.strip_trailing_character (text, character)
	local character_byte = string.byte (character)

	for index = #text, 1, -1 do
		if text:byte (index) ~= character_byte then
			return text:sub (1, index)
		end
	end

	return ''
end

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
