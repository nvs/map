-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Bits = require ('map.file.bits')
local Flags = require ('map.file.flags')

local W3I = {}

local map_flags = {
	[0x00001] = 'hide_minimap_in_preview_screens',
	[0x00002] = 'modify_ally_priorities',
	[0x00004] = 'melee_map',
	[0x00008] = 'playable_map_size_was_large',
	[0x00010] = 'masked_areas_are_partially_visible',
	[0x00020] = 'fixed_player_settings_for_custom_forces',
	[0x00040] = 'use_custom_forces',
	[0x00080] = 'use_custom_techtree',
	[0x00100] = 'use_custom_abilities',
	[0x00200] = 'use_custom_upgrades',
	[0x00400] = 'has_opened_map_properties',
	[0x00800] = 'show_waves_on_cliff_shores',
	[0x01000] = 'show_waves_on_rolling_shores',
	[0x02000] = 'use_terrain_fog',
	[0x04000] = 'requires_expansion',
	[0x08000] = 'use_item_classification_system',
	[0x10000] = 'use_water_tinting_color',
	[0x20000] = 'use_accurate_probability',
	[0x40000] = 'use_custom_ability_skin'
}

local force_flags = {
	[0x01] = 'allied',
	[0x02] = 'allied_victory',
	[0x08] = 'share_vision',
	[0x10] = 'share_control',
	[0x20] = 'share_advanced_control'
}

local formats = {
	[18] = 'RoC',
	[25] = 'TFT',
	[28] = 'Lua',
	[31] = 'Reforged'
}

function W3I.unpack (input)
	assert (type (input) == 'string')

	local unpack = string.unpack
	local count

	local format,
		position = unpack ('< i4', input)

	assert (formats [format])

	local output = {
		format = format,
		map = {},
		camera = { {}, {}, {}, {} },
		margins = {},
		dimensions = {},
		loading = {},
		prologue = {}
	}

	output.saves,
	output.editor,
	position = unpack ('< i4 i4', input, position)

	if format >= 28 then
		output.version = {}

		output.version.major,
		output.version.minor,
		output.version.patch,
		output.version.build,
		position = unpack ('< i4 i4 i4 i4', input, position)
	end

	output.map.name,
	output.map.author,
	output.map.description,
	output.map.recommended,
	output.camera [1].x,
	output.camera [1].y,
	output.camera [2].x,
	output.camera [2].y,
	output.camera [3].x,
	output.camera [3].y,
	output.camera [4].x,
	output.camera [4].y,
	output.margins.left,
	output.margins.right,
	output.margins.top,
	output.margins.bottom,
	output.dimensions.width,
	output.dimensions.height,
	output.map.flags,
	output.tileset,
	position = unpack (
		'< z z z z f f f f f f f f i4 i4 i4 i4 i4 i4 I4 c1',
		input, position)

	output.map.flags = Flags.unpack (map_flags, output.map.flags)

	if format == 18 then
		output.campaign = {}

		output.campaign.background,
		output.loading.text,
		output.loading.title,
		output.loading.subtitle,
		output.loading.background,
		output.prologue.text,
		output.prologue.title,
		output.prologue.subtitle,
		position = unpack ('< i4 z z z i4 z z z', input, position)
	else
		output.fog = {
			z = {},
			color = {}
		}
		output.environment = {
			water = {}
		}

		output.loading.background,
		output.loading.model,
		output.loading.text,
		output.loading.title,
		output.loading.subtitle,
		output.game_data,
		output.prologue.model,
		output.prologue.text,
		output.prologue.title,
		output.prologue.subtitle,
		output.fog.index,
		output.fog.z.start,
		output.fog.z.finish,
		output.fog.density,
		output.fog.color.red,
		output.fog.color.green,
		output.fog.color.blue,
		output.fog.color.alpha,
		output.environment.weather,
		output.environment.sound,
		output.environment.light,
		output.environment.water.red,
		output.environment.water.green,
		output.environment.water.blue,
		output.environment.water.alpha,
		position = unpack (
			'< i4 z z z z i4 z z z z i4 f f f B B B B c4 z c1 B B B B',
			input, position)
	end

	if format >= 28 then
		output.script,
		position = unpack ('< i4', input, position)
	end

	if format >= 31 then
		output.graphics,
		output.game_data_version,
		position = unpack ('< i4 i4', input, position)
	end

	output.players = {}

	count,
	position = unpack ('< i4', input, position)

	for index = 1, count do
		local player = {
			start = {},
			ally = {}
		}
		output.players [index] = player

		player.index,
		player.type,
		player.race,
		player.start.fixed,
		player.name,
		player.start.x,
		player.start.y,
		player.ally.low,
		player.ally.high,
		position = unpack ('< i4 i4 i4 i4 z f f I4 I4', input, position)

		player.ally.low = Bits.unpack ('I4', player.ally.low)
		player.ally.high = Bits.unpack ('I4', player.ally.high)

		if format >= 31 then
			player.enemy = {}

			player.enemy.low,
			player.enemy.high,
			position = unpack ('< I4 I4', input, position)

			player.enemy.low = Bits.unpack ('I4', player.enemy.low)
			player.enemy.high = Bits.unpack ('I4', player.enemy.high)
		end
	end

	output.forces = {}

	count,
	position = unpack ('< i4', input, position)

	for index = 1, count do
		local force = {}
		output.forces [index] = force

		force.flags,
		force.players,
		force.name,
		position = unpack ('< I4 I4 z', input, position)

		force.flags = Flags.unpack (force_flags, force.flags)
		force.players = Bits.unpack ('I4', force.players)
	end

	output.upgrades = {}

	count,
	position = unpack ('< i4', input, position)

	for index = 1, count do
		local upgrade = {}
		output.upgrades [index] = upgrade

		upgrade.players,
		upgrade.id,
		upgrade.level,
		upgrade.availability,
		position = unpack ('< I4 c4 i4 i4', input, position)

		upgrade.players = Bits.unpack ('I4', upgrade.players)
	end

	output.tech = {}

	count,
	position = unpack ('< i4', input, position)

	for index = 1, count do
		local tech = {}
		output.tech [index] = tech

		tech.players,
		tech.id,
		position = unpack ('< I4 c4', input, position)

		tech.players = Bits.unpack ('I4', tech.players)
	end

	output.units = {}

	count,
	position = unpack ('< i4', input, position)

	for index = 1, count do
		local units = {
			rows = {}
		}
		output.units [index] = units

		units.index,
		units.name,
		units.columns,
		position = unpack ('< i4 z i4', input, position)

		local columns = units.columns
		units.type = { unpack (('i4'):rep (columns), input, position) }
		position = table.remove (units.type)

		count,
		position = unpack ('< i4', input, position)

		for row = 1, count do
			units.rows [row] = {}
			row = units.rows [row]

			row.chance,
			position = unpack ('< i4', input, position)

			row.id = { unpack (('c4'):rep (columns), input, position) }
			position = table.remove (row.id)
		end
	end

	if format >= 25 then
		output.item_tables = {}

		count,
		position = unpack ('< i4', input, position)

		for table = 1, count do
			local item_table = {}
			output.item_tables [table] = item_table

			item_table.index,
			item_table.name,
			count,
			position = unpack ('< i4 z i4', input, position)

			for set = 1, count do
				local items = {}
				item_table [set] = items

				count,
				position = unpack ('< i4', input, position)

				for index = 1, count do
					local item = {}
					items [index] = item

					item.chance,
					item.id,
					position = unpack ('< i4 c4', input, position)
				end
			end
		end
	end

	assert (#input == position - 1)

	return output
end

function W3I.pack (input)
	assert (type (input) == 'table')

	local pack = string.pack

	local output = {}
	local format = input.format or 31
	assert (formats [format])

	output [#output + 1] = pack (
		'< i4 i4 i4',
		format,
		input.saves,
		input.editor)

	if format >= 28 then
		output [#output + 1] = pack (
			'< i4 i4 i4 i4',
			input.version.major,
			input.version.minor,
			input.version.patch,
			input.version.build)
	end

	output [#output + 1] = pack (
		'< z z z z f f f f f f f f i4 i4 i4 i4 i4 i4 I4 c1',
		input.map.name,
		input.map.author,
		input.map.description,
		input.map.recommended,
		input.camera [1].x,
		input.camera [1].y,
		input.camera [2].x,
		input.camera [2].y,
		input.camera [3].x,
		input.camera [3].y,
		input.camera [4].x,
		input.camera [4].y,
		input.margins.left,
		input.margins.right,
		input.margins.top,
		input.margins.bottom,
		input.dimensions.width,
		input.dimensions.height,
		Flags.pack (map_flags, input.map.flags),
		input.tileset)

	if format == 18 then
		output [#output + 1] = pack (
		 '< i4 z z z i4 z z z',
		input.campaign.background,
		input.loading.text,
		input.loading.title,
		input.loading.subtitle,
		input.loading.background,
		input.prologue.text,
		input.prologue.title,
		input.prologue.subtitle)
	else
		output [#output + 1] = pack (
			'< i4 z z z z i4 z z z z i4 f f f B B B B c4 z c1 B B B B',
			input.loading.background,
			input.loading.model,
			input.loading.text,
			input.loading.title,
			input.loading.subtitle,
			input.game_data,
			input.prologue.model,
			input.prologue.text,
			input.prologue.title,
			input.prologue.subtitle,
			input.fog.index,
			input.fog.z.start,
			input.fog.z.finish,
			input.fog.density,
			input.fog.color.red,
			input.fog.color.green,
			input.fog.color.blue,
			input.fog.color.alpha,
			input.environment.weather,
			input.environment.sound,
			input.environment.light,
			input.environment.water.red,
			input.environment.water.green,
			input.environment.water.blue,
			input.environment.water.alpha)
	end

	if format >= 28 then
		output [#output + 1] = pack ('< i4', input.script)
	end

	if format >= 31 then
		output [#output + 1] = pack (
			'< i4 i4',
			input.graphics,
			input.game_data_version)
	end

	output [#output + 1] = pack ('< i4', #input.players)

	for _, player in ipairs (input.players) do
		output [#output + 1] = pack (
			'< i4 i4 i4 i4 z f f I4 I4',
			player.index,
			player.type,
			player.race,
			player.start.fixed,
			player.name,
			player.start.x,
			player.start.y,
			Bits.pack (player.ally.low),
			Bits.pack (player.ally.high))

		if format == 31 then
			output [#output + 1] = pack (
				'< I4 I4',
				Bits.pack (player.enemy.low),
				Bits.pack (player.enemy.high))
		end
	end

	output [#output + 1] = pack ('< i4', #input.forces)

	for _, force in ipairs (input.forces) do
		output [#output + 1] = pack (
			'< I4 I4 z',
			Flags.pack (force_flags, force.flags),
			Bits.pack (force.players),
			force.name)
	end

	output [#output + 1] = pack ('< i4', #input.upgrades)

	for _, upgrade in ipairs (input.upgrades) do
		output [#output + 1] = pack (
			'< I4 c4 i4 i4',
			Bits.pack (upgrade.players),
			upgrade.id,
			upgrade.level,
			upgrade.availability)
	end

	output [#output + 1] = pack ('< i4', #input.tech)

	for _, tech in ipairs (input.tech) do
		output [#output + 1] = pack (
			'< I4 c4',
			Bits.pack (tech.players),
			tech.id)
	end

	output [#output + 1] = pack ('< i4', #input.units)

	for _, units in ipairs (input.units) do
		output [#output + 1] = pack (
			'< i4 z i4 i4' .. ('i4'):rep (units.columns),
			units.index,
			units.name,
			units.columns,
			table.unpack (units.type),
			#units.rows)

		for _, row in ipairs (units.rows) do
			output [#output + 1] = pack (
				'< i4' .. ('c4'):rep (units.columns),
				row.chance,
				table.unpack (row.id))
		end
	end

	if format >= 25 then
		output [#output + 1] = pack ('< i4', #input.item_tables)

		for _, item_table in ipairs (input.item_tables) do
			output [#output + 1] = pack (
				'< i4 z i4',
				item_table.index,
				item_table.name,
				#item_table)

			for _, set in ipairs (item_table) do
				output [#output + 1] = pack ('< i4', #set)

				for _, item in ipairs (set) do
					output [#output + 1] = pack (
						'< i4 c4',
						item.chance,
						item.id)
				end
			end
		end
	end

	return table.concat (output)
end

return W3I
