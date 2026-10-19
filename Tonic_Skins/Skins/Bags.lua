-- Bags: combined and individual containers, item buttons with quality containers,
-- search box, money in tabular digits.

local T = Tonic
local L = T.L
local H = T.SkinHelpers

local function updateItems(frame)
	if not frame.EnumerateValidItems then return end
	for _, button in frame:EnumerateValidItems() do
		H.SkinItemButton(button)
		local info = C_Container.GetContainerItemInfo(button:GetBagID(), button:GetID())
		H.SetItemQuality(button, info and info.quality)
	end
end

local function skinContainer(frame)
	if not frame then return end
	H.StripFrame(frame)
	H.Backdrop(frame, { usage = "window", shape = "l" })
	H.SkinCloseButton(frame.CloseButton)
	local name = frame.GetName and frame:GetName()
	H.SetFont(frame.TitleContainer and frame.TitleContainer.TitleText or (name and _G[name .. "Name"]),
		"titleMedium", false, "onSurface")
	if frame.UpdateItems then hooksecurefunc(frame, "UpdateItems", updateItems) end
	updateItems(frame)
end

T.Skins:Register("Bags", {
	label = L["Bags"],
	order = 20,
	expects = { "ContainerFrameCombinedBags", "ContainerFrame1", "BagItemSearchBox" },
	apply = function()
		skinContainer(ContainerFrameCombinedBags)
		for i = 1, (NUM_CONTAINER_FRAMES or 13) do skinContainer(_G["ContainerFrame" .. i]) end
		H.SkinEditBox(BagItemSearchBox)
		local money = ContainerFrameCombinedBags and ContainerFrameCombinedBags.MoneyFrame
		if money then
			for _, key in ipairs({ "GoldButton", "SilverButton", "CopperButton" }) do
				local coin = money[key]
				if coin and coin.Text then H.SetFont(coin.Text, "labelLarge", true, "onSurface") end
			end
		end
	end,
})
