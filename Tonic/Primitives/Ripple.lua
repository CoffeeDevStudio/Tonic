-- Ripple: a circle that grows from the press point (AnimationGroup) clipped to the
-- component. Pill shapes use a MaskTexture of the same shape; other shapes are clipped
-- to their rectangle (their small radius makes the difference invisible at 10%).
-- Disabled with the "ripple" option.

local T = Tonic

local CIRCLE = T.mediaPath .. "Textures\\Circle128"
local PILLS = { [1] = T.mediaPath .. "Textures\\Circle64", [2] = T.mediaPath .. "Textures\\Pill2",
	[4] = T.mediaPath .. "Textures\\Pill4", [8] = T.mediaPath .. "Textures\\Pill8" }

---@class TonicRipple
---@field owner Frame
---@field clip Frame
---@field texture Texture
---@field mask MaskTexture
local RippleMixin = {}

---Sets the mask for the owner's shape. Call after the owner is sized.
---@param shape string|number
function RippleMixin:SetShape(shape)
	local file = Tonic.Shape.white
	if shape == "full" then
		local w, h = self.owner:GetSize()
		local aspect = h > 0 and w / h or 1
		local best = 1
		for _, a in ipairs({ 1, 2, 4, 8 }) do
			if math.abs(math.log(aspect / a)) < math.abs(math.log(aspect / best)) then best = a end
		end
		if w < h then best = 1 end
		file = PILLS[best]
	end
	self.mask:SetTexture(file, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
end

---Starts the ripple at the cursor.
---@param theme TonicTheme
---@param colorName string content color
function RippleMixin:Press(theme, colorName)
	if not theme or not theme.ripple then return end
	local owner = self.owner
	local left, bottom = owner:GetLeft(), owner:GetBottom()
	if not left then return end
	local x, y = GetCursorPosition()
	local scale = owner:GetEffectiveScale()
	x, y = x / scale - left, y / scale - bottom
	local w, h = owner:GetSize()
	local dx, dy = math.max(x, w - x), math.max(y, h - y)
	local radius = math.sqrt(dx * dx + dy * dy)
	local tex = self.texture
	tex:ClearAllPoints()
	tex:SetPoint("CENTER", self.clip, "BOTTOMLEFT", x, y)
	tex:SetSize(radius * 2, radius * 2)
	local r, g, b = theme:RGB(colorName)
	tex:SetVertexColor(r, g, b, T.Color.STATE.pressed)
	self.fade:Stop()
	tex:SetAlpha(1)
	tex:Show()
	self.grow:Restart()
end

---Fades the ripple out.
function RippleMixin:Release()
	if self.texture:IsShown() then self.fade:Restart() end
end

---@class TonicRippleFactory
local Ripple = {}
T.Ripple = Ripple

---Attaches a ripple to owner, under content drawn on frames above clipLevel.
---@param owner Frame
---@return TonicRipple
function Ripple:Attach(owner)
	local r = CreateFromMixins(RippleMixin)
	r.owner = owner
	local clip = CreateFrame("Frame", nil, owner)
	clip:SetAllPoints()
	clip:SetClipsChildren(true)
	r.clip = clip

	local tex = clip:CreateTexture(nil, "ARTWORK")
	tex:SetTexture(CIRCLE)
	tex:Hide()
	r.texture = tex

	local mask = clip:CreateMaskTexture()
	mask:SetAllPoints(clip)
	mask:SetTexture(Tonic.Shape.white, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	tex:AddMaskTexture(mask)
	r.mask = mask

	local grow = tex:CreateAnimationGroup()
	local scale = grow:CreateAnimation("Scale")
	scale:SetScaleFrom(0.1, 0.1)
	scale:SetScaleTo(1, 1)
	scale:SetDuration(T.Motion.durations.medium2)
	scale:SetSmoothing("OUT")
	r.grow = grow

	local fade = tex:CreateAnimationGroup()
	local alpha = fade:CreateAnimation("Alpha")
	alpha:SetFromAlpha(1)
	alpha:SetToAlpha(0)
	alpha:SetDuration(T.Motion.durations.short4)
	fade:SetScript("OnFinished", function() tex:Hide() end)
	r.fade = fade
	return r
end
