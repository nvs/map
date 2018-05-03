local Unix = {}

function Unix.separators ()
	return '/'
end

-- On Unix, this is fairly simple.  Count the number of slashes.  A run of
-- slashes greater than `2` counts as `1`.
function Unix.root_length (path)
	local _, count = path:find ('^/+')

	if not count then
		count = 0
	elseif count > 2 then
		count = 1
	end

	return count
end

-- A path is rooted if it begins with a separator.
function Unix.is_rooted (path)
	return path:sub (1, 1) == '/'
end

-- A path is relative if it is not rooted.
function Unix.is_relative (path)
	return not Unix.is_rooted (path)
end

function Unix.home_directory ()
	return os.getenv ('HOME')
end

return Unix
