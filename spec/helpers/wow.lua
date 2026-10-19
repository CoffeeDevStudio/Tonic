-- Minimal WoW API stubs for busted. Frames record their state; unknown methods are no-ops,
-- unknown Create* methods return new regions.
-- Usage: local wow = require("spec.helpers.wow"); local T = wow.LoadAddon()

local wow = {}

unpack = unpack or table.unpack ---@diagnostic disable-line: deprecated

local function noop() end
local nativeXpcall = xpcall

-- Widget methods: every PascalCase name the addon calls with ":" (scanned from the
-- sources). Other PascalCase keys are child frames (NineSlice, Header...) and stay nil.
local METHODS = {}
for _, addon in ipairs({ "Tonic", "Tonic_Skins", "Tonic_Config" }) do
	for line in io.lines(addon .. "/" .. addon .. ".toc") do
		local file = line:match("^([^#%s].-)%s*$")
		if file then
			local f = io.open(addon .. "/" .. file:gsub("\\", "/"))
			if f then
				for name in f:read("*a"):gmatch(":(%u[%w_]*)%(") do METHODS[name] = true end
				f:close()
			end
		end
	end
end

-- ------------------------------------------------------------- regions

local Region = {}

function Region:SetSize(w, h) self._w, self._h = w, h; self:_sized() end
function Region:SetWidth(w) self._w = w; self:_sized() end
function Region:SetHeight(h) self._h = h; self:_sized() end
function Region:_sized() local fn = self._scripts.OnSizeChanged; if fn then fn(self, self._w, self._h) end end
function Region:GetSize() return self._w or 0, self._h or 0 end
function Region:GetWidth() return self._w or 0 end
function Region:GetHeight() return self._h or 0 end
function Region:GetEffectiveScale() return 1 end
function Region:GetLeft() return 0 end
function Region:GetBottom() return 0 end
function Region:GetTop() return 0 end
function Region:GetRight() return 0 end
function Region:GetCenter() return 0, 0 end
function Region:SetParent(p) self._parent = p end
function Region:GetParent() return self._parent end
function Region:Show() self._shown = true; if self._scripts.OnShow then self._scripts.OnShow(self) end end
function Region:Hide() self._shown = false end
function Region:SetShown(s) if s then self:Show() else self:Hide() end end
function Region:IsShown() return self._shown ~= false end
function Region:IsVisible() return self._shown ~= false end
function Region:SetFrameLevel(l) self._level = l end
function Region:GetFrameLevel() return self._level or 1 end
function Region:GetFrameStrata() return self._strata or "MEDIUM" end
function Region:SetFrameStrata(s) self._strata = s end
function Region:IsObjectType(kind) return self._kind == kind or (kind == "Frame" and self._isFrame) end
function Region:GetObjectType() return self._kind end
function Region:IsForbidden() return false end
function Region:IsEnabled() return self._enabled ~= false end
function Region:SetEnabled(e) self._enabled = e and true or false end
function Region:GetButtonState() return "NORMAL" end
function Region:SetScript(name, fn) self._scripts[name] = fn end
function Region:GetScript(name) return self._scripts[name] end
function Region:HookScript(name, fn)
	local old = self._scripts[name]
	self._scripts[name] = function(...) if old then old(...) end fn(...) end
end
function Region:RegisterEvent(e) wow.registered[e] = true end
function Region:UnregisterEvent(e) wow.registered[e] = nil end
function Region:CreateTexture() local t = wow.NewRegion("Texture"); self._regions[#self._regions + 1] = t; return t end
function Region:CreateFontString() local t = wow.NewRegion("FontString"); self._regions[#self._regions + 1] = t; return t end
function Region:GetRegions() return unpack(self._regions) end
function Region:SetText(t) self._text = t end
function Region:GetText() return self._text or "" end
function Region:GetStringWidth() return #(tostring(self._text or "")) * 7 end
function Region:GetStringHeight() return 14 end
function Region:SetVertexColor(r, g, b, a) self._color = { r, g, b, a } end
function Region:SetTextColor(r, g, b, a) self._color = { r, g, b, a } end
function Region:GetVerticalScroll() return 0 end
function Region:GetVerticalScrollRange() return 0 end
function Region:IsMouseOver() return false end
function Region:SetMinMaxValues(a, b) self._min, self._max = a, b end
function Region:GetMinMaxValues() return self._min or 0, self._max or 1 end
function Region:SetValue(v)
	self._value = v
	local fn = self._scripts.OnValueChanged
	if fn then fn(self, v, false) end
end
function Region:GetValue() return self._value or 0 end
function Region:GetStatusBarTexture() return self._barTexture end
function Region:SetStatusBarTexture() self._barTexture = self._barTexture or wow.NewRegion("Texture") end
function Region:EnumerateActive() return pairs(self._active or {}) end

function wow.NewRegion(kind)
	local r = setmetatable({ _kind = kind, _scripts = {}, _regions = {},
		_isFrame = kind ~= "Texture" and kind ~= "FontString" and kind ~= "MaskTexture" }, {
		__index = function(_, k)
			if Region[k] then return Region[k] end
			-- Fields (lowerCamel, _private) stay nil; methods are PascalCase.
			if type(k) ~= "string" or not k:match("^%u") then return nil end
			-- CreateAnimationGroup, CreateAnimation, CreateMaskTexture...: new regions.
			if k:sub(1, 6) == "Create" then return function() return wow.NewRegion(k:sub(7)) end end
			if METHODS[k] then return noop end
			return nil
		end,
	})
	return r
end

-- ------------------------------------------------------------- fonts

local Font = {}
function Font:SetFont(path) self._path = path; return true end
function Font:GetFont() return self._path, 12, "" end
function Font:CopyFontObject(other) self._path = other._path end

local function newFont(name)
	local f = setmetatable({ _name = name }, { __index = function(_, k) return Font[k] or noop end })
	if name then _G[name] = f end
	return f
end

-- ------------------------------------------------------------- environment

local loaded = {}
local timers = {}

function wow.Reset()
	wow.registered = {}
	wow.errors = {}
	wow.combat = false
	wow.class = "MAGE"
	wow.locale = "enUS"
	loaded = {}
	timers = {}

	_G.Tonic, _G.LibStub, _G.TonicDB, _G.TonicCharDB = nil, nil, nil, nil
	_G.SlashCmdList = {}
	_G.strmatch = string.match
	_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
	_G.geterrorhandler = function() return function(err) wow.errors[#wow.errors + 1] = err end end
	_G.InCombatLockdown = function() return wow.combat end
	_G.issecure = function() return false end
	_G.UnitName = function() return "Tester" end
	_G.GetRealmName = function() return "Realm" end
	_G.UnitClass = function() return "Class", wow.class end
	_G.UnitPowerType = function() return 0, "MANA" end
	_G.UnitCanAttack = function() return false end
	_G.GetLocale = function() return wow.locale end
	_G.GetPhysicalScreenSize = function() return 1920, 1080 end
	_G.GetCursorPosition = function() return 100, 100 end
	_G.GetInventoryItemQuality = function() return 4 end
	_G.ReloadUI = noop
	_G.OKAY = "Okay"
	_G.LOCALIZED_CLASS_NAMES_MALE = { MAGE = "Mage" }
	_G.Mixin = function(obj, ...)
		for i = 1, select("#", ...) do
			for k, v in pairs((select(i, ...))) do obj[k] = v end
		end
		return obj
	end
	_G.CreateFromMixins = function(...) return _G.Mixin({}, ...) end
	_G.CreateFrame = function(kind) return wow.NewRegion(kind) end
	_G.CreateFont = newFont
	_G.CreateFontFamily = function(name) return newFont(name) end
	_G.UIParent = wow.NewRegion("Frame")
	_G.Minimap = wow.NewRegion("Frame")
	_G.print = noop
	_G.hooksecurefunc = function(tbl, name, fn)
		if type(tbl) == "string" then tbl, name, fn = _G, tbl, name end
		local orig = tbl[name]
		tbl[name] = function(...)
			local r = { orig(...) }
			fn(...)
			return unpack(r)
		end
	end
	_G.C_Timer = {
		After = function(_, fn) timers[#timers + 1] = fn end,
		NewTimer = function(_, fn)
			local t = { cancelled = false }
			function t:Cancel() self.cancelled = true end
			timers[#timers + 1] = function() if not t.cancelled then fn() end end
			return t
		end,
	}
	_G.C_AddOns = {
		GetAddOnMetadata = function() return "@project-version@" end,
		IsAddOnLoaded = function(name) return loaded[name] == true end,
		GetAddOnInfo = function(name) return name, name, "", true end,
		LoadAddOn = function(name) return wow.LoadFolder(name) end,
	}
	_G.Settings = {
		RegisterCanvasLayoutCategory = function() return {} end,
		RegisterAddOnCategory = noop,
	}
	_G.CreateScrollBoxListLinearView = function() return wow.NewRegion("ScrollBoxView") end
	_G.ScrollUtil = { InitScrollBoxListWithScrollBar = noop, AddManagedScrollBarVisibilityBehavior = noop }
	_G.CreateDataProvider = function(items) return { items = items, FindIndex = function() return 1 end } end
	-- WoW's xpcall forwards extra arguments (Lua 5.1's does not).
	_G.xpcall = function(fn, handler, ...)
		local args = { n = select("#", ...), ... }
		return nativeXpcall(function() return fn(unpack(args, 1, args.n)) end, handler)
	end
end

---Runs the queued C_Timer callbacks.
function wow.FlushTimers()
	local pending = timers
	timers = {}
	for _, fn in ipairs(pending) do fn() end
end

---Fires a WoW event on every Tonic handler (they all share one frame).
function wow.Fire(event, ...)
	for _, frame in ipairs(wow.eventFrames) do
		local handler = frame._scripts.OnEvent
		if handler then handler(frame, event, ...) end
	end
end

---Loads the files of an addon folder in TOC order, then fires its ADDON_LOADED.
---@param name string
function wow.LoadFolder(name)
	local toc = name .. "/" .. name .. ".toc"
	local f = io.open(toc)
	if not f then return false, "MISSING" end
	f:close()
	for line in io.lines(toc) do
		local file = line:match("^([^#%s].-)%s*$")
		if file then
			local chunk = assert(loadfile(name .. "/" .. file:gsub("\\", "/")))
			chunk(name)
		end
	end
	loaded[name] = true
	wow.Fire("ADDON_LOADED", name)
	return true
end

---Loads the addon files in TOC order in a fresh environment.
---@param opts? { login: boolean } fire ADDON_LOADED (always) and PLAYER_LOGIN (default true)
function wow.LoadAddon(opts)
	opts = opts or {}
	wow.Reset()
	wow.eventFrames = {}
	local createFrame = _G.CreateFrame
	_G.CreateFrame = function(kind, ...)
		local f = createFrame(kind, ...)
		wow.eventFrames[#wow.eventFrames + 1] = f
		return f
	end
	if opts.before then opts.before() end
	wow.LoadFolder("Tonic")
	if opts.login ~= false then wow.Fire("PLAYER_LOGIN") end
	return _G.Tonic
end

return wow
