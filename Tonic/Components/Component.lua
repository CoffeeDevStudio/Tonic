-- Component base: pooled, mixin-based frames with the Tonic contract
--   :ApplyTheme(theme)  :SetState(state)  :Update(props)  :Release()
-- Interaction (hover, press, focus, disabled), ripple and tooltip are handled here;
-- a component implements Build (once), Layout (size/positions) and Render (colors).
--
--   T:DefineComponent("Button", { mixin = ButtonMixin, ripple = true, defaults = { variant = "filled" } })
--   local b = T.Button:Acquire(parent, { text = "Save", onClick = fn })

local T = Tonic

---@class TonicComponent: Button
---@field props table
---@field theme TonicTheme?
---@field factory table
---@field content Frame child frame for labels and icons (above ripple and state layer)
---@field ripple TonicRipple?
---@field hovered boolean
---@field pressed boolean
---@field focused boolean
---@field forcedState string?
local ComponentMixin = {}
T.ComponentMixin = ComponentMixin

---Current M3 state: "disabled", "pressed", "focus", "hover" or nil.
---@return string?
function ComponentMixin:GetState()
	if self.props.disabled then return "disabled" end
	if self.forcedState then return self.forcedState end
	if self.pressed then return "pressed" end
	if self.focused then return "focus" end
	if self.hovered then return "hover" end
	return nil
end

---Forces a visual state (gallery, previews). nil returns to interactive states.
---@param state string?
function ComponentMixin:SetState(state)
	self.forcedState = state
	self:Refresh()
end

---@param theme TonicTheme
function ComponentMixin:ApplyTheme(theme)
	self.theme = theme
	self:Refresh()
end

function ComponentMixin:Refresh()
	if self.theme and self.Render then self:Render(self.theme, self:GetState()) end
end

---Merges props, then lays out and re-renders.
---@param props table
function ComponentMixin:Update(props)
	for k, v in pairs(props) do self.props[k] = v end
	if props.theme then
		T.Theme:Unregister(self)
		self.theme = props.theme
	end
	if self.Layout then self:Layout() end
	self:Refresh()
end

function ComponentMixin:Release()
	self.factory.pool:Release(self)
end

---@param disabled boolean
function ComponentMixin:SetDisabled(disabled)
	self:Update({ disabled = disabled })
end

---Keeps child frame levels relative to the component after a reparent.
function ComponentMixin:SyncLevels()
	local level = self:GetFrameLevel()
	if self.ripple then self.ripple.clip:SetFrameLevel(level + 1) end
	self.content:SetFrameLevel(level + 2)
	if self.OnLevelChanged then self:OnLevelChanged(level) end
end

-- ------------------------------------------------------------- container helpers

---Creates fill, outline and state layer pieces on target (default self).
---@param target? Frame
function ComponentMixin:CreateContainer(target)
	target = target or self
	self.fill = T.Shape:CreatePieces(target, "BACKGROUND", -6)
	self.outline = T.Shape:CreateOutline(target, "BACKGROUND", -5)
	self.stateLayer = T.StateLayer:Create(target, "BACKGROUND", -4)
end

---@param shape string|number
---@param target? Frame
---@param outlineDp? number
function ComponentMixin:LayoutContainer(shape, target, outlineDp)
	target = target or self
	self.containerShape = shape
	T.Shape:Apply(self.fill, target, shape)
	T.Shape:ApplyOutline(self.outline, target, shape, outlineDp or 1)
	self.stateLayer:Layout(shape, target)
	if self.ripple then self.ripple:SetShape(shape) end
end

---Paints the container. Color names may be nil (hidden part).
---@param theme TonicTheme
---@param state string?
---@param fill string?
---@param outline string?
---@param content string content color, used by the state layer and the ripple
function ComponentMixin:PaintContainer(theme, state, fill, outline, content)
	local disabled = state == "disabled"
	if fill then
		local r, g, b = theme:RGB(disabled and "onSurface" or fill)
		self.fill:SetShown(true)
		self.fill:SetColor(r, g, b, disabled and T.Color.STATE.disabledContainer or 1)
	else
		self.fill:SetShown(false)
	end
	if outline then
		local r, g, b = theme:RGB(disabled and "onSurface" or outline)
		self.outline:SetShown(true)
		self.outline:SetColor(r, g, b, disabled and T.Color.STATE.disabledContainer or 1)
	else
		self.outline:SetShown(false)
	end
	self.stateLayer:Paint(theme, content, state)
	self.rippleColor = content
end

---Content color (text, icon) for a state: onSurface at 38% when disabled.
---@param theme TonicTheme
---@param state string?
---@param color string
---@return number r, number g, number b, number a
function ComponentMixin:ContentColor(theme, state, color)
	if state == "disabled" then
		local r, g, b = theme:RGB("onSurface")
		return r, g, b, T.Color.STATE.disabledContent
	end
	local r, g, b = theme:RGB(color)
	return r, g, b, 1
end

---Creates a FontString owned by the component, on its content frame.
---@param role string
---@return FontString
function ComponentMixin:CreateLabel(role)
	local fs = self.content:CreateFontString(nil, "OVERLAY")
	fs:SetFontObject(T.Typography:Get(role))
	fs:SetWordWrap(false)
	return fs
end

---Text width in dp.
---@param fs FontString
---@return number
function ComponentMixin:TextWidth(fs)
	return fs:GetStringWidth() / T.Scale.density
end

-- ------------------------------------------------------------- interaction

local function onEnter(self)
	self.hovered = true
	self:Refresh()
	if self.props.tooltip and T.Tooltip then T.Tooltip:ShowFor(self, self.props.tooltip) end
	if self.OnHover then self:OnHover(true) end
end

local function onLeave(self)
	self.hovered = false
	self.pressed = false
	self:Refresh()
	if T.Tooltip then T.Tooltip:HideFor(self) end
	if self.ripple then self.ripple:Release() end
	if self.OnHover then self:OnHover(false) end
end

local function onMouseDown(self, button)
	if self.props.disabled or button ~= "LeftButton" then return end
	self.pressed = true
	self:Refresh()
	if self.ripple then self.ripple:Press(self.theme, self.rippleColor or "onSurface") end
end

local function onMouseUp(self)
	self.pressed = false
	self:Refresh()
	if self.ripple then self.ripple:Release() end
end

local function onClick(self, button)
	if self.props.disabled then return end
	if self.OnActivate then self:OnActivate(button) end
	if self.props.onClick then self.props.onClick(self, button) end
end

-- ------------------------------------------------------------- definition

---@class TonicComponentDef
---@field mixin table
---@field frameType string? default "Button"
---@field template string?
---@field defaults table?
---@field ripple boolean?
---@field interactive boolean? default true: hover/press/click handling

---Defines a pooled component and exposes its factory as T[name].
---@param name string
---@param def TonicComponentDef
---@return table factory with :Acquire(parent, props) and .pool
function T:DefineComponent(name, def)
	local factory = { name = name, defaults = def.defaults or {} }

	factory.pool = T.CreatePool(function()
		local f = CreateFrame(def.frameType or "Button", nil, T.hiddenParent, def.template)
		Mixin(f, ComponentMixin, def.mixin)
		f.factory = factory
		f.props = {}
		f.hovered, f.pressed, f.focused = false, false, false
		if def.ripple then f.ripple = T.Ripple:Attach(f) end
		f.content = CreateFrame("Frame", nil, f)
		f.content:SetAllPoints()
		if def.interactive ~= false then
			f:SetScript("OnEnter", onEnter)
			f:SetScript("OnLeave", onLeave)
			f:SetScript("OnMouseDown", onMouseDown)
			f:SetScript("OnMouseUp", onMouseUp)
			if f.RegisterForClicks then
				f:RegisterForClicks("LeftButtonUp")
				f:SetScript("OnClick", onClick)
			end
		end
		if f.Build then f:Build() end
		return f
	end, function(_, f)
		T.Theme:Unregister(f)
		if T.Tooltip then T.Tooltip:HideFor(f) end
		if f.OnRelease then f:OnRelease() end
		f:Hide()
		f:ClearAllPoints()
		f:SetParent(T.hiddenParent)
		f.hovered, f.pressed, f.focused, f.forcedState = false, false, false, nil
		f.theme = nil
		f.props = {}
	end)

	---@param parent Frame
	---@param props? table
	function factory:Acquire(parent, props)
		local f = self.pool:Acquire()
		f.props = {}
		for k, v in pairs(self.defaults) do f.props[k] = v end
		for k, v in pairs(props or {}) do f.props[k] = v end
		f:SetParent(parent)
		f:SetFrameStrata(parent:GetFrameStrata())
		f:SetFrameLevel(parent:GetFrameLevel() + 1)
		f:SyncLevels()
		if f.OnAcquire then f:OnAcquire() end
		f:Show()
		if f.Layout then f:Layout() end
		if f.props.theme then
			f.theme = f.props.theme
			f:Refresh()
		else
			T.Theme:Register(f)
		end
		return f
	end

	T[name] = factory
	return factory
end
