-- M3 checkbox: 18 dp box, 2 dp stroke, 40 dp touch target; checked, unchecked,
-- indeterminate, error. Optional label on the right.
--   T.Checkbox:Acquire(parent, { checked = true, text = "Show bags", onChange = fn })

local T = Tonic

---@class TonicCheckbox: TonicComponent
local CheckboxMixin = {}

function CheckboxMixin:Build()
	self.halo = CreateFrame("Frame", nil, self)
	self.haloLayer = T.StateLayer:Create(self.halo, "BACKGROUND", -4)
	self.box = CreateFrame("Frame", nil, self)
	self.boxFill = T.Shape:CreatePieces(self.box, "BACKGROUND", -2)
	self.boxOutline = T.Shape:CreateOutline(self.box, "BACKGROUND", -1)
	self.mark = T.Icon:Create(self.content)
	self.label = self:CreateLabel("bodyMedium")
end

function CheckboxMixin:OnLevelChanged(level)
	self.halo:SetFrameLevel(level)
	self.box:SetFrameLevel(level + 1)
end

function CheckboxMixin:Layout()
	local p = self.props
	local hasText = (p.text or "") ~= ""
	self.label:SetShown(hasText)
	self.label:SetText(p.text or "")
	local width = 40 + (hasText and self:TextWidth(self.label) + 4 or 0)
	T.Scale:SetSize(self, width, 40)
	T.Scale:SetSize(self.halo, 40, 40)
	self.halo:ClearAllPoints()
	self.halo:SetPoint("LEFT")
	T.Scale:SetSize(self.box, 18, 18)
	self.box:ClearAllPoints()
	self.box:SetPoint("CENTER", self.halo, "CENTER")
	self.mark:ClearAllPoints()
	self.mark:SetPoint("CENTER", self.box, "CENTER")
	self.label:ClearAllPoints()
	T.Scale:SetPoint(self.label, "LEFT", self, "LEFT", 40, 0)
	T.Shape:Apply(self.boxFill, self.box, 2)
	T.Shape:ApplyOutline(self.boxOutline, self.box, 2, 2)
	self.haloLayer:Layout("full", self.halo)
	local checked = p.checked
	self.mark:SetShown(checked and true or false)
	if checked then self.mark:Update({ name = checked == "indeterminate" and "remove" or "check", size = 18 }) end
end

function CheckboxMixin:Render(theme, state)
	local p = self.props
	local disabled = state == "disabled"
	local accent = p.error and "error" or "primary"
	local onAccent = p.error and "onError" or "onPrimary"
	local alpha = T.Color.STATE.disabledContent
	if p.checked then
		self.boxOutline:SetShown(false)
		self.boxFill:SetShown(true)
		if disabled then
			local r, g, b = theme:RGB("onSurface")
			self.boxFill:SetColor(r, g, b, alpha)
			self.mark:SetColor(theme:RGB("surface"))
		else
			self.boxFill:SetColor(theme:RGB(accent))
			self.mark:SetColor(theme:RGB(onAccent))
		end
	else
		self.boxFill:SetShown(false)
		self.boxOutline:SetShown(true)
		local r, g, b = theme:RGB(disabled and "onSurface" or (p.error and "error" or "onSurfaceVariant"))
		self.boxOutline:SetColor(r, g, b, disabled and alpha or 1)
	end
	self.haloLayer:Paint(theme, p.error and "error" or (p.checked and "primary" or "onSurface"), state)
	self.label:SetTextColor(self:ContentColor(theme, state, "onSurface"))
end

function CheckboxMixin:OnActivate()
	self.props.checked = not (self.props.checked == true)
	self:Layout()
	self:Refresh()
	if self.props.onChange then self.props.onChange(self, self.props.checked) end
end

T:DefineComponent("Checkbox", { mixin = CheckboxMixin, defaults = { checked = false } })
