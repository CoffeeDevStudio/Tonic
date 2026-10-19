-- Declarative options. The core and other addons register categories and options;
-- Tonic_Config renders them with Tonic components (dogfooding).
--
--   T.Options:AddCategory("appearance", { title = "Appearance", order = 10 })
--   T.Options:Add("appearance", { type = "slider", key = "theme.hudOpacity", label = "HUD opacity",
--     min = 0.6, max = 1, step = 0.01, set = function(v) T.Theme:SetHudOpacity(v) end })
--
-- Types: header, description, toggle, slider, radio, select, button, input, and the
-- custom renderers "skins", "profiles", "about" provided by Tonic_Config.

local T = Tonic

---@class TonicOption
---@field type string
---@field key string? path in the active profile, e.g. "theme.mode"
---@field label string?
---@field desc string?
---@field order number?
---@field choices table|fun(): table? { { value = v, label = "..." }, ... } for radio/select
---@field min number?
---@field max number?
---@field step number?
---@field format fun(value: number): string?
---@field get fun(): any?
---@field set fun(value: any)?
---@field disabled fun(): boolean?
---@field reload boolean? the change needs /reload
---@field onClick fun()? for buttons

---@class TonicOptions
local Options = {
	categories = {}, ---@type table<string, table>
	options = {},    ---@type table<string, TonicOption[]>
}
T.Options = Options

---Reads a dotted path from a table.
---@param tbl table
---@param path string
function Options.GetPath(tbl, path)
	local value = tbl
	for part in path:gmatch("[^%.]+") do
		if type(value) ~= "table" then return nil end
		value = value[part]
	end
	return value
end

---Writes a dotted path into a table, creating sub-tables.
---@param tbl table
---@param path string
---@param value any
function Options.SetPath(tbl, path, value)
	local parts = {}
	for part in path:gmatch("[^%.]+") do parts[#parts + 1] = part end
	local node = tbl
	for i = 1, #parts - 1 do
		if type(node[parts[i]]) ~= "table" then node[parts[i]] = {} end
		node = node[parts[i]]
	end
	node[parts[#parts]] = value
end

---@param id string
---@param def { title: string, icon: string?, order: number? }
function Options:AddCategory(id, def)
	def.id = id
	def.order = def.order or 100
	self.categories[id] = def
	self.options[id] = self.options[id] or {}
end

---@param categoryId string
---@param option TonicOption
function Options:Add(categoryId, option)
	local list = self.options[categoryId]
	assert(list, "Unknown options category: " .. tostring(categoryId))
	option.order = option.order or (#list + 1) * 10
	list[#list + 1] = option
end

---@return table[] categories sorted by order
function Options:GetCategories()
	local list = {}
	for _, def in pairs(self.categories) do list[#list + 1] = def end
	table.sort(list, function(a, b)
		if a.order == b.order then return a.id < b.id end
		return a.order < b.order
	end)
	return list
end

---@param categoryId string
---@return TonicOption[] sorted by order
function Options:GetOptions(categoryId)
	local list = {}
	for i, option in ipairs(self.options[categoryId] or {}) do list[i] = option end
	table.sort(list, function(a, b) return a.order < b.order end)
	return list
end

---@param option TonicOption
function Options:GetValue(option)
	if option.get then return option.get() end
	if option.key then return Options.GetPath(T.db.profile, option.key) end
end

---@param option TonicOption
---@param value any
function Options:SetValue(option, value)
	if option.key then Options.SetPath(T.db.profile, option.key, value) end
	if option.set then option.set(value) end
	T.Events:SendMessage("Tonic.OptionChanged", option, value)
end

---@param option TonicOption
---@return table
function Options:GetChoices(option)
	local choices = option.choices
	if type(choices) == "function" then choices = choices() end
	return choices or {}
end

---@param option TonicOption
---@return boolean
function Options:IsDisabled(option)
	return option.disabled ~= nil and option.disabled() or false
end
