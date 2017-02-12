local Path = require ('map.path')

local Settings = {}

local validate
do
	local unpack = table.unpack or unpack

	local configuration = {
		name = 'string',

		flags = {
			debug = 'boolean'
		},

		input = {
			map = 'string',
		},

		output = {
			directory = 'string'
		},

		patch = {
			directory = 'string',
			files = {
				'string'
			}
		},

		scripts = {
			directory = 'string',
			files = {
				'string'
			}
		},

		imports = {
			directory = 'string'
		},

		objects = {
			directory = 'string',
			files = {
				'string'
			}
		},

		constants = {
			gameplay = {
				directory = 'string',
				files = {
					'string'
				}
			},

			interface = {
				directory = 'string',
				files = {
					'string'
				}
			}
		},

		prefix = 'string',

		pjass = {
			options = {
				'string'
			}
		},

		optimizer = {
			tweaks = 'string'
		}
	}

	local function display (errors)
		local messages = { 'invalid configuration:' }

		for _, message in ipairs (errors) do
			if message [1] == 'missing' then
				table.insert (messages, string.format (
					'\t%s \'%s\' (`%s`)', unpack (message)))
			elseif message [1] == 'bad type'
				or message [1] == 'bad element type'
			then
				table.insert (messages, string.format (
					'\t%s \'%s\' (got `%s`, expected `%s`)', unpack (message)))
			end
		end

		return table.concat (messages, '\n')
	end

	-- Compares `A (table)` with `B (table)`, assuming that `B` represents a
	-- specification that `A` should follow. Returns `true (boolean)` if `A`
	-- validates against `B`. Otherwise, returns `nil` with an error `message
	-- (string)`.
	function validate (A, B, name, errors)
		B = B or configuration
		errors = errors or {}

		for key, B_value in pairs (B) do
			local name

			if name then
				name = name .. '.' .. key
			else
				name = key
			end

			local A_value = A [key]
			local A_type = type (A_value)

			local B_type

			if type (B_value) == 'string' then
				B_type = B_value
			else
				B_type = type (B_value)
			end

			if A_value == nil then
				table.insert (errors, { 'missing', name, B_type })
			elseif A_type ~= B_type then
				table.insert (errors, { 'bad type', name, A_type, B_type })
			elseif B_type == 'table' then
				if #B_value > 0 then
					local B_element_type = B_value [1]

					for _, A_element in ipairs (A_value) do
						if type (A_element) ~= B_element_type then
							table.insert (errors, { 'bad element type',
								name, type (A_element), B_element_type })
						end
					end
				else
					validate (A_value, B_value, name, errors)
				end
			end
		end

		if not name and #errors > 0 then
			return nil, display (errors)
		else
			return true
		end
	end
end

-- Reads and processes the configuration file specified within `arg [1]`, then
-- returns the settings `table`. When an error is encountered, returns `nil`
-- along with a `message (string)`.
function Settings.read ()
	local chunk, message = loadfile (arg [1])

	if not chunk then
		return nil, 'parse error: ' .. message
	end

	local settings = chunk ()

	local is_valid, message = validate (settings)

	if not is_valid then
		return nil, message
	end

	-- If prefix is an empty string, we set it to `nil`. This is necessary to
	-- ensure the first command line argument is not an empty string.
	if settings.prefix == '' then
		settings.prefix = nil
	end

	-- Setup the output files.
	settings.output.map = Path.join (
		settings.output.directory, settings.name ..
		settings.input.map:match ('^.+(%..+)$'))
	settings.output.script = settings.output.map .. '.j'
	settings.output.globals = Path.join (
		settings.output.directory, 'globals.lua')

	return settings
end

return Settings
