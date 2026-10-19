local wow = require("spec.helpers.wow")

-- Fake Blizzard frames, enough for the skins to run their code paths.
local function fakeBlizzard()
	local F = function(kind) return wow.NewRegion(kind or "Frame") end
	_G.CharacterFrame = F()
	_G.CharacterFrameTab1 = F("Button")
	_G.CharacterHeadSlot = F("Button")
	_G.CharacterHeadSlot.IconBorder = wow.NewRegion("Texture")
	_G.PaperDollItemSlotButton_Update = function() end

	local menu = F()
	menu.buttonPool = F()
	menu.buttonPool._active = { [F("Button")] = true }
	menu.InitButtons = function() end
	_G.GameMenuFrame = menu

	_G.GameTooltip = F("GameTooltip")
	_G.GameTooltip.NineSlice = F()
	_G.GameTooltipStatusBar = F("StatusBar")
	_G.TooltipDataProcessor = { AddTooltipPostCall = function() end }
	_G.SharedTooltip_SetBackdropStyle = function() end
	_G.Enum = { TooltipDataType = { Item = 0 } }

	_G.ChatFrame1 = F()
	_G.ChatFrame1Tab = F("Button")
	_G.ChatFrame1EditBox = F("EditBox")
	_G.FCF_OpenTemporaryWindow = function() end
end

describe("Skins", function()
	it("register, apply in isolation and audit", function()
		local T = wow.LoadAddon({ before = fakeBlizzard })
		local report = T.Skins:Audit()
		local status = {}
		for _, entry in ipairs(report) do status[entry.name] = entry.status end
		assert.are.equal("ok", status.Character)
		assert.are.equal("ok", status.GameMenu)
		assert.are.equal("ok", status.Tooltip)
		assert.are.equal("ok", status.Chat)
		-- Frames that do not exist are reported, not run into errors.
		assert.are.equal("missing", status.Bags)
		assert.are.equal("waiting", status.Collections)
		assert.are.same({}, wow.errors)
	end)

	it("applies waiting skins when their Blizzard addon loads", function()
		local T = wow.LoadAddon({ before = fakeBlizzard })
		_G.CollectionsJournal = wow.NewRegion("Frame")
		_G.MountJournal, _G.PetJournal = wow.NewRegion("Frame"), wow.NewRegion("Frame")
		_G.ToyBox, _G.HeirloomsJournal = wow.NewRegion("Frame"), wow.NewRegion("Frame")
		local isLoaded = C_AddOns.IsAddOnLoaded
		C_AddOns.IsAddOnLoaded = function(name) return name == "Blizzard_Collections" or isLoaded(name) end
		wow.Fire("ADDON_LOADED", "Blizzard_Collections")
		assert.are.equal("ok", T.Skins.registry.Collections.status)
	end)

	it("keeps a skin off when disabled in the profile", function()
		local T = wow.LoadAddon({ before = fakeBlizzard, login = false })
		T.Skins:SetEnabled("Chat", false)
		wow.Fire("PLAYER_LOGIN")
		assert.are.equal("disabled", T.Skins.registry.Chat.status)
	end)

	it("isolates a failing skin", function()
		local T = wow.LoadAddon({ before = fakeBlizzard })
		T.Skins:Register("Broken", { apply = function() error("boom") end })
		assert.are.equal("error", T.Skins.registry.Broken.status)
		assert.are.equal(1, #wow.errors)
	end)

	it("maps item qualities to semantic tokens", function()
		local T = wow.LoadAddon()
		local H = T.SkinHelpers
		assert.are.equal("qualityCommon", H.QualityToken(0))
		assert.are.equal("qualityEpic", H.QualityToken(4))
		assert.are.equal("qualityLegendary", H.QualityToken(5))
		assert.are.equal("qualityCommon", H.QualityToken(nil))
	end)
end)
