-- SavedVariables: TonicDB (account: profiles + global) and TonicCharDB (character).
-- Defaults are filled in on load and stripped on logout, so changing a default
-- later reaches every user who never changed that value. Schema migrations run
-- in order before the defaults are applied.

local T = Tonic

---@class TonicDB
---@field profile table active profile (set after Initialize)
---@field global table
---@field char table
local DB = {
	SCHEMA = 1,
	CHAR_SCHEMA = 1,
	DEFAULT_PROFILE = "Default",
}
T.DB = DB

DB.defaults = { profile = {}, global = {}, char = {} }

---@type table<integer, fun(db: table)>
DB.migrations = {}
---@type table<integer, fun(db: table)>
DB.charMigrations = {}

-- ------------------------------------------------------------- pure helpers

---Deep copy of a table (non-table values are returned as is).
function DB.CopyTable(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for k, v in pairs(value) do copy[k] = DB.CopyTable(v) end
	return copy
end

---Fills every key of defaults missing from target (deep). Existing values win,
---including values of a different type.
---@param target table
---@param defaults table
---@return table target
function DB.MergeDefaults(target, defaults)
	for k, v in pairs(defaults) do
		local current = target[k]
		if current == nil then
			target[k] = DB.CopyTable(v)
		elseif type(current) == "table" and type(v) == "table" then
			DB.MergeDefaults(current, v)
		end
	end
	return target
end

---Removes from target every value equal to its default; empty sub-tables go too.
---@param target table
---@param defaults table
---@return table target
function DB.StripDefaults(target, defaults)
	for k, v in pairs(defaults) do
		local current = target[k]
		if type(current) == "table" and type(v) == "table" then
			DB.StripDefaults(current, v)
			if next(current) == nil then target[k] = nil end
		elseif current == v then
			target[k] = nil
		end
	end
	return target
end

---Runs migrations[v] for every v in (data.schema, latest], then stamps data.schema.
---@param data table
---@param migrations table<integer, fun(db: table)>
---@param latest integer
---@return integer applied number of migrations run
function DB.RunMigrations(data, migrations, latest)
	local from = data.schema
	if from == nil then
		-- Fresh install: nothing to migrate.
		data.schema = latest
		return 0
	end
	local applied = 0
	for v = from + 1, latest do
		local migrate = migrations[v]
		if migrate then
			migrate(data)
			applied = applied + 1
		end
		data.schema = v
	end
	return applied
end

---Adds defaults for a scope ("profile", "global" or "char"). Call at file load,
---before ADDON_LOADED.
---@param scope "profile"|"global"|"char"
---@param defaults table
function DB:AddDefaults(scope, defaults)
	DB.MergeDefaults(self.defaults[scope], defaults)
end

-- ------------------------------------------------------------- lifecycle

local function characterKey()
	return (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")
end

function DB:Initialize()
	TonicDB = TonicDB or {}
	TonicCharDB = TonicCharDB or {}
	local account, char = TonicDB, TonicCharDB

	DB.RunMigrations(account, self.migrations, self.SCHEMA)
	DB.RunMigrations(char, self.charMigrations, self.CHAR_SCHEMA)

	account.profileKeys = account.profileKeys or {}
	account.profiles = account.profiles or {}
	account.global = DB.MergeDefaults(account.global or {}, self.defaults.global)
	DB.MergeDefaults(char, self.defaults.char)

	self.account = account
	self.charKey = characterKey()
	self.global = account.global
	self.char = char
	self:SetProfile(account.profileKeys[self.charKey] or self.DEFAULT_PROFILE, true)

	T.Events:RegisterEvent("PLAYER_LOGOUT", self)
end

function DB:PLAYER_LOGOUT()
	for _, profile in pairs(self.account.profiles) do
		DB.StripDefaults(profile, self.defaults.profile)
	end
	DB.StripDefaults(self.account.global, self.defaults.global)
	DB.StripDefaults(self.char, self.defaults.char)
end

-- ------------------------------------------------------------- profiles

---@return string
function DB:GetProfileName()
	return self.profileName
end

---Switches the active profile of this character, creating it if needed.
---@param name string
---@param silent? boolean do not send Tonic.ProfileChanged
function DB:SetProfile(name, silent)
	local profiles = self.account.profiles
	profiles[name] = DB.MergeDefaults(profiles[name] or {}, self.defaults.profile)
	self.account.profileKeys[self.charKey] = name
	self.profileName = name
	self.profile = profiles[name]
	T.db = self
	if not silent then T.Events:SendMessage("Tonic.ProfileChanged", name) end
end

---@return string[] names sorted alphabetically
function DB:GetProfiles()
	local names = {}
	for name in pairs(self.account.profiles) do names[#names + 1] = name end
	table.sort(names)
	return names
end

---Replaces the active profile with a copy of another one.
---@param source string
function DB:CopyProfile(source)
	local src = self.account.profiles[source]
	if not src or source == self.profileName then return end
	self.account.profiles[self.profileName] = DB.CopyTable(src)
	self:SetProfile(self.profileName)
end

---Deletes a profile that is not active. Characters using it fall back to Default.
---@param name string
function DB:DeleteProfile(name)
	if name == self.profileName then return end
	self.account.profiles[name] = nil
	for key, profile in pairs(self.account.profileKeys) do
		if profile == name then self.account.profileKeys[key] = nil end
	end
end

function DB:ResetProfile()
	self.account.profiles[self.profileName] = {}
	self:SetProfile(self.profileName)
end
