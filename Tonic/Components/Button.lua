-- M3 common button: filled, tonal, elevated, outlined, text. Height 40, full shape.
--   T.Button:Acquire(parent, { text = "Save", variant = "filled", icon = "check", onClick = fn })

local T = Tonic

---@class TonicButtonProps
---@field text string?
---@field variant "filled"|"tonal"|"elevated"|"outlined"|"text"|"inverseText"?
---@field icon string? leading icon name
---@field width number? dp; default fits the content
---@field height number? dp; default 40
---@field disabled boolean?
---@field tooltip string|table?
---@field onClick fun(self: TonicButton, button: string)?

local VARIANTS = {
	filled = { fill = "primary", content = "onPrimary" },
	tonal = { fill = "secondaryContainer", content = "onSecondaryContainer" },
	elevated = { fill = "surfaceContainerLow", content = "primary" },
	outlined = { outline = "outline", content = "primary" },
	text = { content = "primary" },
	-- Text button on inverse surfaces (snackbar action).
	inverseText = { content = "inversePrimary" },
}

---@class TonicButton: TonicComponent
local ButtonMixin = {}

function ButtonMixin:Build()
	self:CreateContainer()
	self.label = self:CreateLabel("labelLarge")
	self.icon = T.Icon:Create(self.content)
end

function ButtonMixin:Layout()
	local p = self.props
	local textual = p.variant == "text" or p.variant == "inverseText"
	self.label:SetText(p.text or "")
	local hasIcon = p.icon ~= nil
	local hasText = (p.text or "") ~= ""
	local padLeft = textual and 12 or (hasIcon and 16 or 24)
	local padRight = textual and (hasIcon and 16 or 12) or 24
	local iconW = hasIcon and (18 + (hasText and 8 or 0)) or 0
	local textW = hasText and self:TextWidth(self.label) or 0
	local width = p.width or (padLeft + iconW + textW + padRight)
	T.Scale:SetSize(self, width, p.height or 40)

	-- Content group centered in the button.
	local start = (width - (iconW + textW)) / 2
	self.icon:SetShown(hasIcon)
	if hasIcon then
		self.icon:Update({ name = p.icon, size = 18 })
		self.icon:ClearAllPoints()
		T.Scale:SetPoint(self.icon, "LEFT", self, "LEFT", start, 0)
	end
	self.label:ClearAllPoints()
	T.Scale:SetPoint(self.label, "LEFT", self, "LEFT", start + iconW, 0)
	self:LayoutContainer("full")
end

---@param theme TonicTheme
---@param state string?
function ButtonMixin:Render(theme, state)
	local v = VARIANTS[self.props.variant] or VARIANTS.filled
	self:PaintContainer(theme, state, v.fill, v.outline and (state == "focus" and "primary" or v.outline), v.content)
	local r, g, b, a = self:ContentColor(theme, state, v.content)
	self.label:SetTextColor(r, g, b, a)
	self.icon:SetColor(r, g, b, a)
end

---@param text string
function ButtonMixin:SetText(text)
	self:Update({ text = text })
end

T:DefineComponent("Button", { mixin = ButtonMixin, ripple = true, defaults = { variant = "filled" } })
