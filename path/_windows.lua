local Windows = {}

-- Returns a `boolean` indicating whether the `path` (`string`) uses the
-- canonical form of extended syntax (i.e. `\\?\` or `\??\`).
--
-- According to [CoreFX's `PathInternal.Windows.cs`], both `\\?\` and `\??\`
-- behave the same and will skip normalization.  The article [MSDN: Naming
-- Files, Paths, and Namespaces] discusses the behavior of the `\\?\` prefix
-- in more detail.  Of particular note are the following two quotes:
--
-- > For file I/O, the `\\?\` prefix to a path string tells the Windows APIs
--   to disable all string parsing and to send the string that follows it
--   straight to the file system.
--
-- > [The `\\?\` prefix] indicate[s] that the path should be passed to the
--   system with minimal modification, which means that you cannot use
--   forward slashes to represent path separators, or a period to represent
--   the current directory, or double dots to represent the parent
--   directory.
local function is_extended (path)
	return not not path:find ('^[\\][\\?][?][\\]')
end

-- Returns a `boolean` indicating whether the `path` uses any of the DOS
-- device path syntaxes (i.e. `\\.\`, `\\?\`, or `\??\`).  Can match the
-- alternative directory separator (i.e. `/`).
local function is_device (path)
	return is_extended (path)
		or not not path:find ('^[\\/][\\/][.?][\\/]')
end

-- The separators depend on whether `path` uses the canonical form of
-- extended syntax.  See `is_extended ()`.
function Windows.separators (path)
	return is_extended (path) and '\\' or '\\/'
end

-- For the most part, we follow the behavior of `GetRootLength ()` from
-- [CoreFX's `PathInternal.Windows.cs`].
function Windows.root_length (path)
	local P = '[\\/]'
	local N = '[^\\/]'

	-- `C:`
	-- `C:\`
	local _, index = path:find ('^%a:' .. P .. '?')

	if index then
		return index
	end

	-- At this point, the path can only be rooted if it starts with a
	-- separator.
	if not path:find ('^' .. P) then
		return 0
	end

	if is_device (path) then
		if is_extended (path) then
			P = '[\\]'
			N = '[^\\]'
		end

		-- `\\?\UNC\...`
		if path:find ('^UNC' .. P, 5) then
			index = 9

		-- `\\.\`
		-- `\\?\`
		-- '\??\`
		else
			local pattern = ('^%s+()%s?()'):format (N, P)
			local A, B = path:match (pattern, 5)

			return not A and 4 or B - 1
		end
	end

	-- `\\`
	-- `\\Server\Share`
	-- `\\?\UNC\`
	-- `\\?\UNC\Server\Share`
	if index or path:find ('^' .. P, 2) then
		local pattern = ('^%s*()%s?%s*()%s?'):format (N, P, N, P)
		local A, B = path:match (pattern, index or 3)

		return B and B - 1 or A - 1
	end

	-- `\`
	return 1
end

-- A path is rooted on Windows if it either starts with a directory
-- separator or a valid drive ltter and volume separator (e.g. `C:`).
function Windows.is_rooted (path)
	return not not (path:find ('^[\\/]') or path:find ('^%a:'))
end

-- A path is relative on Windows if it is not fixed to a specified drive or
-- UNC path.  Being rooted does not mean a path is absolute.
function Windows.is_relative (path)
	assert (type (path) == 'string')

	-- Fixed paths cannot be specified with one character or less.
	if #path < 2 then
		return true
	end

	-- A path that starts with `\\` or `\?` cannot be relative.
	if path:find ('^[\\/][\\/?]') then
		return false
	end

	-- This leaves one last way to specify a fixed path: a valid drive
	-- letter, volume separator, and directory separator (e.g. `C:\`).
	-- If the path does not match this, then it is relative.
	return not path:find ('^%a:[\\/]')
end

-- Returns the path (`string`) for the current user's home directory.
-- Returns `nil` if the home directory cannot be discerned.
function Windows.home_directory ()
	local path = os.getenv ('USERPROFILE')

	if path then
		return path
	end

	local drive = os.getenv ('HOMEDRIVE')
	path = os.getenv ('HOMEPATH')

	if drive and path then
		return drive .. path
	end

	return nil
end

return Windows

-- luacheck: no max comment line length
--
-- [CoreFX's `PathInternal.Windows.cs`]: https://github.com/dotnet/corefx/blob/master/src/Common/src/CoreLib/System/IO/PathInternal.Windows.cs
-- [MSDN: Naming Files, Paths, and Namespaces]: https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247.aspx
