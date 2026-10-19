-- Minimal WoW API stubs for busted. Frames record their state; unknown methods are no-ops.
-- Usage: local wow = require("spec.helpers.wow"); local T = wow.LoadAddon()

local wow = {}

unpack = unpack or table.unpack ---@diagnostic disable-line: deprecated

local function noop() end
local nativeXpcall = xpcall

-- ------------------------------------------------------------- regions

local Region = {}

function Region:SetSize(w, h) self._w, self._h = w, h end
function Region:SetWidth(w) self._w = w end
function Region:SetHeight(h) self._h = h end
function Region:GetSize() return self._w or 0, self._h or 0 end
function Region:GetWidth() return self._w or 0 end
function Region:GetHeight() return self._h or 0 end
function Region:GetEffectiveScale() return 1 end
function Region:SetParent(p) self._parent = p end
function Region:GetParent() return self._parent end
function Region:Show() self._shown = true; if self._scripts.OnShow then self._scripts.OnShow(self) end end
function Region:Hide() self._shown = false end
function Region:SetShown(s) if s then self:Show() else self:Hide() end end
function Region:IsShown() return self._shown ~= false end
function Region:SetFrameLevel(l) self._level = l end
function Region:GetFrameLevel() return self._level or 1 end
function Region:SetScript(name, fn)
	self._scripts[name] = fn
	if name == "OnSizeChanged" then self._onSize = fn end
end
function Region:GetScript(name) return self._scripts[name] end
function Region:RegisterEvent(e) wow.registered[e] = true end
function Region:UnregisterEvent(e) wow.registered[e] = nil end
function Region:CreateTexture() return wow.NewRegion("Texture") end
function Region:CreateFontString() return wow.NewRegion("FontString") end
function Region:SetText(t) self._text = t end
function Region:GetText() return self._text end
function Region:GetStringWidth() return #(tostring(self._text or "")) * 7 end
function Region:SetVertexColor(r, g, b, a) self._color = { r, g, b, a } end
function Region:SetTextColor(r, g, b, a) self._color = { r, g, b, a } end
function Region:GetVerticalScroll() return 0 end
function Region:GetVerticalScrollRange() return 0 end
function Region:IsMouseOver() return false end

function wow.NewRegion(kind)
	local r = setmetatable({ _kind = kind, _scripts = {} }, {
		__index = function(_, k)
			if Region[k] then return Region[k] end
			-- Internal "_fields" stay nil; any other unknown method is a no-op.
			if type(k) == "string" and k:sub(1, 1) ~= "_" then return noop end
		end,
	})
	return r
end

-- ------------------------------------------------------------- fonts

local Font = {}
function Font:SetFont(path) self._path = path; return true end
function Font:GetFont() return self._path, 12, "" end

local function newFont(name)
	local f = setmetatable({ _name = name }, { __index = function(_, k) return Font[k] or noop end })
	if name then _G[name] = f end
	return f
end

-- ------------------------------------------------------------- environment

function wow.Reset()
	wow.registered = {}
	wow.errors = {}
	wow.combat = false
	wow.class = "MAGE"
	wow.locale = "enUS"

	_G.Tonic, _G.LibStub, _G.TonicDB, _G.TonicCharDB = nil, nil, nil, nil
	_G.SlashCmdList = {}
	_G.strmatch = string.match
	_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
	_G.geterrorhandler = function() return function(err) wow.errors[#wow.errors + 1] = err end end
	_G.InCombatLockdown = function() return wow.combat end
	_G.UnitName = function() return "Tester" end
	_G.GetRealmName = function() return "Realm" end
	_G.UnitClass = function() return "Class", wow.class end
	_G.GetLocale = function() return wow.locale end
	_G.GetPhysicalScreenSize = function() return 1920, 1080 end
	_G.C_AddOns = { GetAddOnMetadata = function() return "test" end }
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
	_G.print = noop
	-- WoW's xpcall forwards extra arguments (Lua 5.1's does not).
	_G.xpcall = function(fn, handler, ...)
		local args = { n = select("#", ...), ... }
		return nativeXpcall(function() return fn(unpack(args, 1, args.n)) end, handler)
	end
end

---Fires a WoW event on every Tonic handler (they all share one frame).
function wow.Fire(event, ...)
	for _, frame in ipairs(wow.eventFrames) do
		local handler = frame._scripts.OnEvent
		if handler then handler(frame, event, ...) end
	end
end

local TOC = "Tonic/Tonic.toc"

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
	for line in io.lines(TOC) do
		local file = line:match("^([^#%s].-)%s*$")
		if file then
			local chunk = assert(loadfile("Tonic/" .. file:gsub("\\", "/")))
			chunk("Tonic")
		end
	end
	wow.Fire("ADDON_LOADED", "Tonic")
	if opts.login ~= false then wow.Fire("PLAYER_LOGIN") end
	return _G.Tonic
end

return wow
