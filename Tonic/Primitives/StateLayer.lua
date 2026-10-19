-- StateLayer: the M3 state overlay. The content color of a component, at the state
-- opacity (hover 8%, focus/pressed 10%), in the same shape as the component.
-- With the ripple on, the press is shown by the ripple and the layer stays at hover.

local T = Tonic

---@class TonicStateLayer
---@field pieces TonicShapePieces
---@field region Region
local StateLayerMixin = {}

---@param region? Region where the layer is laid out (default: the owner)
---@param shape string|number
function StateLayerMixin:Layout(shape, region)
	self.region = region or self.owner
	self.shape = shape
	T.Shape:Apply(self.pieces, self.region, shape)
end

---@param theme TonicTheme
---@param colorName string content color
---@param state string?
function StateLayerMixin:Paint(theme, colorName, state)
	local opacity = state and state ~= "disabled" and T.Color.STATE[state]
	if state == "pressed" and theme.ripple then opacity = T.Color.STATE.hover end
	if not opacity then
		self.pieces:SetShown(false)
		return
	end
	local r, g, b = theme:RGB(colorName)
	self.pieces:SetShown(true)
	self.pieces:SetColor(r, g, b, opacity)
end

---@class TonicStateLayerFactory
local StateLayer = {}
T.StateLayer = StateLayer

---Creates a state layer drawn on owner.
---@param owner Frame
---@param layer? DrawLayer default "BACKGROUND"
---@param sublevel? integer default -4
---@return TonicStateLayer
function StateLayer:Create(owner, layer, sublevel)
	local s = CreateFromMixins(StateLayerMixin)
	s.owner = owner
	s.pieces = T.Shape:CreatePieces(owner, layer or "BACKGROUND", sublevel or -4)
	s.pieces:SetShown(false)
	return s
end
