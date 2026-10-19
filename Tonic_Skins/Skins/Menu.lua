-- Blizzard menus: the Blizzard_Menu system (context menus, dropdowns) and the legacy
-- UIDropDownMenu lists still used by some addons. Menu surface: shape M, shadow 2.

local T = Tonic
local L = T.L
local H = T.SkinHelpers

local function skinMenuFrame(menu)
	if not menu or (menu.IsForbidden and menu:IsForbidden()) then return end
	if menu.Background then H.Hide(menu.Background) end
	H.StripTextures(menu)
	H.Backdrop(menu, { usage = "menu" })
end

T.Skins:Register("Menu", {
	label = L["Menus"],
	order = 60,
	expects = { "Menu.GetManager" },
	apply = function()
		-- Style mixin of the modern menus: hook before menus are created.
		local style = WowStyle1MenuMixin or MenuStyle1Mixin
		if style and style.Generate then
			hooksecurefunc(style, "Generate", function(self) skinMenuFrame(self) end)
		end
		local manager = Menu and Menu.GetManager and Menu.GetManager()
		if manager then
			local function onOpen(mgr)
				local open = mgr.GetOpenMenu and mgr:GetOpenMenu()
				if open then skinMenuFrame(open) end
			end
			if manager.OpenMenu then hooksecurefunc(manager, "OpenMenu", onOpen) end
			if manager.OpenContextMenu then hooksecurefunc(manager, "OpenContextMenu", onOpen) end
		end
		for i = 1, (UIDROPDOWNMENU_MAXLEVELS or 3) do
			local list = _G["DropDownList" .. i]
			if list then
				H.Hide(_G["DropDownList" .. i .. "Backdrop"])
				H.Hide(_G["DropDownList" .. i .. "MenuBackdrop"])
				H.Backdrop(list, { usage = "menu" })
			end
		end
	end,
})
