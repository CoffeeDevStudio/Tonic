-- GameTooltip and friends: rich-tooltip surface (shape ML), item name in the quality
-- tone 80, flat health bar. Only colors and textures are set; values stay Blizzard's.

local T = Tonic
local L = T.L
local H = T.SkinHelpers

local TOOLTIPS = { "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
	"ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2", "EmbeddedItemTooltip" }

local skinned = setmetatable({}, { __mode = "k" })

local function skin(tooltip)
	if not tooltip or skinned[tooltip] or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
	skinned[tooltip] = true
	H.Hide(tooltip.NineSlice)
	H.Backdrop(tooltip, { usage = "tooltip", outline = "outlineVariant" })
end

T.Skins:Register("Tooltip", {
	label = L["Tooltips"],
	order = 50,
	expects = { "GameTooltip", "GameTooltipStatusBar", "TooltipDataProcessor", "SharedTooltip_SetBackdropStyle" },
	apply = function()
		for _, name in ipairs(TOOLTIPS) do skin(_G[name]) end
		-- Blizzard restores the NineSlice style on every SetOwner.
		if SharedTooltip_SetBackdropStyle then
			hooksecurefunc("SharedTooltip_SetBackdropStyle", function(tooltip)
				if skinned[tooltip] then H.Hide(tooltip.NineSlice) end
			end)
		end
		H.SkinStatusBar(GameTooltipStatusBar, function() return "health.bar" end)

		if TooltipDataProcessor and Enum.TooltipDataType then
			TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
				if not skinned[tooltip] or not data or not data.id then return end
				local quality = C_Item.GetItemQualityByID(data.id)
				local backdrop = H.GetBackdrop(tooltip)
				local token = H.QualityToken(quality)
				local name = tooltip.GetName and tooltip:GetName()
				local line = name and _G[name .. "TextLeft1"]
				local theme = T.Theme:GetTheme()
				if line and quality and quality >= 2 then line:SetTextColor(theme:RGB(token .. ".color")) end
				if backdrop then
					backdrop:Update({ outline = quality == 5 and (token .. ".color") or "outlineVariant" })
				end
			end)
		end
	end,
})
