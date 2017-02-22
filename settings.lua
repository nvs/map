local Path = require ('map.path')

local Settings = {}

do
	local unpack = table.unpack or unpack

	local flags = {}
	flags.__index = flags

	function flags.__call (self, object)
		self.object = object

		return self
	end

	local function has_flags (object)
		return type (object) == 'table' and getmetatable (object) == flags
	end

	local function set (options)
		local self = {
			optional = options.optional
		}

		return setmetatable (self, flags)
	end

	local configuration = {
		map = set {
			optional = true
		} {
			name = set {
				optional = true
			} 'string'
		},

		flags = set {
			optional = true
		} {
			debug = set {
				optional = true
			} 'boolean'
		},

		input = {
			map = 'string',
		},

		output = {
			directory = 'string',
			name = 'string'
		},

		environment = set {
			optional = true
		} {
			'string'
		},

		patch = {
			'string'
		},

		scripts = set {
			optional = true
		} {
			'string'
		},

		imports = set {
			optional = true
		} {
			'string'
		},

		objects = set {
			optional = true
		} {
			'string'
		},

		constants = set {
			optional = true
		} {
			gameplay = set {
				optional = true
			} {
				'string'
			},

			interface = set {
				optional = true
			} {
				'string'
			}
		},

		prefix = set {
			optional = true
		} 'string',

		pjass = set {
			optional = true
		} {
			options = set {
				optional = true
			} {
				'string'
			}
		},

		optimizer = set {
			optional = true
		} {
			tweaks = set {
				optional = true
			} 'string'
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
	function Settings.validate (A, B, name, errors)
		B = B or configuration
		errors = errors or {}

		for key, B_value in pairs (B) do
			local name = name

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
			elseif has_flags (B_value) and type (B_value.object) == 'string' then
				B_type = B_value.object
			else
				B_type = 'table'
			end

			if A_value == nil then
				if not has_flags (B_value) or not B_value.optional then
					table.insert (errors, { 'missing', name, B_type })
				end
			elseif A_type ~= B_type then
				table.insert (errors, { 'bad type', name, A_type, B_type })
			elseif B_type == 'table' then
				if has_flags (B_value) then
					B_value = B_value.object
				end

				if #B_value > 0 then
					local B_element_type = B_value [1]

					for _, A_element in ipairs (A_value) do
						if type (A_element) ~= B_element_type then
							table.insert (errors, { 'bad element type',
								name, type (A_element), B_element_type })
						end
					end
				else
					Settings.validate (A_value, B_value, name, errors)
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

-- Reads and processes the file specified by `configuration (string)`, then
-- returns the settings `table`. When an error is encountered, returns `nil`
-- along with a `message (string)`.
function Settings.read (configuration)
	local chunk, message = loadfile (configuration)

	if not chunk then
		return nil, 'parse error: ' .. message
	end

	local settings = chunk ()

	local is_valid, message = Settings.validate (settings)

	if not is_valid then
		return nil, message
	end

	-- These are optional settings that have 'default' values needed for tools
	-- to function properly.
	settings.map = settings.map or {}
	settings.flags = settings.flags or {
		debug = false
	}
	settings.environment = settings.environment or {}
	settings.scripts = settings.scripts or {}
	settings.imports = settings.imports or {}
	settings.objects = settings.objects or {}
	settings.constants = settings.constants or {}
	settings.constants.gameplay = settings.constants.gameplay or {}
	settings.constants.interface = settings.constants.interface or {}
	settings.pjass = settings.pjass or {}
	settings.optimizer = settings.optimizer or {}

	return settings
end

-- Does final checks on the provided `settings (table)`. This is intended to
-- be called after loading a customized environment.
function Settings.finalize (settings)
	-- If prefix is an empty string, we set it to `nil`. This is necessary to
	-- ensure the first command line argument is not an empty string.
	if settings.prefix == '' then
		settings.prefix = nil
	end

	-- Setup the output files.
	settings.output.map = Path.join (
		settings.output.directory, settings.output.name ..
		settings.input.map:match ('^.+(%..+)$'))
	settings.output.script = settings.output.map .. '.j'
	settings.output.globals = Path.join (
		settings.output.directory, 'globals.lua')
end

return Settings
