-- M3 slider on a Blizzard Slider frame (native drag and keyboard): 4 dp tracks,
-- 20 dp handle, value indicator while dragging.
--   T.Slider:Acquire(parent, { min = 0.6, max = 1, step = 0.01, value = 0.88,
--     format = function(v) return ("%d%%"):format(v * 100) end, onChange = fn })

local T = Tonic

local CIRCLE = T.mediaPath .. "Textures\\Circle64"

---@class TonicSlider: TonicComponent, Slider
local SliderMixin = {}

function SliderMixin:Build()
	self:SetOrientation("HORIZONTAL")
	self:SetObeyStepOnDrag(true)
	self.inactive = CreateFrame("Frame", nil, self)
	self.inactiveFill = T.Shape:CreatePieces(self.inactive, "BACKGROUND", -6)
	self.active = CreateFrame("Frame", nil, self)
	self.activeFill = T.Shape:CreatePieces(self.active, "BACKGROUND", -5)
	self.thumb = self:CreateTexture(nil, "OVERLAY")
	self.thumb:SetTexture(CIRCLE)
	self:SetThumbTexture(self.thumb)
	self.halo = CreateFrame("Frame", nil, self)
	self.haloLayer = T.StateLayer:Create(self.halo, "BACKGROUND", -3)

	-- Value indicator.
	self.bubble = CreateFrame("Frame", nil, self)
	self.bubbleFill = T.Shape:CreatePieces(self.bubble, "BACKGROUND", 0)
	self.bubbleText = self.bubble:CreateFontString(nil, "OVERLAY")
	self.bubbleText:SetFontObject(T.Typography:Get("labelMedium", true))
	self.bubbleText:SetPoint("CENTER")
	self.bubble:Hide()

	self.active:SetScript("OnSizeChanged", function() T.Shape:Apply(self.activeFill, self.active, "full") end)
	self:SetScript("OnValueChanged", function(_, value, userInput)
		self.props.value = value
		self:UpdateBubble()
		if userInput and self.props.onChange then self.props.onChange(self, value) end
	end)
	self:HookScript("OnMouseDown", function()
		if not self.props.disabled then self.bubble:Show() end
	end)
	self:HookScript("OnMouseUp", function() self.bubble:Hide() end)
end

function SliderMixin:OnLevelChanged(level)
	self.inactive:SetFrameLevel(level)
	self.active:SetFrameLevel(level)
	self.halo:SetFrameLevel(level)
	self.bubble:SetFrameLevel(level + 5)
end

function SliderMixin:UpdateBubble()
	local format = self.props.format
	local value = self.props.value or 0
	self.bubbleText:SetText(format and format(value) or ("%.2f"):format(value))
	T.Scale:SetSize(self.bubble, math.max(28, self.bubbleText:GetStringWidth() / T.Scale.density + 16), 28)
	T.Shape:Apply(self.bubbleFill, self.bubble, "full")
end

function SliderMixin:Layout()
	local p = self.props
	T.Scale:SetSize(self, p.width or 200, 40)
	T.Scale:SetSize(self.thumb, 20, 20)
	self.inactive:ClearAllPoints()
	self.inactive:SetPoint("LEFT")
	self.inactive:SetPoint("RIGHT")
	self.inactive:SetHeight(T.Scale:Dp(4, self))
	T.Shape:Apply(self.inactiveFill, self.inactive, "full")
	self.active:ClearAllPoints()
	self.active:SetPoint("LEFT", self.inactive, "LEFT")
	self.active:SetPoint("RIGHT", self.thumb, "CENTER")
	self.active:SetHeight(T.Scale:Dp(4, self))
	T.Scale:SetSize(self.halo, 40, 40)
	self.halo:ClearAllPoints()
	self.halo:SetPoint("CENTER", self.thumb, "CENTER")
	self.haloLayer:Layout("full", self.halo)
	self.bubble:ClearAllPoints()
	T.Scale:SetPoint(self.bubble, "BOTTOM", self.thumb, "TOP", 0, 8)

	self:SetMinMaxValues(p.min or 0, p.max or 1)
	self:SetValueStep(p.step or 0.01)
	if p.value then self:SetValue(p.value) end
	self:SetEnabled(not p.disabled)
	self:UpdateBubble()
end

function SliderMixin:Render(theme, state)
	local disabled = state == "disabled"
	local Color = T.Color.STATE
	if disabled then
		local r, g, b = theme:RGB("onSurface")
		self.activeFill:SetColor(r, g, b, Color.disabledContent)
		self.inactiveFill:SetColor(r, g, b, Color.disabledContainer)
		self.thumb:SetVertexColor(r, g, b, Color.disabledContent)
	else
		self.activeFill:SetColor(theme:RGB("primary"))
		self.inactiveFill:SetColor(theme:RGB("secondaryContainer"))
		self.thumb:SetVertexColor(theme:RGB("primary"))
	end
	self.haloLayer:Paint(theme, "primary", state)
	self.bubbleFill:SetColor(theme:RGB("inverseSurface"))
	self.bubbleText:SetTextColor(theme:RGB("inverseOnSurface"))
end

T:DefineComponent("Slider", { mixin = SliderMixin, frameType = "Slider", defaults = { min = 0, max = 1, step = 0.01 } })
