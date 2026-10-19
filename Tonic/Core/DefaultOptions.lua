-- Core options (rendered by Tonic_Config) and the entry points to open it:
-- /tonic config, minimap button, addon compartment, Blizzard Settings panel.

local T = Tonic
local L = T.L

local Options = T.Options

Options:AddCategory("appearance", { title = L["Appearance"], icon = "palette", order = 10 })
Options:AddCategory("skins", { title = L["Skins"], icon = "tune", order = 20 })
Options:AddCategory("profiles", { title = L["Profiles"], icon = "person", order = 30 })
Options:AddCategory("about", { title = L["About"], icon = "info", order = 40 })

local function seedChoices()
	local choices = { { value = "auto", label = L["Your class"] } }
	for _, seed in ipairs(T.Scheme:GetSeeds()) do
		local name = seed == T.Scheme.DEFAULT_SEED and "Tonic"
			or (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[seed]) or seed
		choices[#choices + 1] = { value = seed, label = name .. "  #" .. T.Scheme:GetSeedHex(seed) }
	end
	return choices
end

Options:Add("appearance", { type = "header", label = L["Color"] })
Options:Add("appearance", {
	type = "radio", key = "theme.mode", label = L["Mode"],
	choices = { { value = "dark", label = L["Dark"] }, { value = "light", label = L["Light"] } },
	set = function() T.Theme:Refresh() end,
})
Options:Add("appearance", {
	type = "select", key = "theme.seed", label = L["Seed color"],
	desc = L["Dynamic color takes your class color as its seed."],
	choices = seedChoices,
	set = function() T.Theme:Refresh() end,
})
Options:Add("appearance", {
	type = "toggle", key = "theme.harmonizeHealth", label = L["Harmonize health"],
	desc = L["With warm seeds the harmonized health drifts towards yellow-green. Turn off to keep it green."],
	set = function() T.Theme:Refresh() end,
})
Options:Add("appearance", { type = "header", label = L["Surfaces"] })
Options:Add("appearance", {
	type = "slider", key = "theme.hudOpacity", label = L["HUD panel opacity"],
	min = 0.6, max = 1, step = 0.01,
	format = function(v) return ("%d%%"):format(v * 100 + 0.5) end,
	set = function(v) T.Theme:SetHudOpacity(v) end,
})
Options:Add("appearance", { type = "header", label = L["Motion"] })
Options:Add("appearance", {
	type = "toggle", key = "theme.ripple", label = L["Ripple"], desc = L["Ripple effect when pressing."],
	set = function() T.Theme:Refresh() end,
})
Options:Add("appearance", {
	type = "toggle", key = "theme.motion", label = L["Animations"], desc = L["Transitions of switches, tabs and windows."],
	set = function() T.Theme:Refresh() end,
})
Options:Add("appearance", { type = "header", label = L["Interface"] })
Options:Add("appearance", {
	type = "toggle", label = L["Minimap button"],
	get = function() return not T.db.global.minimap.hide end,
	set = function(v) T:GetModule("Minimap"):SetShown(v) end,
})

Options:Add("skins", { type = "skins" })
Options:Add("profiles", { type = "profiles" })
Options:Add("about", { type = "about" })

-- ------------------------------------------------------------- open the configuration

---Loads Tonic_Config (LoadOnDemand) and toggles its window.
function T:OpenConfig()
	if not C_AddOns.IsAddOnLoaded("Tonic_Config") then
		local loaded, reason = C_AddOns.LoadAddOn("Tonic_Config")
		if not loaded then
			T:Print(L["Cannot load Tonic_Config:"], _G["ADDON_" .. tostring(reason)] or tostring(reason))
			return
		end
	end
	if T.Config then T.Config:Toggle() end
end

-- Blizzard Settings: a small page that opens the Tonic window.
local module = T:NewModule("SettingsPanel")

function module:OnEnable()
	if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
	local panel = CreateFrame("Frame")
	local logo = T.Logo:Create(panel, 64)
	T.Scale:SetPoint(logo, "TOPLEFT", panel, "TOPLEFT", 16, -16)
	local title = T.Text:Acquire(panel, { role = "headlineMedium", color = "onSurface", text = "Tonic" })
	T.Scale:SetPoint(title, "LEFT", logo, "RIGHT", 16, 8)
	local subtitle = T.Text:Acquire(panel, { role = "bodyMedium", color = "onSurfaceVariant",
		text = L["Material 3 for WoW · your UI in your class colors"] })
	T.Scale:SetPoint(subtitle, "TOPLEFT", title, "BOTTOMLEFT", 0, -4)
	local open = T.Button:Acquire(panel, { text = L["Open Tonic options"], icon = "settings",
		onClick = function() T:OpenConfig() end })
	T.Scale:SetPoint(open, "TOPLEFT", logo, "BOTTOMLEFT", 0, -24)
	local category = Settings.RegisterCanvasLayoutCategory(panel, "Tonic")
	Settings.RegisterAddOnCategory(category)
end
