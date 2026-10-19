-- M3 icon button: standard, filled, tonal, outlined; optional toggle. 40x40, icon 24.
--   T.IconButton:Acquire(parent, { icon = "close", onClick = fn, tooltip = "Close" })

local T = Tonic

---@class TonicIconButtonProps
---@field icon string
---@field variant "standard"|"filled"|"tonal"|"outlined"?
---@field toggle boolean? click flips `selected`
---@field selected boolean?
---@field size number? dp, default 40
---@field disabled boolean?
---@field tooltip string|table?
---@field onClick fun(self: TonicIconButton, button: string)?
---@field onChange fun(self: TonicIconButton, selected: boolean)?

-- [variant] = { selected/unselected: fill, outline, content }
local VARIANTS = {
	standard = {
		on = { content = "primary" },
		off = { content = "onSurfaceVariant" },
	},
	filled = {
		on = { fill = "primary", content = "onPrimary" },
		off = { fill = "surfaceContainerHighest", content = "primary" },
	},
	tonal = {
		on = { fill = "secondaryContainer", content = "onSecondaryContainer" },
		off = { fill = "surfaceContainerHighest", content = "onSurfaceVariant" },
	},
	outlined = {
		on = { fill = "inverseSurface", content = "inverseOnSurface" },
		off = { outline = "outline", content = "onSurfaceVariant" },
	},
}

---@class TonicIconButton: TonicComponent
local IconButtonMixin = {}

function IconButtonMixin:Build()
	self:CreateContainer()
	self.icon = T.Icon:Create(self.content)
	self.icon:SetPoint("CENTER")
end

function IconButtonMixin:Layout()
	local size = self.props.size or 40
	T.Scale:SetSize(self, size, size)
	self.icon:Update({ name = self.props.icon, size = 24 })
	self:LayoutContainer("full")
end

function IconButtonMixin:Render(theme, state)
	local v = VARIANTS[self.props.variant] or VARIANTS.standard
	-- Non-toggle buttons use the "selected" look of filled/tonal, the base look otherwise.
	local selected = self.props.selected
	if not self.props.toggle then selected = self.props.variant == "filled" or self.props.variant == "tonal" end
	local c = selected and v.on or v.off
	self:PaintContainer(theme, state, c.fill, c.outline, c.content)
	self.icon:SetColor(self:ContentColor(theme, state, c.content))
end

function IconButtonMixin:OnActivate()
	if self.props.toggle then
		self.props.selected = not self.props.selected
		self:Refresh()
		if self.props.onChange then self.props.onChange(self, self.props.selected) end
	end
end

T:DefineComponent("IconButton", { mixin = IconButtonMixin, ripple = true, defaults = { variant = "standard" } })
