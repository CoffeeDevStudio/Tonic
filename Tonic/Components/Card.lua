-- M3 card: elevated (tonal, flat in Tonic), filled, outlined. Shape M 12.
-- Put your own content on card.body; title/subtitle/text are optional built-ins.
--   local card = T.Card:Acquire(parent, { variant = "filled", width = 280, height = 120, title = "Bags" })

local T = Tonic

local VARIANTS = {
	elevated = { fill = "surfaceContainerLow" },
	filled = { fill = "surfaceContainerHighest" },
	outlined = { fill = "surface", outline = "outlineVariant" },
}

---@class TonicCard: TonicComponent
---@field body Frame
local CardMixin = {}

function CardMixin:Build()
	self:CreateContainer()
	self.title = self:CreateLabel("titleMedium")
	self.subtitle = self:CreateLabel("bodyMedium")
	self.text = self:CreateLabel("bodyMedium")
	self.text:SetWordWrap(true)
	self.text:SetJustifyH("LEFT")
	self.text:SetJustifyV("TOP")
	self.body = CreateFrame("Frame", nil, self)
	self.body:SetAllPoints()
end

function CardMixin:OnLevelChanged(level)
	self.body:SetFrameLevel(level + 3)
end

function CardMixin:Layout()
	local p = self.props
	T.Scale:SetSize(self, p.width or 280, p.height or 120)
	self:EnableMouse(p.onClick ~= nil)
	local y = 16
	for _, key in ipairs({ "title", "subtitle", "text" }) do
		local fs = self[key]
		local value = p[key]
		fs:SetShown(value ~= nil)
		if value then
			fs:SetText(value)
			fs:ClearAllPoints()
			T.Scale:SetPoint(fs, "TOPLEFT", self, "TOPLEFT", 16, -y)
			if key == "text" then T.Scale:SetPoint(fs, "BOTTOMRIGHT", self, "BOTTOMRIGHT", -16, 16) end
			y = y + (key == "title" and 26 or 22)
		end
	end
	self:LayoutContainer("m")
end

function CardMixin:Render(theme, state)
	local v = VARIANTS[self.props.variant] or VARIANTS.filled
	-- A card is never "disabled" visually as a container; only interactive cards get states.
	local s = self.props.onClick and state or nil
	self:PaintContainer(theme, s ~= "disabled" and s or nil, v.fill, v.outline, "onSurface")
	self.title:SetTextColor(theme:RGB("onSurface"))
	self.subtitle:SetTextColor(theme:RGB("onSurfaceVariant"))
	self.text:SetTextColor(theme:RGB("onSurfaceVariant"))
end

T:DefineComponent("Card", { mixin = CardMixin, ripple = true, defaults = { variant = "filled" } })
