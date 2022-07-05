-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Flags = require ('map.file.flags')

local Doodads_DOO = {}

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

local flags = {
	[0x01] = 'solid',
	[0x02] = 'visible',
	[0x04] = 'fixed_z',
	[0x08] = 'unknown_0x08',
	[0x10] = 'unknown_0x10',
}

function Doodads_DOO.unpack (input, position)
	local magic, count
	local output = {}

	magic, output.format, output.subformat, count,
	position = unpack ('< c4 i4 i4 i4', input, position)

	assert (magic == 'W3do')
	assert (is_format [output.format])
	assert (is_subformat [output.subformat])

	for doodad = 1, count do
		output [doodad] = {
			position = {},
			scale = {}
		}
		doodad = output [doodad]

		doodad.type,
		doodad.variation,
		doodad.position.x,
		doodad.position.y,
		doodad.position.z,
		doodad.angle,
		doodad.scale.x,
		doodad.scale.y,
		doodad.scale.z,
		position = unpack ('< c4 i4 f f f f f f f', input, position)

		-- Degrees are used in other files.  Match that behavior.
		doodad.angle = math.deg (doodad.angle)

		-- Following the behavior at https://github.com/Drake53/War3Net, we
		-- check to see if the next character is printable.  If so, we make
		-- the assumption that the newest format is used.  This imposes a
		-- hard limit of 5-bits for flags.
		local is_reforged = unpack ('< B', input) >= 0x20

		if is_reforged then
			doodad.skin,
			position = unpack ('< c4', input, position)
		end

		doodad.flags,
		doodad.life,
		position = unpack ('< B B', input, position)

		doodad.flags = Flags.unpack (flags, doodad.flags)

		if output.format >= 8 then
			doodad.item_table = {}

			doodad.map_item_table, count,
			position = unpack ('< i4 i4', input, position)

			for set = 1, count do
				local items = {}
				doodad.item_table [set] = items

				count,
				position = unpack ('< i4', input, position)

				for index = 1, count do
					local item = {}
					items [index] = item

					item.id, item.chance,
					position = unpack ('< c4 i4', input, position)

				end
			end
		end

		doodad.index,
		position = unpack ('< i4', input, position)
	end

	output.special = {}

	output.special.format, count,
	position = unpack ('< i4 i4', input, position)

	for index = 1, count do
		local special = {
			position = {}
		}
		output.special [index] = special

		special.type,
		special.variation,
		special.position.x,
		special.position.y,
		position = unpack ('< c4 i4 i4 i4', input, position)
	end

	return output, position
end

function Doodads_DOO.pack (input)
	assert (is_format [input.format])
	assert (is_subformat [input.subformat])

	local output = {}

	output [#output + 1] = pack (
		'< c4 i4 i4 i4',
		'W3do',
		input.format,
		input.subformat,
		#input)

	for _, doodad in ipairs (input) do
		output [#output + 1] = pack (
			'< c4 i4 f f f f f f f',
			doodad.type,
			doodad.variation,
			doodad.position.x,
			doodad.position.y,
			doodad.position.z,
			math.rad (doodad.angle),
			doodad.scale.x,
			doodad.scale.y,
			doodad.scale.z)

		if doodad.skin then
			output [#output + 1] = pack ('c4', doodad.skin)
		end

		output [#output + 1] = pack (
			'< B B',
			Flags.pack (flags, doodad.flags),
			doodad.life)

		if input.format == 8 then
			output [#output + 1] = pack (
				'< i4 i4',
				doodad.map_item_table,
				#doodad.item_table)

			for _, set in ipairs (doodad.item_table) do
				output [#output + 1] = pack ('< i4', #set)

				for _, item in ipairs (set) do
					output [#output + 1] = pack (
						'< c4 i4',
						item.id,
						item.chance)
				end
			end
		end

		output [#output + 1] = pack ('< i4', doodad.index)
	end

	output [#output + 1] = pack (
		'< i4 i4',
		input.special.format,
		#input.special)

	for _, special in ipairs (input.special) do
		output [#output + 1] = pack (
			'< c4 i4 i4 i4',
			special.type,
			special.variation,
			special.position.x,
			special.position.y)
	end

	return table.concat (output)
end

return Doodads_DOO
