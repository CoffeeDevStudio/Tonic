-- M3 switch: track 52x32, handle 16 (off) / 24 (on) / 28 (pressed), optional icons.
--   T.Switch:Acquire(parent, { checked = true, onChange = function(self, checked) end })

local T = Tonic

local CIRCLE = T.mediaPath .. "Textures\\Circle64"
local OFF_X, ON_X = 16, 36

---@class TonicSwitch: TonicComponent
local SwitchMixin = {}

function SwitchMixin:Build()
	self:CreateContainer()
	self.halo = CreateFrame("Frame", nil, self)
	self.haloLayer = T.StateLayer:Create(self.halo, "BACKGROUND", -3)
	self.handle = self:CreateTexture(nil, "ARTWORK")
	self.handle:SetTexture(CIRCLE)
	self.handleIcon = T.Icon:Create(self.content)
end

function SwitchMixin:OnLevelChanged(level)
	self.halo:SetFrameLevel(level)
end

function SwitchMixin:HandleSize(state)
	if state == "pressed" then return 28 end
	if self.props.checked or self.props.icons then return 24 end
	return 16
end

-- Places the handle at x (dp, center from the left edge).
function SwitchMixin:PlaceHandle(x, size)
	self.handleX = x
	T.Scale:SetSize(self.handle, size, size)
	self.handle:ClearAllPoints()
	T.Scale:SetPoint(self.handle, "CENTER", self, "LEFT", x, 0)
	self.halo:ClearAllPoints()
	T.Scale:SetPoint(self.halo, "CENTER", self, "LEFT", x, 0)
	self.handleIcon:ClearAllPoints()
	T.Scale:SetPoint(self.handleIcon, "CENTER", self, "LEFT", x, 0)
end

function SwitchMixin:Layout()
	T.Scale:SetSize(self, 52, 32)
	T.Scale:SetSize(self.halo, 40, 40)
	self:LayoutContainer("full", self, 2)
	self.haloLayer:Layout("full", self.halo)
	if not self.tween then
		self:PlaceHandle(self.props.checked and ON_X or OFF_X, self:HandleSize(self:GetState()))
	end
	local icon = self.props.icons and (self.props.checked and "check" or "close")
	self.handleIcon:SetShown(icon and true or false)
	if icon then self.handleIcon:Update({ name = icon, size = 16 }) end
end

function SwitchMixin:Render(theme, state)
	local on = self.props.checked
	local disabled = state == "disabled"
	local Color = T.Color.STATE
	-- Track.
	if disabled then
		local r, g, b = theme:RGB(on and "onSurface" or "surfaceContainerHighest")
		self.fill:SetShown(true)
		self.fill:SetColor(r, g, b, Color.disabledContainer)
		self.outline:SetShown(not on)
		if not on then
			local orr, og, ob = theme:RGB("onSurface")
			self.outline:SetColor(orr, og, ob, Color.disabledContainer)
		end
	else
		self.fill:SetShown(true)
		self.fill:SetColor(theme:RGB(on and "primary" or "surfaceContainerHighest"))
		self.outline:SetShown(not on)
		if not on then self.outline:SetColor(theme:RGB("outline")) end
	end
	self.stateLayer:Paint(theme, "onSurface", nil)
	-- Handle.
	local active = state == "hover" or state == "focus" or state == "pressed"
	local handle
	if disabled then
		handle = on and { theme:RGB("surface") } or { theme:RGB("onSurface") }
		handle[4] = on and 1 or Color.disabledContent
	elseif on then
		handle = { theme:RGB(active and "primaryContainer" or "onPrimary") }
	else
		handle = { theme:RGB(active and "onSurfaceVariant" or "outline") }
	end
	self.handle:SetVertexColor(handle[1], handle[2], handle[3], handle[4] or 1)
	if disabled then
		local r, g, b = theme:RGB("onSurface")
		self.handleIcon:SetColor(r, g, b, Color.disabledContent)
	else
		self.handleIcon:SetColor(theme:RGB(on and "onPrimaryContainer" or "surfaceContainerHighest"))
	end
	self.haloLayer:Paint(theme, on and "primary" or "onSurface", state)
	if not self.tween then self:PlaceHandle(self.handleX or OFF_X, self:HandleSize(state)) end
end

function SwitchMixin:OnActivate()
	self:SetChecked(not self.props.checked, true)
end

---@param checked boolean
---@param userInput? boolean calls onChange
function SwitchMixin:SetChecked(checked, userInput)
	self.props.checked = checked and true or false
	local from = self.handleX or (checked and OFF_X or ON_X)
	local to = checked and ON_X or OFF_X
	T.Motion:Cancel(self.tween)
	self.tween = T.Motion:Tween("medium1", "emphasizedDecelerate", function(p)
		self:PlaceHandle(from + (to - from) * p, self:HandleSize(self:GetState()))
	end, function() self.tween = nil end)
	self:Layout()
	self:Refresh()
	if userInput and self.props.onChange then self.props.onChange(self, self.props.checked) end
end

function SwitchMixin:OnRelease()
	T.Motion:Cancel(self.tween)
	self.tween, self.handleX = nil, nil
end

T:DefineComponent("Switch", { mixin = SwitchMixin, defaults = { checked = false } })
