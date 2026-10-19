-- Game menu (Escape): window surface and tonal buttons. Buttons are created by
-- GameMenuFrame:InitButtons on every open; skinning is idempotent.

local T = Tonic
local L = T.L
local H = T.SkinHelpers

T.Skins:Register("GameMenu", {
	label = L["Game menu"],
	order = 30,
	expects = { "GameMenuFrame", "GameMenuFrame.InitButtons" },
	apply = function()
		local frame = GameMenuFrame
		H.StripFrame(frame)
		H.Hide(frame.Header)
		H.Backdrop(frame, { usage = "window" })
		local header = frame.Header and (frame.Header.Text or frame.Header.TitleText)
		if header then H.SetFont(header, "headlineSmall", false, "onSurface") end
		local function skinButtons(menu)
			if not menu.buttonPool then return end
			for button in menu.buttonPool:EnumerateActive() do H.SkinButton(button, "tonal") end
		end
		hooksecurefunc(frame, "InitButtons", skinButtons)
		skinButtons(frame)
	end,
})
