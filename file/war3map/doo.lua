-- luacheck: std lua53
if _VERSION < 'Lua 5.3' then
	require ('compat53')
end

local Flags = require ('map.file.flags')

local Doodads_DOO = {}

local unpack = string.unpack
local pack = string.pack

local flags = {
	[0x01] = 'solid',
	[0x02] = 'visible',
	[0x04] = 'fixed_z'
}

function Doodads_DOO.unpack (input, version)
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

		if version.minor >= 32 then
			doodad.skin,
			position = unpack ('c4', input, position)
		end

		doodad.flags,
		doodad.life,
		position = unpack ('B B', input, position)

		doodad.flags = Flags.unpack (flags, doodad.flags)

		if format == 8 then
			doodad.item_table = {}

			doodad.map_item_table,
			count,
			position = unpack ('< i4 i4', input, position)

			for set = 1, count do
				local items = {}
				doodad.item_table [set] = items

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
		end

		doodad.id,
		position = unpack ('< i4', input, position)
	end

	output.special = {}

	output.special.format,
	count,
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

	assert (#input == position - 1)

	return output
end

function Doodads_DOO.pack (input, version)
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

		if version.minor >= 32 then
			output [#output + 1] = pack ('c4', doodad.skin)
		end

		output [#output + 1] = pack (
			'B B',
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

		output [#output + 1] = pack ('< i4', doodad.id)
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
