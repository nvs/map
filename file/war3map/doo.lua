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

	for index = 1, unpack ('i4') do
		local doodad = {
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
			doodad.skin = unpack ('c4')
		end

		local flags = unpack ('B')
		doodad.flags = {
			visible = flags > 1,
			solid = flags == 2
		}
		doodad.life = unpack ('B')

		if format == 8 then
			doodad.map_item_table = unpack ('i4')
			doodad.item_table = {}

			for set = 1, unpack ('i4') do
				doodad.item_table [set] = {}

				for item = 1, unpack ('i4') do
					doodad.item_table [set] [item] = {
						id = unpack ('c4'),
						chance = unpack ('i4')
					}
				end
			end
		end

		doodad.id = unpack ('i4')

		output [index] = doodad
	end

	output.special = {
		format = unpack ('i4')
	}

	for index = 1, unpack ('i4') do
		local special = {
			type = unpack ('c4'),
			variation = unpack ('i4'),
			position = {
				x = unpack ('i4'),
				y = unpack ('i4')
			}
		}

		output.special [index] = special
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

	pack ('c4', 'W3do')
	pack ('i4', input.format)
	pack ('i4', input.subformat)
	pack ('i4', #input)

	for _, doodad in ipairs (input) do
		pack ('c4', doodad.type)
		pack ('i4', doodad.variation)
		pack ('f', doodad.position.x)
		pack ('f', doodad.position.y)
		pack ('f', doodad.position.z)
		pack ('f', math.rad (doodad.angle))
		pack ('f', doodad.scale.x)
		pack ('f', doodad.scale.y)
		pack ('f', doodad.scale.z)

		if version.minor >= 32 then
			pack ('c4', doodad.skin)
		end

		pack ('B', doodad.flags.solid and 2	or doodad.flags.visible or 0)
		pack ('B', doodad.life)

		if input.format == 8 then
			pack ('i4', doodad.map_item_table)
			pack ('i4', #doodad.item_table)

			for _, set in ipairs (doodad.item_table) do
				pack ('i4', #set)

				for _, item in ipairs (set) do
					pack ('c4', item.id)
					pack ('i4', item.chance)
				end
			end
		end

		pack ('i4', doodad.id)
	end

	pack ('i4', input.special.format)
	pack ('i4', #input.special)

	for _, special in ipairs (input.special) do
		pack ('c4', special.type)
		pack ('i4', special.variation)
		pack ('i4', special.position.x)
		pack ('i4', special.position.y)
	end

	return table.concat (output)
end

return DOO
