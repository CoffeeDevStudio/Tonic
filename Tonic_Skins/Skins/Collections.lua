-- Collections journal (Blizzard_Collections, load on demand): window, tabs, insets,
-- search boxes.

local T = Tonic
local L = T.L
local H = T.SkinHelpers

T.Skins:Register("Collections", {
	label = L["Collections"],
	order = 40,
	addon = "Blizzard_Collections",
	expects = { "CollectionsJournal", "MountJournal", "PetJournal", "ToyBox", "HeirloomsJournal" },
	apply = function()
		local frame = CollectionsJournal
		H.StripFrame(frame)
		H.Backdrop(frame, { usage = "window" })
		H.SkinCloseButton(CollectionsJournalCloseButton or frame.CloseButton)
		local title = frame.TitleContainer and frame.TitleContainer.TitleText
		H.SetFont(title, "titleLarge", false, "onSurface")
		for i = 1, 8 do H.SkinTab(_G["CollectionsJournalTab" .. i]) end
		if frame.Tabs then
			for _, tab in ipairs(frame.Tabs) do H.SkinTab(tab) end
		end

		local insets = {
			MountJournal and MountJournal.LeftInset, MountJournal and MountJournal.RightInset,
			MountJournal and MountJournal.BottomLeftInset,
			PetJournal and PetJournal.LeftInset, PetJournal and PetJournal.RightInset,
			ToyBox and ToyBox.iconsFrame, HeirloomsJournal and HeirloomsJournal.iconsFrame,
		}
		for _, inset in pairs(insets) do
			H.StripFrame(inset)
			H.Backdrop(inset, { usage = "hud", opacity = 1, shape = "l" })
		end
		for _, box in ipairs({ MountJournalSearchBox, PetJournalSearchBox,
			ToyBox and ToyBox.searchBox, HeirloomsJournalSearchBox }) do
			H.SkinEditBox(box)
		end
	end,
})
