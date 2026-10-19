-- Skin engine: registry of skins for Blizzard areas. Each skin runs isolated in
-- xpcall, has a toggle in the options and declares the frames it expects, which
-- `/tonic audit` checks after every patch. Skins for load-on-demand Blizzard addons
-- wait for their ADDON_LOADED. Skins live in Tonic_Skins (LoadOnDemand), loaded at login.
--
--   T.Skins:Register("Character", { label = "Character", expects = { "CharacterFrame" },
--     apply = function(skin) ... end })

local T = Tonic

T.DB:AddDefaults("profile", { skins = {} })

---@class TonicSkinDef
---@field name string
---@field label string?
---@field desc string?
---@field addon string? Blizzard load-on-demand addon that creates the frames
---@field expects string[]? global paths ("CharacterFrame.NineSlice") checked by the audit
---@field apply fun(skin: TonicSkinDef)
---@field order number?
---@field status "pending"|"waiting"|"ok"|"error"|"disabled"|"missing"
---@field error string?

---@class TonicSkins
local Skins = {
	registry = {}, ---@type table<string, TonicSkinDef>
	order = {},    ---@type TonicSkinDef[]
}
T.Skins = Skins

local started = false

---Resolves a dotted global path ("A.B.C"); nil if any part is missing.
---@param path string
---@return any
function Skins.Resolve(path)
	local value = _G
	for part in path:gmatch("[^%.]+") do
		if type(value) ~= "table" then return nil end
		value = value[part]
	end
	return value
end

---@param name string
---@param def TonicSkinDef
function Skins:Register(name, def)
	assert(not self.registry[name], "Tonic skin already registered: " .. name)
	def.name = name
	def.status = "pending"
	def.order = def.order or (#self.order + 1)
	self.registry[name] = def
	self.order[#self.order + 1] = def
	if started then self:TryApply(def) end
end

---@param name string
---@return boolean
function Skins:IsEnabled(name)
	return T.db.profile.skins[name] ~= false
end

---Takes effect after /reload: a skin cannot be removed from Blizzard frames safely.
---@param name string
---@param enabled boolean
function Skins:SetEnabled(name, enabled)
	if enabled then
		T.db.profile.skins[name] = nil
	else
		T.db.profile.skins[name] = false
	end
end

---@param def TonicSkinDef
function Skins:TryApply(def)
	if def.status == "ok" or def.status == "error" then return end
	if not self:IsEnabled(def.name) then
		def.status = "disabled"
		return
	end
	if def.addon and not C_AddOns.IsAddOnLoaded(def.addon) then
		def.status = "waiting"
		return
	end
	-- After a patch renames a frame the skin is skipped, not run into an error.
	for _, path in ipairs(def.expects or {}) do
		if Skins.Resolve(path) == nil then
			def.status = "missing"
			return
		end
	end
	local ok = xpcall(def.apply, function(err)
		def.error = tostring(err)
		geterrorhandler()(err)
	end, def)
	def.status = ok and "ok" or "error"
end

---@return TonicSkinDef[]
function Skins:GetAll()
	table.sort(self.order, function(a, b) return a.order < b.order end)
	return self.order
end

---Checks every skin: status and the expected frames that are missing.
---@return { name: string, status: string, missing: string[], error: string? }[]
function Skins:Audit()
	local report = {}
	for _, def in ipairs(self:GetAll()) do
		local missing = {}
		local check = def.status ~= "waiting" and def.status ~= "disabled"
		for _, path in ipairs(def.expects or {}) do
			if check and Skins.Resolve(path) == nil then missing[#missing + 1] = path end
		end
		report[#report + 1] = { name = def.name, status = def.status, missing = missing, error = def.error }
	end
	return report
end

-- ------------------------------------------------------------- lifecycle

local module = T:NewModule("Skins")

function module:OnEnable()
	-- Tonic_Skins registers the skins when it loads.
	local name = "Tonic_Skins"
	local loadable = C_AddOns.GetAddOnInfo and select(4, C_AddOns.GetAddOnInfo(name))
	if loadable ~= false and not C_AddOns.IsAddOnLoaded(name) then
		C_AddOns.LoadAddOn(name)
	end
	started = true
	for _, def in ipairs(Skins:GetAll()) do Skins:TryApply(def) end
	T.Events:RegisterEvent("ADDON_LOADED", self)
end

function module:ADDON_LOADED(_, addon)
	for _, def in ipairs(Skins.order) do
		if def.status == "waiting" and def.addon == addon then Skins:TryApply(def) end
	end
end
