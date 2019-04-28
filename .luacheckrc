-- Target the intersection of globals for:
--
-- - Lua 5.1
-- - Lua 5.2
-- - Lua 5.3
-- - LuaJIT 2.x
std = 'min'

cache = true

-- Tabs are used for identation.  However, they only count as a single
-- character in regards to width.  So we use a shorter line length for now.
max_line_length = 76

-- The default pattern (equivalent to `'**/*.lua'`) does not match commands.
-- As such, we must explicitly list them and handle all matching ourselves.
include_files = {
	'build',
	'check',

	'**/*.lua'
}

exclude_files = {
	'docs',
	'external'
}
