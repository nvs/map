-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

-- Template for Warcraft III object files (i.e. `war3map.w3u`,
-- `war3map.w3t`, etc.).
local Objects = {}

local to_format = {
	[0] = 'i4',
	[1] = 'f',
	[2] = 'f',
	[3] = 'z'
}

local modification_format = {
	-- Abilities, destructables, and doodads.
	[true] = {
		[0] = 'c4 i4 i4 i4 i4 c4',
		[1] = 'c4 i4 i4 i4 f c4',
		[2] = 'c4 i4 i4 i4 f c4',
		[3] = 'c4 i4 i4 i4 z c4'
	},

	-- Units, quests, items, and buffs.
	[false] = {
		[0] = 'c4 i4 i4 c4',
		[1] = 'c4 i4 f c4',
		[2] = 'c4 i4 f c4',
		[3] = 'c4 i4 z c4'
	}
}

local from_name = {
	integer = 0,
	real = 1,
	unreal = 2,
	string = 3
}

local to_name = {
	[0] = 'integer',
	[1] = 'real',
	[2] = 'unreal',
	[3] = 'string'
}

function Objects.unpack (input, extra)
	extra = not not extra
	local position

	local function unpack (options)
		local values = { string.unpack ('<' .. options, input, position) }
		local last = #values
		position = values [last]
		return table.unpack (values, 1, last - 1)
	end

	local function unpack_modification (object)
		local id, type = unpack ('c4 i4')

		local modification = object [id] or {}
		modification.type = to_name [type]

		local variation

		if extra then
			variation, modification.data = unpack ('i4 i4')
		end

		local format = to_format [type]

		if variation and variation > 0 then
			modification.values = modification.values or {}
			modification.values [variation] = unpack (format)
		else
			modification.value = unpack (format)
		end

		object [id] = modification
	end

	local function unpack_table (output)
		for _ = 1, unpack ('i4') do
			local object = {}
			local base, id = unpack ('c4 c4')

			-- Original table.
			if id == '\0\0\0\0' then
				id = base

			-- Custom table.
			else
				object.base = base
			end

			for _ = 1, unpack ('i4') do
				unpack_modification (object)

				local cap = unpack ('c4')
				assert (cap == '\0\0\0\0' or cap == id or cap == base)
			end

			output [id] = object
		end
	end

	local output = {}

	unpack ('i4')
	unpack_table (output)
	unpack_table (output)

	return output
end

function Objects.pack (input, extra)
	assert (type (input) == 'table')
	extra = not not extra

	local output = {}

	local function pack (options, ...)
		output [#output + 1] = string.pack ('<' .. options, ...)
	end

	local function pack_modifications (object, object_id)
		local count = 0

		for _, modification in pairs (object) do
			if type (modification) == 'table' then
				if extra and modification.values then
					for _ in pairs (modification.values) do
						count = count + 1
					end
				else
					count = count + 1
				end
			end
		end

		pack ('i4', count)

		for id, modification in pairs (object) do
			if type (modification) == 'table' then
				local type = assert (from_name [modification.type])
				local format = assert (modification_format [extra] [type])

				if extra and modification.values then
					local data = modification.data or 0

					for variation, value in pairs (modification.values) do
						pack (format, id, type,
							variation, data, value, object_id)
					end
				elseif extra then
					pack (format, id, type, 0, modification.data or 0,
						modification.value, object_id)
				else
					pack (format, id, type, modification.value, object_id)
				end
			end
		end
	end

	local function pack_table (objects)
		local count = 0

		for _ in pairs (objects) do
			count = count + 1
		end

		pack ('i4', count)

		for id, object in pairs (objects) do
			local base

			-- Custom table.
			if object.base then
				base = object.base

			-- Original table.
			else
				base = id
				id = '\0\0\0\0'
			end

			pack ('c4 c4', base, id)
			pack_modifications (object, id)
		end
	end

	-- Version.
	pack ('i4', 2)

	local original = {}
	local custom = {}

	-- Split the input table into original and custom.
	for id, object in pairs (input) do
		if #id == 4 then
			if not object.base then
				original [id] = object
			else
				custom [id] = object
			end
		end
	end

	pack_table (original)
	pack_table (custom)

	return table.concat (output)
end

return Objects
