-- Icon: Material Symbols Rounded glyph (codepoints: WoW has no ligatures), or the
-- generated texture of the same name when the font is not installed.
--
--   local icon = T.Icon:Acquire(parent, { name = "close", size = 24, color = "onSurfaceVariant" })

local T = Tonic

local FONT_FILE = T.mediaPath .. "Fonts\\MaterialSymbolsRounded.ttf"
local TEXTURE_DIR = T.mediaPath .. "Textures\\Icons\\"

-- Material Symbols codepoints used by Tonic.
local CODEPOINTS = {
	add = 0xE145, remove = 0xE15B, close = 0xE5CD, check = 0xE5CA,
	chevron_left = 0xE5CB, chevron_right = 0xE5CC, expand_more = 0xE5CF, expand_less = 0xE5CE,
	arrow_back = 0xE5C4, menu = 0xE5D2, more_vert = 0xE5D4, search = 0xE8B6,
	light_mode = 0xE518, dark_mode = 0xE51C, info = 0xE88E, warning = 0xE002,
	settings = 0xE8B8, palette = 0xE40A, tune = 0xE429, person = 0xE7FD,
	star = 0xE838, favorite = 0xE87D, delete = 0xE872, edit = 0xE3C9,
	refresh = 0xE5D5, home = 0xE88A, visibility = 0xE8F4, content_copy = 0xE14D,
}

-- Icons with a generated texture fallback (tools/tokens).
local TEXTURES = {
	add = true, remove = true, close = true, check = true, chevron_left = true, chevron_right = true,
	expand_more = true, expand_less = true, arrow_back = true, menu = true, more_vert = true,
	search = true, light_mode = true, dark_mode = true, info = true, warning = true,
}

local function utf8(cp)
	if cp < 0x80 then return string.char(cp) end
	if cp < 0x800 then return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40) end
	return string.char(0xE0 + math.floor(cp / 0x1000), 0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
end

local fonts = {}
local fontAvailable

local function iconFont(size)
	local px = math.floor(size * T.Scale.density + 0.5)
	local font = fonts[px]
	if not font then
		font = CreateFont("TonicIconFont" .. px)
		font:SetFont(FONT_FILE, px, "")
		font:SetJustifyH("CENTER")
		fonts[px] = font
	end
	return font
end

---@class TonicIconProps
---@field name string
---@field size number? dp, default 24
---@field color string? theme color name
---@field alpha number?
---@field theme TonicTheme?

---@class TonicIcon: Frame
---@field props TonicIconProps
---@field glyph FontString
---@field tex Texture
local IconMixin = {}

---@param name string
function IconMixin:SetIcon(name)
	self.props.name = name
	self:Render()
end

function IconMixin:Render()
	local p = self.props
	local size = p.size or 24
	T.Scale:SetSize(self, size, size)
	local useFont = T.Icon:HasFont() and CODEPOINTS[p.name]
	self.glyph:SetShown(useFont and true or false)
	self.tex:SetShown(not useFont and TEXTURES[p.name] or false)
	if useFont then
		self.glyph:SetFontObject(iconFont(size))
		self.glyph:SetText(utf8(CODEPOINTS[p.name]))
	elseif TEXTURES[p.name] then
		self.tex:SetTexture(TEXTURE_DIR .. p.name)
	end
end

---@param theme TonicTheme
function IconMixin:ApplyTheme(theme)
	self.theme = theme
	local r, g, b = theme:RGB(self.props.color or "onSurface")
	self:SetColor(r, g, b, self.props.alpha or 1)
end

---Direct color (components compute disabled/state colors themselves).
function IconMixin:SetColor(r, g, b, a)
	self.glyph:SetTextColor(r, g, b, a or 1)
	self.tex:SetVertexColor(r, g, b, a or 1)
end

function IconMixin:SetState(state)
	self.state = state
	if self.theme then self:ApplyTheme(self.theme) end
end

function IconMixin:Update(props)
	for k, v in pairs(props) do self.props[k] = v end
	self:Render()
	if self.theme then self:ApplyTheme(props.theme or self.theme) end
end

function IconMixin:Release()
	T.Icon.pool:Release(self)
end

---@class TonicIconFactory
local Icon = {}
T.Icon = Icon

---True when MaterialSymbolsRounded.ttf is installed.
---@return boolean
function Icon:HasFont()
	if fontAvailable == nil then
		local probe = CreateFont("TonicIconProbe")
		probe:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
		local ok = probe:SetFont(FONT_FILE, 12, "")
		local file = probe:GetFont()
		fontAvailable = ok ~= false and file ~= nil and file:lower():find("materialsymbols") ~= nil
	end
	return fontAvailable
end

---@param name string
---@return boolean
function Icon:Exists(name)
	return CODEPOINTS[name] ~= nil and self:HasFont() or TEXTURES[name] == true
end

local function build(parent)
	local f = CreateFrame("Frame", nil, parent)
	Mixin(f, IconMixin)
	f.glyph = f:CreateFontString(nil, "OVERLAY")
	f.glyph:SetPoint("CENTER")
	f.tex = f:CreateTexture(nil, "OVERLAY")
	f.tex:SetAllPoints()
	f.props = {}
	return f
end

Icon.pool = T.CreatePool(function() return build(T.hiddenParent) end, function(_, f)
	T.Theme:Unregister(f)
	f:Hide()
	f:ClearAllPoints()
	f:SetParent(T.hiddenParent)
	f.props, f.theme, f.state = {}, nil, nil
end)

---Acquires a themed icon from the pool.
---@param parent Frame
---@param props TonicIconProps
---@return TonicIcon
function Icon:Acquire(parent, props)
	local f = self.pool:Acquire()
	f.props = {}
	for k, v in pairs(props or {}) do f.props[k] = v end
	f:SetParent(parent)
	f:Render()
	if f.props.theme then f:ApplyTheme(f.props.theme) else T.Theme:Register(f) end
	f:Show()
	return f
end

---Creates an icon owned by a component (not pooled, not registered: the owner colors it).
---@param parent Frame
---@param name? string
---@param size? number
---@return TonicIcon
function Icon:Create(parent, name, size)
	local f = build(parent)
	f.props = { name = name, size = size }
	if name then f:Render() end
	return f
end
