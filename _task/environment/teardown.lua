local function teardown_objects (self)
	for id, object in pairs (self.objects) do
		local type = object.type
		local category = self [type]

		if not category then
			category = {
				format = 2
			}
			self [type] = category
		end

		category [id] = object
	end

	self.objects = nil
end

local function teardown_constants (self)
	for name, category in pairs (self.constants) do
		self [name] = category
	end

	self.constants = nil
end

local unloaders = {
	information = true,
	imports = true,
	objects = teardown_objects,
	constants = teardown_constants,

	strings = true,
	regions = true,
	sounds = true,
	cameras = true,
	doodads = true,
	units = true,
	terrain = true,
	pathing = true
}

return function (state)
	local environment = state.environment
	setmetatable (environment, nil)

	local names = {}

	for name in pairs (environment) do
		names [#names + 1] = name
	end

	for _, name in ipairs (names) do
		local unloader = unloaders [name]

		if unloader then
			if type (unloader) == 'function' then
				unloader (environment)
			end
		else
			environment [name] = nil
		end
	end

	return true
end
