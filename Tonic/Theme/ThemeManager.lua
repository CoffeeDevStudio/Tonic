-- ThemeManager: builds themes (seed + mode) and pushes the current one to every
-- registered object through :ApplyTheme(theme). There is exactly one, in the core.

local T = Tonic

T.DB:AddDefaults("profile", {
	theme = {
		mode = "dark",     -- "dark" | "light"
		seed = "auto",     -- "auto" = class of the character, or a classFile / "DEFAULT"
		hudOpacity = 0.88, -- 0.60..1.00
		ripple = true,
		motion = true,
		harmonizeHealth = true, -- false: health keeps its base hue (readability with warm seeds)
	},
})

local HUD_OPACITY_MIN, HUD_OPACITY_MAX = 0.60, 1.00

-- ------------------------------------------------------------- theme object

---@class TonicTheme
---@field seed string
---@field mode "dark"|"light"
---@field roles table<string, TonicColor>
---@field semantic table<string, table<string, TonicColor>>
---@field hudOpacity number
---@field ripple boolean
local ThemeMixin = {}

local WHITE = { 1, 1, 1 }

---Resolves a color: a scheme role ("primary"), an elevation tone or usage
---("high", "window") or a semantic token ("health.bar").
---@param name string
---@return TonicColor
function ThemeMixin:Color(name)
	local c = self.roles[name]
	if c then return c end
	local group, tone = name:match("^(%w+)%.(%w+)$")
	if group then
		local sem = self.semantic[group]
		c = sem and sem[tone]
	else
		local role = T.Elevation:Role(name)
		c = role and self.roles[role]
	end
	if not c then
		geterrorhandler()("Tonic: unknown color " .. tostring(name))
		return WHITE
	end
	return c
end

---@param name string
---@return number r, number g, number b
function ThemeMixin:RGB(name)
	local c = self:Color(name)
	return c[1], c[2], c[3]
end

---@return boolean
function ThemeMixin:IsDark()
	return self.mode == "dark"
end

-- ------------------------------------------------------------- manager

---@class TonicThemeManager
local ThemeManager = {}
T.Theme = ThemeManager

local registry = setmetatable({}, { __mode = "k" }) ---@type table<table, boolean>
local cache = {}   ---@type table<string, TonicTheme>
local current      ---@type TonicTheme?

---@param seed string
---@param mode "dark"|"light"
---@return TonicTheme
function ThemeManager:Build(seed, mode)
	if not T.Scheme:HasSeed(seed) then seed = T.Scheme.DEFAULT_SEED end
	local key = seed .. ":" .. mode
	local theme = cache[key]
	if not theme then
		local palette = T.Scheme:Get(seed, mode)
		theme = CreateFromMixins(ThemeMixin)
		theme.seed = seed
		theme.mode = mode
		theme.roles = palette.roles
		theme.semantic = palette.semantic
		cache[key] = theme
	end
	-- User options are applied on top of the cached colors.
	local options = T.db and T.db.profile.theme
	theme.hudOpacity = options and options.hudOpacity or 0.88
	theme.ripple = not options or options.ripple ~= false
	local palette = T.Scheme:Get(theme.seed, mode)
	if options and options.harmonizeHealth == false then
		theme.semantic = setmetatable({ health = palette.semantic.healthBase }, { __index = palette.semantic })
	else
		theme.semantic = palette.semantic
	end
	T.Motion.enabled = not options or options.motion ~= false
	return theme
end

---Seed actually in use: the override, or the class of the character.
---@return string
function ThemeManager:GetSeed()
	local seed = T.db.profile.theme.seed
	if seed == "auto" or not T.Scheme:HasSeed(seed) then
		local _, classFile = UnitClass("player")
		seed = classFile and T.Scheme:HasSeed(classFile) and classFile or T.Scheme.DEFAULT_SEED
	end
	return seed
end

---@return TonicTheme
function ThemeManager:GetTheme()
	if not current then self:Refresh(true) end
	return current
end

---Registers an object: it receives the current theme now and on every change.
---@param obj { ApplyTheme: fun(self, theme: TonicTheme) }
function ThemeManager:Register(obj)
	registry[obj] = true
	if current then obj:ApplyTheme(current) end
end

---@param obj table
function ThemeManager:Unregister(obj)
	registry[obj] = nil
end

---Rebuilds the current theme and re-themes every registered object.
---@param silent? boolean do not notify (initial build)
function ThemeManager:Refresh(silent)
	local options = T.db.profile.theme
	current = self:Build(self:GetSeed(), options.mode == "light" and "light" or "dark")
	if silent then return end
	for obj in pairs(registry) do
		xpcall(obj.ApplyTheme, geterrorhandler(), obj, current)
	end
	T.Events:SendMessage("Tonic.ThemeChanged", current)
end

---@param mode "dark"|"light"
function ThemeManager:SetMode(mode)
	T.db.profile.theme.mode = mode
	self:Refresh()
end

---@param seed string classFile, "DEFAULT" or "auto"
function ThemeManager:SetSeed(seed)
	T.db.profile.theme.seed = seed
	self:Refresh()
end

---@param opacity number clamped to 0.60..1.00
function ThemeManager:SetHudOpacity(opacity)
	T.db.profile.theme.hudOpacity = math.min(HUD_OPACITY_MAX, math.max(HUD_OPACITY_MIN, opacity))
	self:Refresh()
end

-- ------------------------------------------------------------- lifecycle

local module = T:NewModule("Theme")

function module:OnInitialize()
	-- Not silent: objects registered at file load (skin helpers) get their first theme.
	ThemeManager:Refresh()
	T.Events:RegisterMessage("Tonic.ProfileChanged", self, function() ThemeManager:Refresh() end)
end

function module:OnEnable()
	-- The class is reliable at PLAYER_LOGIN; re-theme if the early guess differed.
	if current and current.seed ~= ThemeManager:GetSeed() then ThemeManager:Refresh() end
end
