-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local IO = {}

local replacements = {
	['s'] = 'i',
	['z'] = 'x'
}

-- Returns a `boolean` indicating whether `options` (a `string`) is a valid
-- format string.
local function is_format_string (options)
	-- We replace variable options `s` and `z` with temporary stand-ins to
	-- satisfy `string.packsize ()`.
	return not not pcall (string.packsize,
		options:gsub ('[sz]', replacements))
end

local is_endianness = {
	['<'] = true,
	['>'] = true,
	['='] = true
}

-- Returns an interator `function` that, each time it is called, returns
-- the padding (a `number)` and the format (a `string)` for the next
-- non-configuration style option present within `options` (a `string`).
-- Note that format may include endianness (but never alignment).
--
-- ``` lua
-- for padding, format in each_option (io, options) do
--     -- Use `padding` and `format` here.
-- end
-- ```
--
-- The accuracy of the returned results hinges on whether the returned
-- padding and format are used to advanced through the `io` stream as
-- alignment is processed on every format option.
-- ```
local function each_option (io, options)
	local endianness = ''
	local maximum_alignment = 1

	return coroutine.wrap (function ()
		for empty, format, option, size in
			options:gmatch (' *(X?)(([<>=!xbBhHlLTiIfdjJncsz])(%d*))')
		do
			-- No more options.
			if not empty then
				return nil
			end

			empty = #empty > 0 and empty or nil

			-- Endianness.
			if is_endianness [option] then
				endianness = option

			-- Maximum alignment.
			elseif option == '!' then
				-- Error on invalid alignment.
				maximum_alignment = string.packsize (format .. 'xXi16')

			-- Invalid empty option.
			elseif empty and not option:find ('[xbBhHlLTiIfdjJns]') then
				-- Error should come from `string.packsize ()`.
				error (string.packsize (empty .. format))

			-- All other options.
			else
				-- Prefixed length string.
				if option == 's' then
					format = #size > 0 and 'I' .. size or 'T'
				end

				local padding = 0

				-- Perform alignment.
				if option ~= 'c' and option ~= 'z' then
					local alignment = math.min (
						string.packsize (format), maximum_alignment)
					local remainder = io:seek () % alignment

					if remainder > 0 then
						padding = alignment - remainder
					end
				end

				-- Empty only manages alignment, and that has been
				-- translated into padding.
				if empty then
					format = nil

				-- Padding.
				elseif option == 'x' then
					padding = padding + 1
					format = nil

				-- Other options.
				else
					format = endianness .. format
				end

				coroutine.yield (padding, format)
			end
		end
	end)
end

-- Reads the `io` stream according to `options` and returns the packed
-- values.  Returns `nil` if an error is encountered.
--
-- The `io` stream is expected to have an interface similar to that of Lua's
-- [I/O] library.  The `options` argument follows the rules of [Format
-- Strings] for `string.pack ()` and `string.unpack ()`.
--
-- [I/O]: https://www.lua.org/manual/5.3/manual.html#6.8
-- [Format Strings]: https://www.lua.org/manual/5.3/manual.html#6.4.2
function IO.unpack (io, options)
	assert (io
		and type (io.seek) == 'function'
		and type (io.read) == 'function')
	assert (is_format_string (options))

	local output = {}

	for padding, format in each_option (io, options) do
		local result

		-- Padding and alignment.
		if padding > 0 then
			local status, message = io:seek ('cur', padding)

			if not status then
				return nil, message
			end
		end

		-- No option.
		if not format then -- luacheck: ignore 542

		-- Null-terminated string.
		elseif format:find ('z') then
			local buffer = {}

			repeat
				local byte = io:read (1)

				buffer [#buffer + 1] = byte
			until byte == '\0' or byte == nil

			-- Ignore the null byte.
			buffer [#buffer] = nil

			result = table.concat (buffer)

		-- All other options.
		else
			local is_prefixed = format:find ('s')

			if is_prefixed then
				local size = format:match ('s(%d+)')
				format = size and 'I' .. size or 'T'
			end

			result = string.unpack (format,
				io:read (string.packsize (format)))

			if is_prefixed then
				result = io:read (result)
			end
		end

		output [#output + 1] = result
	end

	return table.unpack (output)
end

-- Writes to the `io` stream the serialized binary representation of a
-- vriable number of arguments according to `options`.  In case of success,
-- this function returns the `io` stream.  Otherwise, it returns `nil`.
--
-- The `io` stream is expected to have an interface similar to that of Lua's
-- [I/O] library.  The `options` argument follows the rules of [Format
-- Strings] for `string.pack ()` and `string.unpack ()`.
function IO.pack (io, options, ...)
	assert (io
		and type (io.seek) == 'function'
		and type (io.write) == 'function')
	assert (is_format_string (options))

	local values = { ... }
	local index = 1

	for padding, format in each_option (io, options) do
		-- Padding and alignment.
		if padding > 0 then
			local status, message = io:write (('\0'):rep (padding))

			if not status then
				return nil, message
			end
		end

		-- All options.
		if format then
			local status, message = io:write (
				string.pack (format, values [index]))

			if not status then
				return nil, message
			end

			index = index + 1
		end
	end

	return io
end

return IO
