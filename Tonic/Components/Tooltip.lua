-- M3 tooltips for Tonic components (GameTooltip is skinned separately).
--   plain: inverseSurface, shape XS, bodySmall, max 200 dp
--   rich:  surfaceContainer, shape ML 14, titleSmall + bodyMedium, max 312 dp
-- props.tooltip = "text" or { title = "...", text = "..." }

local T = Tonic

---@class TonicTooltip
local Tooltip = {}
T.Tooltip = Tooltip

local frame, title, body, owner

local function ensureFrames()
	if frame then return end
	frame = T.Surface:Acquire(UIParent, { color = "inverseSurface", shape = "xs" })
	frame:SetFrameStrata("TOOLTIP")
	frame:SetClampedToScreen(true)
	frame:Hide()
	title = T.Text:Acquire(frame, { role = "titleSmall", color = "onSurfaceVariant", wrap = true })
	body = T.Text:Acquire(frame, { role = "bodySmall", color = "inverseOnSurface", wrap = true })
end

---Shows the tooltip above a region.
---@param region Region
---@param content string|{ title: string?, text: string? }
function Tooltip:ShowFor(region, content)
	ensureFrames()
	owner = region
	local rich = type(content) == "table"
	local maxW = rich and 312 or 200
	local pad = rich and 16 or 8
	local text = rich and content.text or content
	frame:Update({ color = rich and "surfaceContainer" or "inverseSurface", shape = rich and "ml" or "xs" })
	local y = rich and 12 or 4
	title:SetShown(rich and content.title ~= nil)
	if rich and content.title then
		title:Update({ text = content.title, width = maxW - 2 * pad })
		title:ClearAllPoints()
		T.Scale:SetPoint(title, "TOPLEFT", frame, "TOPLEFT", pad, -y)
		y = y + title:GetStringHeight() / T.Scale.density + 4
	end
	body:Update({ text = text or "", role = rich and "bodyMedium" or "bodySmall",
		color = rich and "onSurfaceVariant" or "inverseOnSurface" })
	-- Shrink plain tooltips to their text.
	body:SetWidth(0)
	local natural = body:GetStringWidth() / T.Scale.density
	body:Update({ width = math.min(maxW - 2 * pad, natural + 1) })
	body:ClearAllPoints()
	T.Scale:SetPoint(body, "TOPLEFT", frame, "TOPLEFT", pad, -y)
	y = y + body:GetStringHeight() / T.Scale.density + (rich and 12 or 4)
	local width = math.min(maxW, math.max(rich and 120 or 0, body:GetWidth() / T.Scale.density + 2 * pad))
	frame:Update({ width = width, height = math.max(rich and 0 or 24, y) })
	frame:ClearAllPoints()
	T.Scale:SetPoint(frame, "BOTTOM", region, "TOP", 0, 4)
	frame:Show()
	frame:SetAlpha(0)
	T.Motion:Tween("short2", "standard", function(p) frame:SetAlpha(p) end)
end

---Hides the tooltip if it belongs to region.
---@param region Region
function Tooltip:HideFor(region)
	if frame and owner == region then
		frame:Hide()
		owner = nil
	end
end
