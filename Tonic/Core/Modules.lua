-- Module lifecycle.
--   OnInitialize: ADDON_LOADED of Tonic, after the DB is ready.
--   OnEnable:     PLAYER_LOGIN (or immediately, if enabled later), when not disabled in the profile.
--   OnDisable:    when disabled at runtime.
-- Every callback runs isolated in xpcall.

local T = Tonic

---@class TonicModule
---@field name string
---@field enabled boolean
---@field OnInitialize fun(self: TonicModule)?
---@field OnEnable fun(self: TonicModule)?
---@field OnDisable fun(self: TonicModule)?

local modules = {}  ---@type table<string, TonicModule>
local order = {}    ---@type TonicModule[]
local initialized, loggedIn = false, false

T.DB:AddDefaults("profile", { modules = {} })

local function call(module, method)
	local fn = module[method]
	if fn then xpcall(fn, geterrorhandler(), module) end
end

local function isWanted(module)
	return T.db.profile.modules[module.name] ~= false
end

---Creates and registers a module.
---@param name string
---@param module? table
---@return TonicModule
function T:NewModule(name, module)
	assert(not modules[name], "Tonic module already exists: " .. name)
	module = module or {}
	module.name = name
	module.enabled = false
	modules[name] = module
	order[#order + 1] = module
	if initialized then call(module, "OnInitialize") end
	if loggedIn and isWanted(module) then T:EnableModule(name) end
	return module
end

---@param name string
---@return TonicModule?
function T:GetModule(name)
	return modules[name]
end

---@return fun(): integer?, TonicModule
function T:IterateModules()
	return ipairs(order)
end

---@param name string
function T:EnableModule(name)
	local module = modules[name]
	if not module then return end
	T.db.profile.modules[name] = nil
	if module.enabled or not loggedIn then return end
	module.enabled = true
	call(module, "OnEnable")
end

---@param name string
function T:DisableModule(name)
	local module = modules[name]
	if not module then return end
	T.db.profile.modules[name] = false
	if not module.enabled then return end
	module.enabled = false
	call(module, "OnDisable")
end

local Lifecycle = {}

function Lifecycle:ADDON_LOADED(_, addon)
	if addon ~= T.name then return end
	T.Events:UnregisterEvent("ADDON_LOADED", Lifecycle)
	T.DB:Initialize()
	initialized = true
	for _, module in ipairs(order) do call(module, "OnInitialize") end
end

function Lifecycle:PLAYER_LOGIN()
	loggedIn = true
	for _, module in ipairs(order) do
		if isWanted(module) then T:EnableModule(module.name) end
	end
end

T.Events:RegisterEvent("ADDON_LOADED", Lifecycle)
T.Events:RegisterEvent("PLAYER_LOGIN", Lifecycle)
