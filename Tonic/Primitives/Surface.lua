-- Surface: a rounded, tinted rectangle with optional outline and pre-rendered shadow.
-- Contract: :ApplyTheme(theme), :SetState(state), :Update(props), :Release().
--
--   local s = T.Surface:Acquire(parent, { usage = "window" })
--   local s = T.Surface:Acquire(parent, { color = "primaryContainer", shape = "m", width = 120, height = 48 })

local T = Tonic

---@class TonicSurfaceProps
---@field usage string? Elevation usage ("window", "hud", "menu", ...): sets color, shape, shadow
---@field color string? any theme color name; overrides usage
---@field shape string|number? shape token or radius in dp
---@field shadow integer? shadow level 0..5
---@field opacity number|"hud"? fill opacity; "hud" follows the HUD opacity option
---@field outline string? outline color name (1 dp); best on opaque surfaces
---@field width number? dp
---@field height number? dp
---@field theme TonicTheme? pinned theme: not registered with the ThemeManager

---@class TonicSurface: Frame
---@field props TonicSurfaceProps
---@field theme TonicTheme?
---@field state string?
local SurfaceMixin = {}

local DEFAULTS = { color = "surface", shape = "none", shadow = 0, opacity = 1 }

local function resolved(props)
	local usage = props.usage and T.Elevation:GetUsage(props.usage)
	return {
		color = props.color or (usage and T.Elevation:Role(props.usage)) or DEFAULTS.color,
		shape = props.shape or (usage and usage.shape) or DEFAULTS.shape,
		shadow = props.shadow or (usage and usage.shadow) or DEFAULTS.shadow,
		opacity = props.opacity or (usage and usage.hud and "hud") or DEFAULTS.opacity,
		outline = props.outline,
	}
end

function SurfaceMixin:Layout()
	local r = self.resolved
	local Scale = T.Scale
	local width, height = self:GetSize()
	if width <= 0 or height <= 0 then return end
	local px = Scale:PixelSize(self)
	local radius = T.Shape:Radius(r.shape, self, width, height)
	local radiusPx = radius / px

	local inset = 0
	if r.outline then
		inset = px
		self.outlinePieces:SetShown(true)
		self.outlinePieces:Layout(radius, T.Shape:CircleTexture(radiusPx), 0, 0, 0, 0)
	else
		self.outlinePieces:SetShown(false)
	end
	local fillRadius = math.max(radius - inset, 0)
	self.fillPieces:Layout(fillRadius, T.Shape:CircleTexture(fillRadius / px), -inset, -inset, -inset, -inset)

	local shadow = T.Elevation:GetShadow(r.shadow)
	if shadow then
		local blur = Scale:Dp(shadow.blur, self)
		local y = Scale:Dp(shadow.y, self)
		self.shadowPieces:SetShown(true)
		self.shadowPieces:Layout(radius + blur, T.Shape.shadowTexture, blur, blur - y, blur, blur + y)
	else
		self.shadowPieces:SetShown(false)
	end
end

---@param theme TonicTheme
function SurfaceMixin:ApplyTheme(theme)
	self.theme = theme
	local r = self.resolved
	local opacity = r.opacity == "hud" and theme.hudOpacity or r.opacity
	local cr, cg, cb = theme:RGB(r.color)
	if self.state == "disabled" then
		-- M3 disabled container: onSurface at 12%.
		cr, cg, cb = theme:RGB("onSurface")
		opacity = T.Color.STATE.disabledContainer
	elseif self.state and T.Color.STATE[self.state] then
		-- State layer of the content color over the container.
		local layer = theme:Color(self.stateLayer or "onSurface")
		local mixed = T.Color.Mix({ cr, cg, cb }, layer, T.Color.STATE[self.state])
		cr, cg, cb = mixed[1], mixed[2], mixed[3]
	end
	self.fillPieces:SetColor(cr, cg, cb, opacity)
	if r.outline then self.outlinePieces:SetColor(theme:RGB(r.outline)) end
	local shadow = T.Elevation:GetShadow(r.shadow)
	if shadow then
		local sr, sg, sb = theme:RGB("shadow")
		self.shadowPieces:SetColor(sr, sg, sb, shadow.alpha)
	end
end

---Sets an M3 state: nil, "hover", "focus", "pressed" or "disabled".
---@param state string?
---@param layerColor? string content color used for the state layer (default onSurface)
function SurfaceMixin:SetState(state, layerColor)
	self.state = state
	self.stateLayer = layerColor
	if self.theme then self:ApplyTheme(self.theme) end
end

---Merges props and re-renders.
---@param props TonicSurfaceProps
function SurfaceMixin:Update(props)
	for k, v in pairs(props) do self.props[k] = v end
	self.resolved = resolved(self.props)
	if props.width or props.height then
		T.Scale:SetSize(self, self.props.width or 0, self.props.height or 0)
	end
	if props.theme then
		T.Theme:Unregister(self)
		self:ApplyTheme(props.theme)
	elseif self.theme then
		self:ApplyTheme(self.theme)
	end
	self:Layout()
end

function SurfaceMixin:Release()
	T.Surface.pool:Release(self)
end

local function onSizeChanged(self)
	self:Layout()
end

local function onScaleChanged(self)
	self:Layout()
end

-- ------------------------------------------------------------- factory

---@class TonicSurfaceFactory
local Surface = {}
T.Surface = Surface

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

Surface.pool = T.CreatePool(function()
	local f = CreateFrame("Frame", nil, hiddenParent)
	Mixin(f, SurfaceMixin)
	f.shadowPieces = T.Shape:CreatePieces(f, "BACKGROUND", -8)
	f.outlinePieces = T.Shape:CreatePieces(f, "BACKGROUND", -7)
	f.fillPieces = T.Shape:CreatePieces(f, "BACKGROUND", -6)
	f:SetScript("OnSizeChanged", onSizeChanged)
	return f
end, function(_, f)
	T.Theme:Unregister(f)
	T.Events:UnregisterMessage("Tonic.ScaleChanged", f)
	f:Hide()
	f:ClearAllPoints()
	f:SetParent(hiddenParent)
	f:EnableMouse(false)
	f:SetScript("OnEnter", nil)
	f:SetScript("OnLeave", nil)
	f:SetScript("OnMouseDown", nil)
	f:SetScript("OnMouseUp", nil)
	f.theme, f.state, f.stateLayer, f.props, f.resolved = nil, nil, nil, nil, nil
end)

---Acquires a surface from the pool.
---@param parent Frame
---@param props? TonicSurfaceProps
---@return TonicSurface
function Surface:Acquire(parent, props)
	local f = self.pool:Acquire()
	props = props or {}
	f.props = {}
	for k, v in pairs(props) do f.props[k] = v end
	f.resolved = resolved(f.props)
	f:SetParent(parent)
	f:SetFrameLevel(parent:GetFrameLevel() + 1)
	if props.width or props.height then
		T.Scale:SetSize(f, props.width or 0, props.height or 0)
	end
	T.Events:RegisterMessage("Tonic.ScaleChanged", f, onScaleChanged)
	if props.theme then
		f:ApplyTheme(props.theme)
	else
		T.Theme:Register(f)
	end
	f:Show()
	f:Layout()
	return f
end
