-- M3 floating action button: small 40, standard 56, large 96; extended with a label.
-- Flat: in Tonic shadows are reserved to windows and menus.
--   T.FAB:Acquire(parent, { icon = "add", text = "New", color = "primary", onClick = fn })

local T = Tonic

local SIZES = {
	small = { size = 40, shape = 12, icon = 24 },
	standard = { size = 56, shape = 16, icon = 24 },
	large = { size = 96, shape = 28, icon = 36 },
}

local COLORS = {
	primary = { fill = "primaryContainer", content = "onPrimaryContainer" },
	secondary = { fill = "secondaryContainer", content = "onSecondaryContainer" },
	tertiary = { fill = "tertiaryContainer", content = "onTertiaryContainer" },
	surface = { fill = "surfaceContainerHigh", content = "primary" },
}

---@class TonicFAB: TonicComponent
local FABMixin = {}

function FABMixin:Build()
	self:CreateContainer()
	self.icon = T.Icon:Create(self.content)
	self.label = self:CreateLabel("labelLarge")
end

function FABMixin:Layout()
	local p = self.props
	local spec = SIZES[p.size] or SIZES.standard
	local extended = (p.text or "") ~= ""
	self.label:SetShown(extended)
	self.icon:Update({ name = p.icon or "add", size = spec.icon })
	self.icon:ClearAllPoints()
	self.label:ClearAllPoints()
	if extended then
		self.label:SetText(p.text)
		local width = 16 + 24 + 12 + self:TextWidth(self.label) + 20
		T.Scale:SetSize(self, width, 56)
		T.Scale:SetPoint(self.icon, "LEFT", self, "LEFT", 16, 0)
		T.Scale:SetPoint(self.label, "LEFT", self.icon, "RIGHT", 12, 0)
		self:LayoutContainer(16)
	else
		T.Scale:SetSize(self, spec.size, spec.size)
		self.icon:SetPoint("CENTER")
		self:LayoutContainer(spec.shape)
	end
end

function FABMixin:Render(theme, state)
	local c = COLORS[self.props.color] or COLORS.primary
	self:PaintContainer(theme, state, c.fill, nil, c.content)
	local r, g, b, a = self:ContentColor(theme, state, c.content)
	self.icon:SetColor(r, g, b, a)
	self.label:SetTextColor(r, g, b, a)
end

T:DefineComponent("FAB", { mixin = FABMixin, ripple = true, defaults = { size = "standard", color = "primary" } })
