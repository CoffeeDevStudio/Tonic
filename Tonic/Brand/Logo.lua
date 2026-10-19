-- Tonic logo: a tonic vial whose liquid has 4 tonal bands (primary 90/80/60/40), cap
-- tertiary 80, outline and neck primary 90. White layers tinted live: the logo follows
-- the class color. 64 dp and up: 4 bands; 32: two bands; 16: silhouette.
--   local logo = T.Logo:Create(parent, 48)

local T = Tonic

local DIR = T.mediaPath .. "Textures\\Logo\\"

local VARIANTS = {
	[64] = {
		{ "band1", "tonePrimary90" }, { "band2", "tonePrimary80" }, { "band3", "tonePrimary60" },
		{ "band4", "tonePrimary40" }, { "outline", "tonePrimary90" }, { "cap", "toneTertiary80" },
	},
	[32] = {
		{ "bandTop", "tonePrimary80" }, { "bandBottom", "tonePrimary40" },
		{ "outline", "tonePrimary90" }, { "cap", "toneTertiary80" },
	},
	[16] = { { "silhouette", "tonePrimary80" } },
}

---@class TonicLogo: Frame
local LogoMixin = {}

---@param theme TonicTheme
function LogoMixin:ApplyTheme(theme)
	-- Brand tones come from the dark scheme, as in the store icon.
	local dark = self.pinnedTheme or T.Theme:Build(theme.seed, "dark")
	for i, layer in ipairs(self.layers) do
		layer:SetVertexColor(dark:RGB(self.spec[i][2]))
	end
end

---@class TonicLogoFactory
local Logo = {}
T.Logo = Logo

---Creates a logo of size dp (picks the 64, 32 or 16 artwork).
---@param parent Frame
---@param size number
---@param theme? TonicTheme pinned theme
---@return TonicLogo
function Logo:Create(parent, size, theme)
	local f = CreateFrame("Frame", nil, parent)
	Mixin(f, LogoMixin)
	local variant = size >= 48 and 64 or (size >= 24 and 32 or 16)
	f.spec = VARIANTS[variant]
	f.layers = {}
	for i, layer in ipairs(f.spec) do
		local tex = f:CreateTexture(nil, "ARTWORK", nil, i)
		tex:SetAllPoints()
		tex:SetTexture(DIR .. layer[1] .. variant)
		f.layers[i] = tex
	end
	T.Scale:SetSize(f, size, size)
	f.pinnedTheme = theme
	if theme then f:ApplyTheme(theme) else T.Theme:Register(f) end
	return f
end
