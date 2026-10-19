-- Character window: window surface, tabs, close button, item slots with quality
-- containers, item level in Roboto Serif.

local T = Tonic
local L = T.L
local H = T.SkinHelpers

local SLOTS = {
	"CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot", "CharacterBackSlot",
	"CharacterChestSlot", "CharacterShirtSlot", "CharacterTabardSlot", "CharacterWristSlot",
	"CharacterHandsSlot", "CharacterWaistSlot", "CharacterLegsSlot", "CharacterFeetSlot",
	"CharacterFinger0Slot", "CharacterFinger1Slot", "CharacterTrinket0Slot", "CharacterTrinket1Slot",
	"CharacterMainHandSlot", "CharacterSecondaryHandSlot",
}

T.Skins:Register("Character", {
	label = L["Character"],
	order = 10,
	expects = { "CharacterFrame", "CharacterFrameTab1", "CharacterHeadSlot", "PaperDollItemSlotButton_Update" },
	apply = function()
		local frame = CharacterFrame
		H.StripFrame(frame)
		H.StripFrame(CharacterFrameInset)
		H.StripFrame(CharacterFrameInsetRight)
		H.Backdrop(frame, { usage = "window" })
		H.Backdrop(CharacterFrameInset, { usage = "hud", opacity = 1, shape = "l" }, 2)
		H.SkinCloseButton(CharacterFrameCloseButton or frame.CloseButton)
		local title = frame.TitleContainer and frame.TitleContainer.TitleText or CharacterFrameTitleText
		H.SetFont(title, "titleLarge", false, "onSurface")
		for i = 1, 4 do H.SkinTab(_G["CharacterFrameTab" .. i]) end

		for _, name in ipairs(SLOTS) do
			local slot = _G[name]
			if slot then
				H.SkinItemButton(slot)
				H.SetItemQuality(slot, GetInventoryItemQuality("player", slot:GetID()))
			end
		end
		hooksecurefunc("PaperDollItemSlotButton_Update", function(button)
			H.SetItemQuality(button, GetInventoryItemQuality("player", button:GetID()))
		end)

		-- Item level: Display/Headline in Roboto Serif with tabular digits.
		local ilvl = CharacterStatsPane and CharacterStatsPane.ItemLevelFrame
		if ilvl and ilvl.Value then H.SetFont(ilvl.Value, "headlineMedium", true, "primary") end
		if CharacterStatsPane then
			H.Hide(CharacterStatsPane.ClassBackground)
			for _, key in ipairs({ "ItemLevelCategory", "AttributesCategory", "EnhancementsCategory" }) do
				local category = CharacterStatsPane[key]
				if category then
					H.StripTextures(category)
					H.SetFont(category.Title, "titleSmall", false, "primary")
				end
			end
		end
	end,
})
