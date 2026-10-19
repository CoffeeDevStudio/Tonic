-- Chat: HUD panel behind each chat window (opacity from the options), field-style edit
-- box, tabs with M3 labels. Messages and channel colors are untouched.

local T = Tonic
local L = T.L
local H = T.SkinHelpers

local BG_SUFFIXES = { "Background", "TopLeftTexture", "TopRightTexture", "BottomLeftTexture", "BottomRightTexture",
	"TopTexture", "BottomTexture", "LeftTexture", "RightTexture" }
local TAB_SUFFIXES = { "Left", "Middle", "Right", "SelectedLeft", "SelectedMiddle", "SelectedRight",
	"HighlightLeft", "HighlightMiddle", "HighlightRight", "ActiveLeft", "ActiveMiddle", "ActiveRight" }
local EDIT_SUFFIXES = { "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }

local skinned = {}

local function skinWindow(index)
	local name = "ChatFrame" .. index
	local frame = _G[name]
	if not frame or skinned[frame] then return end
	skinned[frame] = true
	-- The floating-frame textures get their alpha reset by FCF: clear the files instead.
	for _, suffix in ipairs(BG_SUFFIXES) do
		local tex = _G[name .. suffix]
		if tex then tex:SetTexture(nil) end
	end
	H.Backdrop(frame, { usage = "hud" }, -6)

	local tab = _G[name .. "Tab"]
	if tab then
		for _, suffix in ipairs(TAB_SUFFIXES) do H.Hide(_G[name .. "Tab" .. suffix] or tab[suffix]) end
		H.SetFont(H.Child(tab, "Text") or _G[name .. "TabText"], "labelLarge", false, "onSurfaceVariant")
	end

	local edit = _G[name .. "EditBox"]
	if edit then
		for _, suffix in ipairs(EDIT_SUFFIXES) do H.Hide(_G[name .. "EditBox" .. suffix]) end
		H.Backdrop(edit, { usage = "field", shape = "full" }, 2)
		H.SetFont(H.Child(edit, "header") or _G[name .. "EditBoxHeader"], "labelLarge", false, "primary")
	end
	H.StripTextures(_G[name .. "ButtonFrame"])
end

T.Skins:Register("Chat", {
	label = L["Chat"],
	order = 70,
	expects = { "ChatFrame1", "ChatFrame1Tab", "ChatFrame1EditBox", "FCF_OpenTemporaryWindow" },
	apply = function()
		for i = 1, (NUM_CHAT_WINDOWS or 10) do skinWindow(i) end
		if FCF_OpenTemporaryWindow then
			hooksecurefunc("FCF_OpenTemporaryWindow", function()
				for i = 1, (NUM_CHAT_WINDOWS or 10) + 10 do skinWindow(i) end
			end)
		end
		if FCFTab_UpdateColors then
			hooksecurefunc("FCFTab_UpdateColors", function(tab, selected)
				local fs = H.Child(tab, "Text") or (tab.GetName and _G[tab:GetName() .. "Text"])
				if fs then H.ColorText(fs, selected and "primary" or "onSurfaceVariant") end
			end)
		end
	end,
})
