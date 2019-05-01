-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Bits = require ('map.file.bits')
local Flags = require ('map.file.flags')
local IO = require ('map.io')
local Null = require ('map.io.null')

-- Deals with the `war3map.w3i`.
local W3I = {}

local map_flags = require ('map.file.map_flags')
local force_flags = {
	[0x01] = 'allied',
	[0x02] = 'allied_victory',
	[0x08] = 'share_vision',
	[0x10] = 'share_control',
	[0x20] = 'share_advanced_control'
}

function W3I.unpack (io)
	if not io then
		return nil
	end

	local function unpack (options)
		return assert (IO.unpack (io, '<' .. options))
	end

	local function unpack_bits (option)
		return Bits.unpack (option, unpack (option))
	end

	local function unpack_map_flags (option)
		return Flags.unpack (map_flags, unpack (option))
	end

	local function unpack_force_flags (option)
		return Flags.unpack (force_flags, unpack (option))
	end

	assert (io:seek ('set'))

	local output = {}

	output.type = unpack ('i4')

	local is_roc = output.type == 0x12
	local is_tft = output.type == 0x19
	local is_lua = output.type == 0x1C

	if not (is_roc or is_tft or is_lua) then
		return nil
	end

	output.saves = unpack ('i4')
	output.editor = unpack ('i4')

	if is_lua then
		output.version = {
			major = unpack ('i4'),
			minor = unpack ('i4'),
			patch = unpack ('i4'),
			build = unpack ('i4')
		}
	end

	output.map = {
		name = unpack ('z'),
		author = unpack ('z'),
		description = unpack ('z'),
		recommended = unpack ('z'),
	}

	output.camera = {}

	for index = 1, 4 do
		output.camera [index] = {
			x = unpack ('f'),
			y = unpack ('f')
		}
	end

	output.margins = {
		left = unpack ('i4'),
		right = unpack ('i4'),
		top = unpack ('i4'),
		bottom = unpack ('i4')
	}

	output.dimensions = {
		width = unpack ('i4'),
		height = unpack ('i4')
	}

	output.map.flags = unpack_map_flags ('I4')
	output.tileset = unpack ('c1')

	if is_roc then
		output.campaign = {
			background = unpack ('i4')
		}

		output.loading = {
			text = unpack ('z'),
			title = unpack ('z'),
			subtitle = unpack ('z'),
			background = unpack ('i4')
		}

		output.prologue = {
			text = unpack ('z'),
			title = unpack ('z'),
			subtitle = unpack ('z')
		}
	end

	if is_tft or is_lua then
		output.loading = {
			background = unpack ('i4'),
			model = unpack ('z'),
			text = unpack ('z'),
			title = unpack ('z'),
			subtitle = unpack ('z')
		}

		output.game_data = unpack ('i4')

		output.prologue = {
			model = unpack ('z'),
			text = unpack ('z'),
			title = unpack ('z'),
			subtitle = unpack ('z')
		}

		output.fog = {
			index = unpack ('i4'),
			z = {
				start = unpack ('f'),
				finish = unpack ('f')
			},
			density = unpack ('f'),
			color = {
				red = unpack ('B'),
				green = unpack ('B'),
				blue = unpack ('B'),
				alpha = unpack ('B')
			}
		}

		output.environment = {
			weather = unpack ('c4'),
			sound = unpack ('z'),
			light = unpack ('c1'),
			water = {
				red = unpack ('B'),
				green = unpack ('B'),
				blue = unpack ('B'),
				alpha = unpack ('B')
			}
		}
	end

	if is_lua then
		output.is_lua = unpack ('i4') == 1
	end

	output.players = {}

	for index = 1, unpack ('i4') do
		local player = {
			index = unpack ('i4'),
			type = unpack ('i4'),
			race = unpack ('i4'),
			start = {
				fixed = unpack ('i4')
			},
			name = unpack ('z'),
			ally = {}
		}

		player.start.x = unpack ('f')
		player.start.y = unpack ('f')

		player.ally.low = unpack_bits ('I4')
		player.ally.high = unpack_bits ('I4')

		output.players [index] = player
	end

	output.forces = {}

	for index = 1, unpack ('i4') do
		output.forces [index] = {
			flags = unpack_force_flags ('I4'),
			players = unpack_bits ('I4'),
			name = unpack ('z')
		}
	end

	output.upgrades = {}

	for index = 1, unpack ('i4') do
		output.upgrades [index] = {
			players = unpack_bits ('I4'),
			id = unpack ('c4'),
			level = unpack ('i4'),
			availability = unpack ('i4')
		}
	end

	output.tech = {}

	for index = 1, unpack ('i4') do
		output.tech [index] = {
			players = unpack_bits ('I4'),
			id = unpack ('c4')
		}
	end

	output.units = {}

	for index = 1, unpack ('i4') do
		local unit = {
			index = unpack ('i4'),
			name = unpack ('z'),
			columns = unpack ('i4')
		}

		unit.type = { unpack (('i4'):rep (unit.columns)) }

		for row = 1, unpack ('i4') do
			unit.rows [row] = {
				chance = unpack ('i4'),
				id = { unpack (('c4'):rep (unit.columns)) }
			}
		end

		output.units [index] = unit
	end

	if is_tft or is_lua then
		output.item_tables = {}

		for index = 1, unpack ('i4') do
			local item_table = {
				index = unpack ('i4'),
				name = unpack ('z')
			}

			for set = 1, unpack ('i4') do
				item_table [set] = {}

				for item = 1, unpack ('i4') do
					item_table [set] [item] = {
						chance = unpack ('i4'),
						id = unpack ('c4')
					}
				end
			end

			output.item_tables [index] = item_table
		end
	end

	return output
end

function W3I.pack (io, input)
	assert (type (input) == 'table')

	if not io then
		return nil
	end

	local function pack (options, ...)
		assert (IO.pack (io, '<' .. options, ...))
	end

	local function pack_bits (option, value)
		pack (option, Bits.pack (option, value))
	end

	local function pack_map_flags (option, value)
		pack (option, Flags.pack (map_flags, value))
	end

	local function pack_force_flags (option, value)
		pack (option, Flags.pack (force_flags, value))
	end

	assert (io:seek ('set'))

	local is_roc = input.type == 0x12
	local is_tft = input.type == 0x19
	local is_lua = input.type == 0x1C

	if not (is_roc or is_tft or is_lua) then
		return nil
	end

	pack ('i4', input.type)
	pack ('i4', input.saves)
	pack ('i4', input.editor)

	if is_lua then
		pack ('i4', input.version.major)
		pack ('i4', input.version.minor)
		pack ('i4', input.version.patch)
		pack ('i4', input.version.build)
	end

	pack ('z', input.map.name)
	pack ('z', input.map.author)
	pack ('z', input.map.description)
	pack ('z', input.map.recommended)

	for index = 1, 4 do
		pack ('f', input.camera [index].x)
		pack ('f', input.camera [index].y)
	end

	pack ('i4', input.margins.left)
	pack ('i4', input.margins.right)
	pack ('i4', input.margins.top)
	pack ('i4', input.margins.bottom)

	pack ('i4', input.dimensions.width)
	pack ('i4', input.dimensions.height)

	pack_map_flags ('I4', input.map.flags)
	pack ('c1', input.tileset)

	if is_roc then
		pack ('i4', input.campaign.background)

		pack ('z', input.loading.text)
		pack ('z', input.loading.title)
		pack ('z', input.loading.subtitle)
		pack ('i4', input.loading.background)

		pack ('z', input.prologue.text)
		pack ('z', input.prologue.title)
		pack ('z', input.prologue.subtitle)
	end

	if is_tft or is_lua then
		pack ('i4', input.loading.background)
		pack ('z', input.loading.model)
		pack ('z', input.loading.text)
		pack ('z', input.loading.title)
		pack ('z', input.loading.subtitle)

		pack ('i4', input.game_data)

		pack ('z', input.prologue.model)
		pack ('z', input.prologue.text)
		pack ('z', input.prologue.title)
		pack ('z', input.prologue.subtitle)

		pack ('i4', input.fog.index)
		pack ('f', input.fog.z.start)
		pack ('f', input.fog.z.finish)
		pack ('f', input.fog.density)
		pack ('B', input.fog.color.red)
		pack ('B', input.fog.color.green)
		pack ('B', input.fog.color.blue)
		pack ('B', input.fog.color.alpha)

		pack ('c4', input.environment.weather)
		pack ('z', input.environment.sound)
		pack ('c1', input.environment.light)
		pack ('B', input.environment.water.red)
		pack ('B', input.environment.water.green)
		pack ('B', input.environment.water.blue)
		pack ('B', input.environment.water.alpha)
	end

	if is_lua then
		pack ('i4', input.is_lua and 1 or 0)
	end

	pack ('i4', #input.players)

	for _, player in ipairs (input.players) do
		pack ('i4', player.index)
		pack ('i4', player.type)
		pack ('i4', player.race)
		pack ('i4', player.start.fixed)
		pack ('z', player.name)
		pack ('f', player.start.x)
		pack ('f', player.start.y)
		pack_bits ('I4', player.ally.low)
		pack_bits ('I4', player.ally.high)
	end

	pack ('i4', #input.forces)

	for _, force in ipairs (input.forces) do
		pack_force_flags ('I4', force.flags)
		pack_bits ('I4', force.players)
		pack ('z', force.name)
	end

	pack ('i4', #input.upgrades)

	for _, upgrade in ipairs (input.upgrades) do
		pack_bits ('I4', upgrade.players)
		pack ('c4', upgrade.id)
		pack ('i4', upgrade.level)
		pack ('i4', upgrade.availability)
	end

	pack ('i4', #input.tech)

	for _, tech in ipairs (input.tech) do
		pack_bits ('I4', tech.players)
		pack ('c4', tech.id)
	end

	pack ('i4', #input.units)

	for _, units in ipairs (input.units) do
		pack ('i4', units.index)
		pack ('z', units.name)
		pack ('i4', units.columns)
		pack (('i4'):rep (units.columns), table.unpack (units.type))

		pack ('i4', #units.rows)

		for _, row in ipairs (units.rows) do
			pack ('i4', row.chance)
			pack (('c4'):rep (units.columns), table.unpack (row.id))
		end
	end

	if is_tft or is_lua then
		pack ('i4', #input.item_tables)

		for _, item_table in ipairs (input.item_tables) do
			pack ('i4', item_table.index)
			pack ('z', item_table.name)
			pack ('i4', #item_table)

			for _, set in ipairs (item_table) do
				pack ('i4', #set)

				for _, item in ipairs (set) do
					pack ('i4', item.chance)
					pack ('c4', item.id)
				end
			end
		end
	end

	return true
end

function W3I.packsize (input)
	assert (type (input) == 'table')

	local io = Null.open ()

	if not W3I.pack (io, input) then
		return nil
	end

	return io:seek ('end')
end

return W3I
