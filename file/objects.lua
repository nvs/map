-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

-- Template for Warcraft III object files (i.e. `war3map.w3u`,
-- `war3map.w3t`, etc.).
local Objects = {}

local to_value = {
	[0] = '< i4 xxxx',
	[1] = '< f xxxx',
	[2] = '< f xxxx',
	[3] = '< z xxxx',
}

local to_modification = {
	-- Abilities, destructables, and doodads.
	[true] = {
		[0] = '< c4 i4 i4 i4 i4 c4',
		[1] = '< c4 i4 i4 i4 f c4',
		[2] = '< c4 i4 i4 i4 f c4',
		[3] = '< c4 i4 i4 i4 z c4'
	},

	-- Units, quests, items, and buffs.
	[false] = {
		[0] = '< c4 i4 i4 c4',
		[1] = '< c4 i4 f c4',
		[2] = '< c4 i4 f c4',
		[3] = '< c4 i4 z c4'
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

local unpack = string.unpack
local pack = string.pack

function Objects.unpack (input, extra)
	local output = {}

	-- Version.
	local position = unpack ('< xxxx', input)

	local function unpack_table ()
		local count
		count, position = unpack ('< i4', input, position)

		for _ = 1, count do
			local object = {}

			local base, id
			base, id, count, position =
				unpack ('< c4 c4 i4', input, position)

			-- Original table.
			if id == '\0\0\0\0' then
				id = base

			-- Custom table.
			else
				object.base = base
			end

			for _ = 1, count do
				local name, type, variation, data

				if extra then
					name, type, variation, data, position =
						unpack ('< c4 i4 i4 i4', input, position)
				else
					name, type, position =
						unpack ('< c4 i4', input, position)
				end

				local modification = object [name] or {}
				modification.type = to_name [type]

				if extra then
					modification.data = data
				end

				local value
				value, position = unpack (to_value [type], input, position)

				if variation and variation > 0 then
					modification.values = modification.values or {}
					modification.values [variation] = value
				else
					modification.value = value
				end
			end

			output [id] = object
		end
	end

	unpack_table (output)
	unpack_table (output)

	return output
end

function Objects.pack (input, extra)
	assert (type (input) == 'table')
	extra = not not extra

	local output = {}

	local function pack_table (objects)
		local count = 0

		for _ in pairs (objects) do
			count = count + 1
		end

		output [#output + 1] = pack ('< i4', count)

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

			output [#output + 1] = pack ('< c4 c4', base, id)

			-- Placeholder for the modification count.
			output [#output + 1] = true
			local index = #output

			for name, modification in pairs (object) do
				if type (modification) == 'table' then
					local type = assert (from_name [modification.type])
					local format = assert (to_modification [extra] [type])

					if extra and modification.values then
						local data = modification.data or 0

						for variation, value in
							pairs (modification.values)
						do
							count = count + 1
							output [#output + 1] = pack (
								format, name, type,
								variation, data, value, id)
						end
					elseif extra then
						count = count + 1
						output [#output + 1] = pack (
							format, name, type, 0, modification.data or 0,
							modification.value, id)
					else
						count = count + 1
						output [#output + 1] = pack (
							format, name, type, modification.value, id)
					end
				end
			end

			output [index] = pack ('< i4', count)
		end
	end

	-- Version.
	output [#output + 1] = pack ('< i4', 2)

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
