-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Flags = require ('map.file.flags')

local Units_DOO = {}

local unpack = string.unpack
local pack = string.pack

local is_format = {
	[7] = true,
	[8] = true
}

local is_subformat = {
	[9] = true,
	[11] = true
}

-- Probably the same or similar to those in the Doodads DOO.
local flags = {
	[0x01] = 'unknown_0x01',
	[0x02] = 'unknown_0x02',
	[0x04] = 'unknown_0x04',
	[0x08] = 'unknown_0x08',
	[0x10] = 'unknown_0x10',
}

function Units_DOO.unpack (input, position)
	local magic, count
	local output = {}

	magic, output.format, output.subformat, count,
	position = unpack ('< c4 i4 i4 i4', input, position)

	assert (magic == 'W3do')
	assert (is_format [output.format])
	assert (is_subformat [output.subformat])

	for unit = 1, count do
		output [unit] = {
			position = {},
			scale = {}
		}
		unit = output [unit]

		unit.type,
		unit.variation,
		unit.position.x,
		unit.position.y,
		unit.position.z,
		unit.angle,
		unit.scale.x,
		unit.scale.y,
		unit.scale.z,
		position = unpack ('< c4 i4 f f f f f f f', input, position)

		-- Degrees are used in other files.  Match that behavior.
		unit.angle = math.deg (unit.angle)

		-- Following the behavior at https://github.com/Drake53/War3Net, we
		-- check to see if the next character is printable.  If so, we make
		-- the assumption that the newest format is used.  This imposes a
		-- hard limit of 5-bits for flags.
		local is_reforged = unpack ('< B', input) >= 0x20

		if is_reforged then
			unit.skin,
			position = unpack ('< c4', input, position)
		end

		unit.flags,
		unit.player,
		unit.unknown_A,
		unit.unknown_B,
		unit.life,
		unit.mana,
		position = unpack ('< B i4 B B i4 i4', input, position)

		unit.flags = Flags.unpack (flags, unit.flags)

		if output.subformat >= 11 then
			unit.map_item_table,
			position = unpack ('< i4', input, position)
		end

		unit.item_table = {}

		count,
		position = unpack ('< i4', input, position)

		for set = 1, count do
			local items = {}
			unit.item_table [set] = items

			count,
			position = unpack ('< i4', input, position)

			for index = 1, count do
				local item = {}
				items [index] = item

				item.id,
				item.chance,
				position = unpack ('< c4 i4', input, position)
			end
		end

		unit.gold,
		unit.target_acquisition,
		unit.level,
		position = unpack ('< i4 f i4', input, position)

		if output.subformat >= 11 then
			unit.attributes = {}

			unit.attributes.strength,
			unit.attributes.agility,
			unit.attributes.intelligence,
			position = unpack ('< i4 i4 i4', input, position)
		end

		unit.items = {}

		count,
		position = unpack ('< i4', input, position)

		for slot = 1, count do
			local item = {}
			unit.items [slot] = item

			item.slot,
			item.id,
			position = unpack ('< i4 c4', input, position)
		end

		unit.abilities = {}

		count,
		position = unpack ('< i4', input, position)

		for index = 1, count do
			local ability = {}
			unit.abilities [index] = ability

			ability.id,
			ability.autocast,
			ability.level,
			position = unpack ('< c4 i4 i4', input, position)
		end

		unit.random = {}

		unit.random.format,
		position = unpack ('< i4', input, position)

		if unit.random.format == 0 then
			unit.random.level,
			unit.random.class,
			position = unpack ('< i3 i1', input, position)
		elseif unit.random.format == 1 then
			unit.random.group,
			unit.random.position,
			position = unpack ('< i4 i4', input, position)
		elseif unit.random.format == 2 then
			count,
			position = unpack ('< i4', input, position)

			for index = 1, count do
				local random = {}

				random.id,
				random.chance,
				position = unpack ('< c4 i4', input, position)

				unit.random [index] = random
			end
		end

		unit.color,
		unit.waygate,
		unit.index,
		position = unpack ('< i4 i4 i4', input, position)
	end

	return output, position
end

function Units_DOO.pack (input)
	assert (is_format [input.format])
	assert (is_subformat [input.subformat])

	local output = {}

	output [#output + 1] = pack (
		'< c4 i4 i4 i4',
		'W3do',
		input.format,
		input.subformat,
		#input)

	for _, unit in ipairs (input) do
		output [#output + 1] = pack (
			'< c4 i4 f f f f f f f',
			unit.type,
			unit.variation,
			unit.position.x,
			unit.position.y,
			unit.position.z,
			math.rad (unit.angle),
			unit.scale.x,
			unit.scale.y,
			unit.scale.z)

		if unit.skin then
			output [#output + 1] = pack ('< c4', unit.skin)
		end

		output [#output + 1] = pack (
			'< B i4 B B i4 i4',
			Flags.pack (flags, unit.flags),
			unit.player,
			unit.unknown_A,
			unit.unknown_B,
			unit.life,
			unit.mana)

		if input.subformat == 11 then
			output [#output + 1] = pack ('< i4', unit.map_item_table)
		end

		output [#output + 1] = pack ('< i4', #unit.item_table)

		for _, set in ipairs (unit.item_table) do
			output [#output + 1] = pack ('< i4', #set)

			for _, item in ipairs (set) do
				output [#output + 1] = pack (
					'< c4 i4',
					item.id,
					item.chance)
			end
		end

		output [#output + 1] = pack (
			'< i4 f i4',
			unit.gold,
			unit.target_acquisition,
			unit.level)

		if input.subformat == 11 then
			output [#output + 1] = pack (
				'< i4 i4 i4',
				unit.attributes.strength,
				unit.attributes.agility,
				unit.attributes.intelligence)
		end

		output [#output + 1] = pack ('< i4', #unit.items)

		for _, item in ipairs (unit.items) do
			output [#output + 1] = pack ('< i4 c4', item.slot, item.id)
		end

		output [#output + 1] = pack ('< i4', #unit.abilities)

		for _, ability in ipairs (unit.abilities) do
			output [#output + 1] = pack (
				'< c4 i4 i4',
				ability.id,
				ability.autocast,
				ability.level)
		end

		output [#output + 1] = pack ('< i4', unit.random.format)

		if unit.random.format == 0 then
			output [#output + 1] = pack (
				'< i3 B',
				unit.random.level,
				unit.random.class)
		elseif unit.random.format == 1 then
			output [#output + 1] = pack (
				'< i4 i4',
				unit.random.group,
				unit.random.position)
		elseif unit.random.format == 2 then
			output [#output + 1] = pack ('< i4', #unit.random)

			for _, random in ipairs (unit.random) do
				output [#output + 1] = pack (
					'< c4 i4',
					random.id,
					random.chance)
			end
		end

		output [#output + 1] = pack (
			'< i4 i4 i4',
			unit.color,
			unit.waygate,
			unit.index)
	end

	return table.concat (output)
end

return Units_DOO
