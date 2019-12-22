-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Units_DOO = {}

local unpack = string.unpack
local pack = string.pack

function Units_DOO.unpack (input, version)
	assert (type (input) == 'string')
	assert (type (version) == 'table')

	local magic,
		format,
		subformat,
		count,
		position = unpack ('< c4 i4 i4 i4', input)

	assert (magic == 'W3do')
	assert (format == 7 or format == 8)
	assert (subformat == 9 or subformat == 11)

	local output = {
		format = format,
		subformat = subformat
	}

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

		if version.minor >= 32 then
			unit.skin,
			position = unpack ('c4', input, position)
		end

		-- TODO: Determine flags.  They probably mirror those from the
		-- doodads DOO file.
		unit.flags,
		unit.player,
		unit.unknown_A,
		unit.unknown_B,
		unit.life,
		unit.mana,
		position = unpack ('< B i4 B B i4 i4', input, position)

		if subformat == 11 then
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

		if subformat == 11 then
			unit.strength,
			unit.agility,
			unit.intelligence,
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
		unit.id,
		position = unpack ('< i4 i4 i4', input, position)
	end

	assert (#input == position - 1)

	return output
end

function Units_DOO.pack (input, version)
	assert (type (input) == 'table')
	assert (type (version) == 'table')

	local output = {}
	local format = input.format or 8
	local subformat = input.subformat or 11
	assert (format == 7 or format == 8)
	assert (subformat == 9 or subformat == 11)

	output [#output + 1] = pack (
		'< c4 i4 i4 i4',
		'W3do',
		format,
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

		if version.minor >= 32 then
			output [#output + 1] = pack ('c4', unit.skin)
		end

		output [#output + 1] = pack (
			'< B i4 B B i4 i4',
			unit.flags,
			unit.player,
			unit.unknown_A,
			unit.unknown_B,
			unit.life,
			unit.mana)

		if subformat == 11 then
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

		if subformat == 11 then
			output [#output + 1] = pack (
				'< i4 i4 i4',
				unit.strength,
				unit.agility,
				unit.intelligence)
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
			unit.id)
	end

	return table.concat (output)
end

return Units_DOO
