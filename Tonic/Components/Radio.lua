-- M3 radio button: 20 dp ring (2 dp), 10 dp dot when selected, 40 dp touch target.
-- Groups: give radios the same `group` table; selecting one deselects the others.
--   local group = {}
--   T.Radio:Acquire(parent, { group = group, value = "dark", selected = true, text = "Dark", onChange = fn })

local T = Tonic

local CIRCLE = T.mediaPath .. "Textures\\Circle32"

---@class TonicRadio: TonicComponent
local RadioMixin = {}

function RadioMixin:Build()
	self.halo = CreateFrame("Frame", nil, self)
	self.haloLayer = T.StateLayer:Create(self.halo, "BACKGROUND", -4)
	self.ring = self.content:CreateTexture(nil, "ARTWORK")
	self.dot = self.content:CreateTexture(nil, "OVERLAY")
	self.dot:SetTexture(CIRCLE)
	self.label = self:CreateLabel("bodyMedium")
end

function RadioMixin:OnLevelChanged(level)
	self.halo:SetFrameLevel(level)
end

function RadioMixin:OnAcquire()
	local group = self.props.group
	if group then group[self] = true end
end

function RadioMixin:OnRelease()
	local group = self.props.group
	if group then group[self] = nil end
end

function RadioMixin:Layout()
	local p = self.props
	local hasText = (p.text or "") ~= ""
	self.label:SetShown(hasText)
	self.label:SetText(p.text or "")
	T.Scale:SetSize(self, 40 + (hasText and self:TextWidth(self.label) + 4 or 0), 40)
	T.Scale:SetSize(self.halo, 40, 40)
	self.halo:ClearAllPoints()
	self.halo:SetPoint("LEFT")
	T.Scale:SetSize(self.ring, 20, 20)
	self.ring:ClearAllPoints()
	self.ring:SetPoint("CENTER", self.halo, "CENTER")
	T.Scale:SetSize(self.dot, 10, 10)
	self.dot:ClearAllPoints()
	self.dot:SetPoint("CENTER", self.halo, "CENTER")
	local px = T.Scale:PixelSize(self)
	self.ring:SetTexture(T.Shape:RingTexture(T.Scale:Dp(10, self) / px, T.Scale:Dp(2, self) / px))
	self.label:ClearAllPoints()
	T.Scale:SetPoint(self.label, "LEFT", self, "LEFT", 40, 0)
	self.haloLayer:Layout("full", self.halo)
end

function RadioMixin:Render(theme, state)
	local selected = self.props.selected
	local color = selected and "primary" or "onSurfaceVariant"
	local r, g, b, a = self:ContentColor(theme, state, color)
	self.ring:SetVertexColor(r, g, b, a)
	self.dot:SetShown(selected and true or false)
	self.dot:SetVertexColor(r, g, b, a)
	self.haloLayer:Paint(theme, selected and "primary" or "onSurface", state)
	self.label:SetTextColor(self:ContentColor(theme, state, "onSurface"))
end

---@param selected boolean
function RadioMixin:SetSelected(selected)
	self.props.selected = selected
	self:Refresh()
end

function RadioMixin:OnActivate()
	if self.props.selected then return end
	local group = self.props.group
	if group then
		for other in pairs(group) do
			if other ~= self then other:SetSelected(false) end
		end
	end
	self:SetSelected(true)
	if self.props.onChange then self.props.onChange(self, self.props.value) end
end

T:DefineComponent("Radio", { mixin = RadioMixin, defaults = { selected = false } })
