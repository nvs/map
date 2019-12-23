-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Objects = {}

local to_value = {
	-- Value; cap.
	[0] = '< i4 xxxx',
	[1] = '< f xxxx',
	[2] = '< f xxxx',
	[3] = '< z xxxx',
}

local to_modification = {
	-- Abilities, doodads, and upgrades.
	[true] = {
		-- Name; type; variation; data; value; id.
		[0] = '< c4 i4 i4 i4 i4 c4',
		[1] = '< c4 i4 i4 i4 f c4',
		[2] = '< c4 i4 i4 i4 f c4',
		[3] = '< c4 i4 i4 i4 z c4'
	},

	-- Units, quests, items, and buffs.
	[false] = {
		-- Name; type; value; id.
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

	local format,
		position = unpack ('< i4', input)

	assert (format == 2)

	local function unpack_table ()
		local objects

		objects,
		position = unpack ('< i4', input, position)

		for _ = 1, objects do
			local object = {}
			local base, id, modifications

			base,
			id,
			modifications,
			position = unpack ('< c4 c4 i4', input, position)

			-- Original table.
			if id == '\0\0\0\0' then
				id = base

			-- Custom table.
			else
				object.base = base
			end

			for _ = 1, modifications do
				local name, type, variation, data

				if extra then
					name,
					type,
					variation,
					data,
					position = unpack ('< c4 i4 i4 i4', input, position)
				else
					name,
					type,
					position = unpack ('< c4 I4', input, position)
				end

				local modification = object [name] or {}
				modification.type = to_name [type]

				if extra then
					modification.data = data
				end

				local value

				value,
				position = unpack (to_value [type], input, position)

				if variation and variation > 0 then
					modification.values = modification.values or {}
					modification.values [variation] = value
				else
					modification.value = value
				end

				object [name] = modification
			end

			output [id] = object
		end
	end

	unpack_table ()
	unpack_table ()

	assert (#input == position - 1)

	return output
end

function Objects.pack (input, extra)
	assert (type (input) == 'table')
	extra = not not extra

	local original = { 0 }
	local custom = { 0 }

	for id, object in pairs (input) do
		if #id == 4 then
			local output, base, cap

			if not object.base then
				output = original
				base = id
				cap = id
				id = '\0\0\0\0'
			else
				output = custom
				base = object.base
				cap = '\0\0\0\0'
			end

			output [1] = output [1] + 1
			output [#output + 1] = pack ('< c4 c4', base, id)

			local count = 0
			output [#output + 1] = true
			local index = #output

			for name, modification in pairs (object) do
				if type (modification) == 'table' then
					local type = from_name [modification.type]
					local format = to_modification [extra] [type]

					if extra and modification.values then
						local data = modification.data or 0

						for variation, value in
							pairs (modification.values)
						do
							count = count + 1
							output [#output + 1] = pack (
								format,
								name,
								type,
								variation,
								data,
								value,
								cap)
						end
					elseif extra then
						count = count + 1
						output [#output + 1] = pack (
							format,
							name,
							type,
							0,
							modification.data or 0,
							modification.value,
							cap)
					else
						count = count + 1
						output [#output + 1] = pack (
							format,
							name,
							type,
							modification.value,
							cap)
					end
				end
			end

			output [index] = pack ('< i4', count)
		end
	end

	original [1] = pack ('< i4', original [1])
	custom [1] = pack ('< i4', custom [1])

	return pack ('< i4', 2)
		.. table.concat (original)
		.. table.concat (custom)
end

return Objects
