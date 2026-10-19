-- Skin helpers. Rules (taint): on Blizzard frames only hooksecurefunc and HookScript,
-- never SetScript, never replace their functions. Textures are hidden with SetAlpha(0),
-- frames through T.Combat:Defer. Our state lives in weak tables, never on their frames.
-- Values (health, text) are never read: they are only forwarded by Blizzard's code.

local T = Tonic

---@class TonicSkinHelpers
local H = {}
T.SkinHelpers = H

local backdrops = setmetatable({}, { __mode = "k" })  -- [frame] = Surface
local textColors = setmetatable({}, { __mode = "k" }) -- [fontString] = color name
local qualities = setmetatable({}, { __mode = "k" })  -- [button] = quality
local bars = setmetatable({}, { __mode = "k" })       -- [statusBar] = colorFn
local hooked = setmetatable({}, { __mode = "k" })     -- [object] = true
local theme -- current theme, kept by H:ApplyTheme

H.Resolve = T.Skins.Resolve

---A child region stored under key on a Blizzard frame, or nil.
---@param frame table?
---@param key string
---@return table?
function H.Child(frame, key)
	local child = type(frame) == "table" and frame[key]
	return type(child) == "table" and child or nil
end

-- Missing (or not a region) counts as forbidden: skins never touch what they can't see.
local function isForbidden(region)
	return type(region) ~= "table" or (region.IsForbidden and region:IsForbidden())
end

---Hides a texture or a frame without fighting Blizzard's Show calls.
---@param region Region?
function H.Hide(region)
	if isForbidden(region) then return end
	if region:IsObjectType("Texture") or region:IsObjectType("FontString") then
		region:SetAlpha(0)
	else
		T.Combat:Defer(function() region:SetAlpha(0) end)
	end
end

---Hides every texture region of a frame.
---@param frame Frame?
function H.StripTextures(frame)
	if isForbidden(frame) then return end
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:IsObjectType("Texture") then region:SetAlpha(0) end
	end
end

local FRAME_ART = { "NineSlice", "Bg", "Background", "TopTileStreaks", "PortraitContainer", "Border",
	"TitleBg", "Inset", "BorderFrame", "Shadows" }

---Hides the standard Blizzard window art (portrait frame, NineSlice, background...).
---@param frame Frame?
---@param keepTextures? boolean only the art children
function H.StripFrame(frame, keepTextures)
	if isForbidden(frame) then return end
	if not keepTextures then H.StripTextures(frame) end
	for _, key in ipairs(FRAME_ART) do
		local child = frame[key]
		if type(child) == "table" and child.GetObjectType then
			if child:IsObjectType("Frame") then H.StripTextures(child) end
			H.Hide(child)
		end
	end
	local name = frame.GetName and frame:GetName()
	if name then
		for _, suffix in ipairs({ "Bg", "Portrait", "TitleBg", "TopBorder", "BotLeftCorner", "BotRightCorner" }) do
			H.Hide(_G[name .. suffix])
		end
	end
end

---Adds a Tonic Surface behind a frame's content (child frame one level below it).
---@param frame Frame
---@param props? TonicSurfaceProps
---@param inset? number dp; negative grows the backdrop
---@return TonicSurface?
function H.Backdrop(frame, props, inset)
	if isForbidden(frame) then return nil end
	local surface = backdrops[frame]
	if surface then
		if props then surface:Update(props) end
		return surface
	end
	surface = T.Surface:Acquire(frame, props or { usage = "window" })
	backdrops[frame] = surface
	inset = inset or 0
	T.Scale:SetPoint(surface, "TOPLEFT", frame, "TOPLEFT", inset, -inset)
	T.Scale:SetPoint(surface, "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
	local function sync()
		surface:SetFrameStrata(frame:GetFrameStrata())
		surface:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
	end
	sync()
	frame:HookScript("OnShow", sync)
	return surface
end

---@param frame Frame
---@return TonicSurface?
function H.GetBackdrop(frame)
	return backdrops[frame]
end

-- ------------------------------------------------------------- text

---Applies a type role to a Blizzard FontString (the text itself is untouched).
---@param fs FontString?
---@param role string
---@param numeric? boolean
---@param color? string theme color kept in sync
function H.SetFont(fs, role, numeric, color)
	if isForbidden(fs) then return end
	fs:SetFontObject(T.Typography:Get(role, numeric))
	if color then H.ColorText(fs, color) end
end

---Keeps a FontString colored with a theme color.
---@param fs FontString?
---@param color string
function H.ColorText(fs, color)
	if isForbidden(fs) then return end
	textColors[fs] = color
	if theme then fs:SetTextColor(theme:RGB(color)) end
end

-- Font objects shared by skinned Blizzard buttons and tabs; recolored with the theme.
local fontObjects = {}
local function stateFont(key, role, color, alpha)
	local font = fontObjects[key]
	if not font then
		font = { font = CreateFont("TonicSkinFont_" .. key), color = color, alpha = alpha }
		font.font:CopyFontObject(T.Typography:Get(role))
		if theme then
			local r, g, b = theme:RGB(color)
			font.font:SetTextColor(r, g, b, alpha or 1)
		end
		fontObjects[key] = font
	end
	return font.font
end

-- ------------------------------------------------------------- buttons

---Skins a Blizzard button as an M3 tonal (or filled) button.
---@param button Button?
---@param variant? "tonal"|"filled"|"text"
function H.SkinButton(button, variant)
	if isForbidden(button) or hooked[button] then return end
	hooked[button] = true
	variant = variant or "tonal"
	H.StripTextures(button)
	for _, key in ipairs({ "Left", "Middle", "Right", "LeftSeparator", "RightSeparator" }) do H.Hide(button[key]) end
	for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }) do
		local tex = button[getter] and button[getter](button)
		if tex then tex:SetAlpha(0) end
	end
	local fill = variant == "filled" and "primary" or (variant == "text" and "surface" or "secondaryContainer")
	local content = variant == "filled" and "onPrimary" or (variant == "text" and "primary" or "onSecondaryContainer")
	local surface = H.Backdrop(button, { color = fill, shape = "full", opacity = variant == "text" and 0 or 1 })
	button:SetNormalFontObject(stateFont("button_" .. variant, "labelLarge", content))
	button:SetHighlightFontObject(stateFont("button_" .. variant, "labelLarge", content))
	button:SetDisabledFontObject(stateFont("button_disabled", "labelLarge", "onSurface", T.Color.STATE.disabledContent))
	local function refresh()
		if not button:IsEnabled() then
			surface:SetState("disabled")
		elseif button:IsMouseOver() then
			surface:SetState(button:GetButtonState() == "PUSHED" and "pressed" or "hover", content)
		else
			surface:SetState(nil)
		end
	end
	button:HookScript("OnEnter", refresh)
	button:HookScript("OnLeave", refresh)
	button:HookScript("OnMouseDown", function() surface:SetState("pressed", content) end)
	button:HookScript("OnMouseUp", refresh)
	button:HookScript("OnEnable", refresh)
	button:HookScript("OnDisable", refresh)
	refresh()
end

---Skins a close button: icon "close" on a circular state layer.
---@param button Button?
function H.SkinCloseButton(button)
	if isForbidden(button) or hooked[button] then return end
	hooked[button] = true
	H.StripTextures(button)
	for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }) do
		local tex = button[getter] and button[getter](button)
		if tex then tex:SetAlpha(0) end
	end
	local surface = H.Backdrop(button, { color = "onSurfaceVariant", shape = "full", opacity = 0 })
	local icon = T.Icon:Acquire(button, { name = "close", size = 20, color = "onSurfaceVariant" })
	icon:SetPoint("CENTER")
	icon:SetFrameLevel(button:GetFrameLevel() + 1)
	button:HookScript("OnEnter", function() surface:Update({ opacity = T.Color.STATE.hover }) end)
	button:HookScript("OnLeave", function() surface:Update({ opacity = 0 }) end)
end

local tabIndicators = setmetatable({}, { __mode = "k" })

local function paintTab(tab, selected)
	local fs = H.Child(tab, "Text") or (tab.GetFontString and tab:GetFontString())
	if fs then fs:SetFontObject(stateFont(selected and "tab_on" or "tab_off", "titleSmall",
		selected and "primary" or "onSurfaceVariant")) end
	local indicator = tabIndicators[tab]
	if indicator then indicator:SetShown(selected) end
end

---Skins a Blizzard tab (PanelTabButtonTemplate and similar): label + 3 dp indicator.
---@param tab Button?
function H.SkinTab(tab)
	if isForbidden(tab) or hooked[tab] then return end
	hooked[tab] = true
	H.StripTextures(tab)
	for _, key in ipairs({ "Left", "Middle", "Right", "LeftActive", "MiddleActive", "RightActive",
		"LeftHighlight", "MiddleHighlight", "RightHighlight" }) do H.Hide(tab[key]) end
	local indicator = T.Surface:Acquire(tab, { color = "primary", shape = 3, height = 3 })
	indicator:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", T.Scale:Dp(12, tab), 0)
	indicator:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -T.Scale:Dp(12, tab), 0)
	tabIndicators[tab] = indicator
	paintTab(tab, false)
end

if PanelTemplates_SelectTab then
	hooksecurefunc("PanelTemplates_SelectTab", function(tab) if tabIndicators[tab] then paintTab(tab, true) end end)
end
if PanelTemplates_DeselectTab then
	hooksecurefunc("PanelTemplates_DeselectTab", function(tab) if tabIndicators[tab] then paintTab(tab, false) end end)
end

---Skins an EditBox (search boxes): field surface, Tonic font.
---@param edit EditBox?
function H.SkinEditBox(edit)
	if isForbidden(edit) or hooked[edit] then return end
	hooked[edit] = true
	H.StripTextures(edit)
	for _, key in ipairs({ "Left", "Middle", "Mid", "Right" }) do H.Hide(edit[key]) end
	H.Backdrop(edit, { usage = "field", shape = "full" }, -2)
	edit:SetFontObject(T.Typography:Get("bodyMedium"))
	H.ColorText(edit, "onSurface")
end

-- ------------------------------------------------------------- items

local QUALITY_TOKENS = {
	[0] = "qualityCommon", [1] = "qualityCommon", [2] = "qualityUncommon", [3] = "qualityRare",
	[4] = "qualityEpic", [5] = "qualityLegendary", [6] = "qualityLegendary", [7] = "qualityRare",
	[8] = "qualityRare",
}
local LEGENDARY = 5

---Semantic token of an item quality ("qualityEpic"), common for nil.
---@param quality integer?
---@return string
function H.QualityToken(quality)
	return QUALITY_TOKENS[quality or 1] or "qualityCommon"
end

local rings = setmetatable({}, { __mode = "k" })

local function paintQuality(button)
	local surface = backdrops[button]
	if not surface or not theme then return end
	local quality = qualities[button]
	local token = H.QualityToken(quality)
	-- Common and poor are neutral: the slot keeps its tonal surface.
	local tinted = quality and quality >= 2
	surface:Update({ color = tinted and (token .. ".container") or "surfaceContainerHighest" })
	local ring = rings[button]
	if ring then
		ring:SetShown(quality == LEGENDARY)
		ring:SetVertexColor(theme:RGB(token .. ".color"))
	end
end

---Skins an item button: tonal container (shape M), cropped icon, legendary ring.
---@param button Button?
function H.SkinItemButton(button)
	if isForbidden(button) or hooked[button] then return end
	hooked[button] = true
	for _, key in ipairs({ "IconBorder", "IconOverlay", "NormalTexture", "Background" }) do H.Hide(button[key]) end
	local normal = button.GetNormalTexture and button:GetNormalTexture()
	if normal then normal:SetAlpha(0) end
	local name = button.GetName and button:GetName()
	if name then H.Hide(_G[name .. "NormalTexture"]); H.Hide(_G[name .. "Frame"]) end
	local icon = button.icon or button.Icon or (name and _G[name .. "IconTexture"])
	if icon then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
	H.Backdrop(button, { color = "surfaceContainerHighest", shape = "m" }, -2)
	local ring = button:CreateTexture(nil, "OVERLAY", nil, 7)
	ring:SetPoint("TOPLEFT", -T.Scale:Dp(2, button), T.Scale:Dp(2, button))
	ring:SetPoint("BOTTOMRIGHT", T.Scale:Dp(2, button), -T.Scale:Dp(2, button))
	ring:SetTexture(T.mediaPath .. "Textures\\Ring6")
	ring:Hide()
	rings[button] = ring
	paintQuality(button)
end

---@param button Button
---@param quality integer? Enum.ItemQuality
function H.SetItemQuality(button, quality)
	qualities[button] = quality
	paintQuality(button)
end

-- ------------------------------------------------------------- status bars

local FLAT = T.Shape.white
local guard = setmetatable({}, { __mode = "k" })

local function paintBarColor(bar)
	local colorFn = bars[bar]
	if not colorFn or not theme or guard[bar] then return end
	local name = colorFn(bar)
	if not name then return end
	guard[bar] = true
	local r, g, b = theme:RGB(name)
	bar:SetStatusBarColor(r, g, b)
	guard[bar] = nil
end

local function paintBarTexture(bar)
	if not bars[bar] or guard[bar] then return end
	guard[bar] = true
	bar:SetStatusBarTexture(FLAT)
	guard[bar] = nil
	paintBarColor(bar)
end

---Flat texture and theme color on a StatusBar. Blizzard keeps setting the values;
---we only re-apply texture and color after its own calls.
---@param bar StatusBar?
---@param colorFn fun(bar: StatusBar): string? color name, nil keeps Blizzard's color
function H.SkinStatusBar(bar, colorFn)
	if isForbidden(bar) then return end
	bars[bar] = colorFn
	if not hooked[bar] then
		hooked[bar] = true
		hooksecurefunc(bar, "SetStatusBarColor", paintBarColor)
		hooksecurefunc(bar, "SetStatusBarTexture", paintBarTexture)
	end
	paintBarTexture(bar)
end

-- ------------------------------------------------------------- theme

---@param newTheme TonicTheme
function H:ApplyTheme(newTheme)
	theme = newTheme
	for _, def in pairs(fontObjects) do
		local r, g, b = theme:RGB(def.color)
		def.font:SetTextColor(r, g, b, def.alpha or 1)
	end
	for fs, color in pairs(textColors) do fs:SetTextColor(theme:RGB(color)) end
	for button in pairs(qualities) do paintQuality(button) end
	for button in pairs(rings) do paintQuality(button) end
	for bar in pairs(bars) do paintBarColor(bar) end
end

T.Theme:Register(H)
