-- M3 text field: filled or outlined, 56 dp, floating label, supporting/error text.
--   T.TextField:Acquire(parent, { label = "Profile name", variant = "outlined", onSubmit = fn })

local T = Tonic

---@class TonicTextFieldProps
---@field label string?
---@field text string? initial text
---@field variant "filled"|"outlined"?
---@field supporting string?
---@field error string? replaces the supporting text and turns the field red
---@field width number? dp, default 240
---@field background string? color behind an outlined field (label notch), default "surface"
---@field maxLetters integer?
---@field disabled boolean?
---@field onChange fun(self: TonicTextField, text: string)?
---@field onSubmit fun(self: TonicTextField, text: string)?

---@class TonicTextField: TonicComponent
local TextFieldMixin = {}

local HAS_TEXT_SCALE

function TextFieldMixin:Build()
	self.field = CreateFrame("Frame", nil, self)
	self:CreateContainer(self.field)
	self.indicator = self.field:CreateTexture(nil, "BORDER")
	self.indicator:SetTexture(T.Shape.white)
	self.notch = self.field:CreateTexture(nil, "BORDER")
	self.notch:SetTexture(T.Shape.white)
	self.label = self:CreateLabel("bodyLarge")
	self.supporting = self:CreateLabel("bodySmall")

	local edit = CreateFrame("EditBox", nil, self)
	edit:SetAutoFocus(false)
	edit:SetFontObject(T.Typography:Get("bodyLarge"))
	edit:SetTextInsets(0, 0, 0, 0)
	edit:SetScript("OnEditFocusGained", function()
		self.focused = true
		self:Float(true)
		self:Refresh()
	end)
	edit:SetScript("OnEditFocusLost", function()
		self.focused = false
		self:Float(edit:GetText() ~= "")
		self:Refresh()
	end)
	edit:SetScript("OnTextChanged", function(_, userInput)
		self.props.text = edit:GetText()
		if userInput and self.props.onChange then self.props.onChange(self, self.props.text) end
	end)
	edit:SetScript("OnEnterPressed", function()
		if self.props.onSubmit then self.props.onSubmit(self, edit:GetText()) end
		edit:ClearFocus()
	end)
	edit:SetScript("OnEscapePressed", function() edit:ClearFocus() end)
	self.edit = edit
	HAS_TEXT_SCALE = self.label.SetTextScale ~= nil
end

function TextFieldMixin:OnLevelChanged(level)
	self.field:SetFrameLevel(level)
	self.edit:SetFrameLevel(level + 3)
end

-- Label position for progress p (0 = resting inside, 1 = floated).
function TextFieldMixin:PlaceLabel(p)
	self.floatProgress = p
	local outlined = self.props.variant == "outlined"
	local restY, floatY = -28, outlined and 0 or -14
	self.label:ClearAllPoints()
	T.Scale:SetPoint(self.label, "LEFT", self.field, "TOPLEFT", 16, restY + (floatY - restY) * p)
	if HAS_TEXT_SCALE then
		self.label:SetTextScale(1 - 0.25 * p)
	else
		self.label:SetFontObject(T.Typography:Get(p >= 0.5 and "bodySmall" or "bodyLarge"))
	end
	-- Notch: background patch that interrupts the outline behind the floated label.
	local showNotch = outlined and p > 0.5 and (self.props.label or "") ~= ""
	self.notch:SetShown(showNotch)
	if showNotch then
		local w = self:TextWidth(self.label) * (HAS_TEXT_SCALE and 0.75 or 1) + 8
		self.notch:ClearAllPoints()
		T.Scale:SetPoint(self.notch, "LEFT", self.field, "TOPLEFT", 12, 0)
		T.Scale:SetSize(self.notch, w, 4)
	end
end

---@param floated boolean
function TextFieldMixin:Float(floated)
	if (self.props.label or "") == "" then return end
	local from, to = self.floatProgress or 0, floated and 1 or 0
	if from == to then return end
	T.Motion:Cancel(self.tween)
	self.tween = T.Motion:Tween("short4", "standard", function(p) self:PlaceLabel(from + (to - from) * p) end,
		function() self.tween = nil end)
end

function TextFieldMixin:Layout()
	local p = self.props
	local width = p.width or 240
	local supportingText = p.error or p.supporting
	T.Scale:SetSize(self, width, 56 + (supportingText and 20 or 0))
	self.field:ClearAllPoints()
	self.field:SetPoint("TOPLEFT")
	self.field:SetPoint("TOPRIGHT")
	self.field:SetHeight(T.Scale:Dp(56, self))

	local outlined = p.variant == "outlined"
	T.Shape:Apply(self.fill, self.field, "xs", nil, not outlined)
	T.Shape:ApplyOutline(self.outline, self.field, "xs", self.focused and 2 or 1)
	self.stateLayer:Layout("xs", self.field)
	self.indicator:ClearAllPoints()
	self.indicator:SetPoint("BOTTOMLEFT", self.field, "BOTTOMLEFT")
	self.indicator:SetPoint("BOTTOMRIGHT", self.field, "BOTTOMRIGHT")
	self.indicator:SetHeight(T.Scale:Dp(self.focused and 2 or 1, self))
	self.indicator:SetShown(not outlined)

	self.label:SetText(p.label or "")
	self.label:SetShown((p.label or "") ~= "")
	self.edit:ClearAllPoints()
	local hasLabel = (p.label or "") ~= ""
	if outlined or not hasLabel then
		T.Scale:SetPoint(self.edit, "LEFT", self.field, "LEFT", 16, 0)
		T.Scale:SetPoint(self.edit, "RIGHT", self.field, "RIGHT", -16, 0)
		self.edit:SetHeight(T.Scale:Dp(24, self))
	else
		T.Scale:SetPoint(self.edit, "TOPLEFT", self.field, "TOPLEFT", 16, -24)
		T.Scale:SetPoint(self.edit, "BOTTOMRIGHT", self.field, "BOTTOMRIGHT", -16, 6)
	end
	if p.maxLetters then self.edit:SetMaxLetters(p.maxLetters) end
	if p.text ~= nil and p.text ~= self.edit:GetText() then self.edit:SetText(p.text) end
	self.edit:SetEnabled(not p.disabled)
	if not self.tween then self:PlaceLabel((self.focused or self.edit:GetText() ~= "") and 1 or 0) end

	self.supporting:SetShown(supportingText ~= nil)
	self.supporting:SetText(supportingText or "")
	self.supporting:ClearAllPoints()
	T.Scale:SetPoint(self.supporting, "TOPLEFT", self.field, "BOTTOMLEFT", 16, -4)
end

function TextFieldMixin:Render(theme, state)
	local p = self.props
	local disabled = state == "disabled"
	local Color = T.Color.STATE
	local accent = p.error and "error" or (self.focused and "primary" or nil)
	local outlined = p.variant == "outlined"

	if outlined then
		self.fill:SetShown(false)
		self.outline:SetShown(true)
		local name = accent or (state == "hover" and "onSurface" or "outline")
		local r, g, b = theme:RGB(disabled and "onSurface" or name)
		self.outline:SetColor(r, g, b, disabled and Color.disabledContainer or 1)
		self.notch:SetVertexColor(theme:RGB(p.background or "surface"))
	else
		self.outline:SetShown(false)
		self.fill:SetShown(true)
		local fr, fg, fb = theme:RGB(disabled and "onSurface" or "surfaceContainerHighest")
		self.fill:SetColor(fr, fg, fb, disabled and 0.04 or 1)
		local name = accent or (state == "hover" and "onSurface" or "onSurfaceVariant")
		local r, g, b = theme:RGB(disabled and "onSurface" or name)
		self.indicator:SetVertexColor(r, g, b, disabled and Color.disabledContent or 1)
	end
	self.stateLayer:Paint(theme, "onSurface", (not outlined and state == "hover") and "hover" or nil)
	self.label:SetTextColor(self:ContentColor(theme, state, accent or "onSurfaceVariant"))
	self.edit:SetTextColor(self:ContentColor(theme, state, "onSurface"))
	self.supporting:SetTextColor(self:ContentColor(theme, state, p.error and "error" or "onSurfaceVariant"))
	-- Stroke width follows focus.
	T.Shape:ApplyOutline(self.outline, self.field, "xs", self.focused and 2 or 1)
	self.indicator:SetHeight(T.Scale:Dp(self.focused and 2 or 1, self))
end

function TextFieldMixin:OnActivate()
	self.edit:SetFocus()
end

---@return string
function TextFieldMixin:GetText()
	return self.edit:GetText()
end

---@param text string
function TextFieldMixin:SetText(text)
	self.props.text = text
	self.edit:SetText(text or "")
	self:PlaceLabel((self.focused or (text or "") ~= "") and 1 or 0)
end

function TextFieldMixin:OnRelease()
	T.Motion:Cancel(self.tween)
	self.tween, self.floatProgress = nil, nil
	self.edit:ClearFocus()
	self.edit:SetText("")
end

T:DefineComponent("TextField", { mixin = TextFieldMixin, defaults = { variant = "filled" } })
