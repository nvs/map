-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local DOO = {}

function DOO.unpack (input, version)
	assert (type (input) == 'string')
	assert (type (version) == 'table')

	local position

	local function unpack (options)
		local values = { string.unpack ('<' .. options, input, position) }
		position = values [#values]
		return table.unpack (values, 1, #values - 1)
	end

	local magic = unpack ('c4')
	local format = unpack ('i4')

	if magic ~= 'W3do' or format < 7 or format > 8 then
		return nil
	end

	local output = {
		format = format,
		subformat = unpack ('i4')
	}

	for _ = 1, unpack ('i4') do
		local unit = {
			type = unpack ('c4'),
			variation = unpack ('i4'),
			position = {
				x = unpack ('f'),
				y = unpack ('f'),
				z = unpack ('f')
			},
			angle = math.deg (unpack ('f')),
			scale = {
				x = unpack ('f'),
				y = unpack ('f'),
				z = unpack ('f')
			}
		}

		if version.minor >= 32 then
			unit.skin = unpack ('c4')
		end

		unit.flags = unpack ('B')
		unit.player = unpack ('i4')
		unit.unknown_A = unpack ('B')
		unit.unknown_B = unpack ('B')
		unit.life = unpack ('i4')
		unit.mana = unpack ('i4')

		if format == 8 then
			unit.map_item_table = unpack ('i4')
		end

		unit.item_table = {}

		for set = 1, unpack ('i4') do
			unit.item_table [set] = {}

			for item = 1, unpack ('i4') do
				unit.item_table [set] [item] = {
					id = unpack ('c4'),
					chance = unpack ('i4')
				}
			end
		end

		unit.gold = unpack ('i4')
		unit.target_acquisition = unpack ('f')
		unit.level = unpack ('i4')

		if format == 8 then
			unit.strength = unpack ('i4')
			unit.agility = unpack ('i4')
			unit.intelligence = unpack ('i4')
		end

		unit.items = {}

		for slot = 1, unpack ('i4') do
			local item = {
				slot = unpack ('i4'),
				id = unpack ('c4')
			}

			unit.items [slot] = item
		end

		unit.abilities = {}

		for index = 1, unpack ('i4') do
			local ability = {
				id = unpack ('c4'),
				autocast = unpack ('i4'),
				level = unpack ('i4')
			}

			unit.abilities [index] = ability
		end

		unit.random = {
			format = unpack ('i4')
		}

		if unit.random.format == 0 then
			unit.random.level = unpack ('i3')
			unit.random.class = unpack ('i1')
		elseif unit.random.format == 1 then
			unit.random.group = unpack ('i4')
			unit.random.position = unpack ('i4')
		elseif unit.random.format == 2 then
			for index = 1, unpack ('i4') do
				unit.random [index] = {
					id = unpack ('c4'),
					chance = unpack ('i4')
				}
			end
		end

		unit.color = unpack ('i4')
		unit.waygate = unpack ('i4')
		unit.id = unpack ('i4')

		output [#output + 1] = unit
	end

	assert (#input == position - 1)

	return output
end

function DOO.pack (input, version)
	assert (type (input) == 'table')
	assert (type (version) == 'table')

	local output = {}

	local function pack (options, ...)
		output [#output + 1] = string.pack ('<' .. options, ...)
	end

	local format = input.format

	pack ('c4', 'W3do')
	pack ('i4', input.format)
	pack ('i4', input.subformat)
	pack ('i4', #input)

	for _, unit in ipairs (input) do
		pack ('c4', unit.type)
		pack ('i4', unit.variation)
		pack ('f', unit.position.x)
		pack ('f', unit.position.y)
		pack ('f', unit.position.z)
		pack ('f', math.rad (unit.angle))
		pack ('f', unit.scale.x)
		pack ('f', unit.scale.y)
		pack ('f', unit.scale.z)

		if version.minor >= 32 then
			pack ('c4', unit.skin)
		end

		pack ('B', unit.flags)
		pack ('i4', unit.player)
		pack ('B', unit.unknown_A)
		pack ('B', unit.unknown_B)
		pack ('i4', unit.life)
		pack ('i4', unit.mana)

		if format == 8 then
			pack ('i4', unit.map_item_table)
		end

		pack ('i4', #unit.item_table)

		for _, set in ipairs (unit.item_table) do
			pack ('i4', #set)

			for _, item in ipairs (set) do
				pack ('c4', item.id)
				pack ('i4', item.chance)
			end
		end

		pack ('i4', unit.gold)
		pack ('f', unit.target_acquisition)
		pack ('i4', unit.level)

		if format == 8 then
			pack ('i4', unit.strength)
			pack ('i4', unit.agility)
			pack ('i4', unit.intelligence)
		end

		pack ('i4', #unit.items)

		for _, item in ipairs (unit.items) do
			pack ('i4', item.slot)
			pack ('c4', item.id)
		end

		pack ('i4', #unit.abilities)

		for _, ability in ipairs (unit.abilities) do
			pack ('c4', ability.id)
			pack ('i4', ability.autocast)
			pack ('i4', ability.level)
		end

		pack ('i4', unit.random.format)

		if unit.random.format == 0 then
			pack ('i3', unit.random.level)
			pack ('B', unit.random.class)
		elseif unit.random.format == 1 then
			pack ('i4', unit.random.group)
			pack ('i4', unit.random.position)
		elseif unit.random.format == 2 then
			pack ('i4', #unit.random)

			for _, random in ipairs (unit.random) do
				pack ('c4', random.id)
				pack ('i4', random.chance)
			end
		end

		pack ('i4', unit.color)
		pack ('i4', unit.waygate)
		pack ('i4', unit.id)
	end

	return table.concat (output)
end

return DOO
