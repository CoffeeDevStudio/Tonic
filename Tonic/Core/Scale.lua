-- dp -> pixel-perfect UI units.
-- 1 dp is one UI unit at Tonic density 1. Sizes and offsets are snapped to whole
-- physical pixels for the effective scale of the region they are applied to.

local T = Tonic

---@class TonicScale
local Scale = {
	density = 1,
}
T.Scale = Scale

local floor, max = math.floor, math.max

---Size of one physical pixel in the coordinate space of region (default UIParent).
---@param region? Region
---@return number
function Scale:PixelSize(region)
	local _, height = GetPhysicalScreenSize()
	return 768 / height / (region or UIParent):GetEffectiveScale()
end

---Converts dp to UI units snapped to the pixel grid. Non-zero values are at least 1 px.
---@param dp number
---@param region? Region
---@return number
function Scale:Dp(dp, region)
	if dp == 0 then return 0 end
	local px = self:PixelSize(region)
	local pixels = floor(dp * self.density / px + 0.5)
	if dp > 0 then pixels = max(pixels, 1) else pixels = math.min(pixels, -1) end
	return pixels * px
end

---Converts dp to whole physical pixels.
---@param dp number
---@param region? Region
---@return integer
function Scale:Pixels(dp, region)
	return floor(dp * self.density / self:PixelSize(region) + 0.5)
end

---@param region Region
---@param width number dp
---@param height number dp
function Scale:SetSize(region, width, height)
	region:SetSize(self:Dp(width, region), self:Dp(height, region))
end

---SetPoint with dp offsets.
---@param region Region
function Scale:SetPoint(region, point, relativeTo, relativePoint, x, y)
	region:SetPoint(point, relativeTo, relativePoint, self:Dp(x or 0, region), self:Dp(y or 0, region))
end

local Watcher = {}
function Watcher:UI_SCALE_CHANGED() T.Events:SendMessage("Tonic.ScaleChanged") end
Watcher.DISPLAY_SIZE_CHANGED = Watcher.UI_SCALE_CHANGED

T.Events:RegisterEvent("UI_SCALE_CHANGED", Watcher)
T.Events:RegisterEvent("DISPLAY_SIZE_CHANGED", Watcher)
