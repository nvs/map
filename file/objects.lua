-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Utils = require ('map.utils')

local Objects = {}

local unpack = string.unpack
local pack = string.pack

local is_format = {
	[2] = true
}

local value_format = {
	[0] = '< i4',
	[1] = '< f',
	[2] = '< f',
	[3] = '< z',
}

local to_type = {
	[0] = 'integer',
	[1] = 'real',
	[2] = 'unreal',
	[3] = 'string'
}

local default_options = {
	has_variations = true,
	is_file = true
}

function Objects.unpack (input, position, options)
	options = Utils.merge_options (options, default_options)
	local has_variations = options.has_variations

	local output = {
		objects = {}
	}

	output.format, position = unpack ('< i4', input, position)
	assert (is_format [output.format])

	local function unpack_table ()
		local objects

		objects,
		position = unpack ('< i4', input, position)

		for _ = 1, objects do
			local object = {}
			local base, id, modifications

			base, id, modifications,
			position = unpack ('< c4 c4 i4', input, position)

			if id == '\0\0\0\0' then
				id = base
			else
				object.base = base
			end

			for _ = 1, modifications do
				local name, type, variation, data
				local value

				if has_variations then
					name, type, variation, data,
					position = unpack ('< c4 i4 i4 i4', input, position)
				else
					name, type,
					position = unpack ('< c4 i4', input, position)
				end

				value,
				position = unpack (value_format [type], input, position)
				position = position + 4

				local modification = object [name] or {}
				modification.type = to_type [type]
				modification.data = data

				if variation and variation > 0 then
					modification.values = modification.values or {}
					modification.values [variation] = value
				else
					modification.value = value
				end

				object [name] = modification
			end

			output.objects [id] = object
		end
	end

	unpack_table ()
	unpack_table ()

	if options.is_file then
		assert (position > #input)
	end

	return output, position
end

local from_type = {
	integer = 0,
	real = 1,
	unreal = 2,
	string = 3
}

local modification_formats = {
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

function Objects.pack (input, options)
	options = Utils.merge_options (options, default_options)
	local has_variations = options.has_variations
	assert (is_format [input.format])

	local modification_format = modification_formats [has_variations]
	local original = { 0 }
	local custom = { 0 }

	for id, object in pairs (input.objects) do
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
		output [#output + 1] = true
		local index = #output

		for name, modification in pairs (object) do
			if type (modification) == 'table' then
				local type = from_type [modification.type]
				local format = modification_format [type]

				if modification.values then
					local data = modification.data or 0

					for variation, value in pairs (modification.values) do
						output [#output + 1] = pack (format, name, type,
							variation, data, value, cap)
					end
				elseif has_variations then
					output [#output + 1] = pack (format, name, type, 0,
						modification.data or 0, modification.value, cap)
				else
					output [#output + 1] = pack (format, name, type,
						modification.value, cap)
				end
			end
		end

		output [index] = pack ('< i4', #output - index)
	end

	original [1] = pack ('< i4', original [1])
	custom [1] = pack ('< i4', custom [1])

	return pack ('< i4', input.format)
		.. table.concat (original)
		.. table.concat (custom)
end

return Objects
