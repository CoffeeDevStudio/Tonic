std = "lua51"
max_line_length = 140
-- Long strings (translations, descriptions) are fine.
max_string_line_length = false
self = false
unused_args = false
-- Shadowing an upvalue is common in UI callbacks (self, close...); empty branches are intentional.
ignore = { "431", "432", "542" }

exclude_files = {
	"Tonic/Libs/",
	"Tonic/Theme/Palettes.generated.lua",
	"tools/tokens/node_modules/",
	".luarocks/",
	".lua/",
}

-- The only globals Tonic writes.
globals = {
	"Tonic",
	"TonicDB",
	"TonicCharDB",
	"SLASH_TONIC1",
	"SlashCmdList",
}

read_globals = {
	-- Libraries and Lua extensions of WoW
	"LibStub", "strmatch", "unpack", "wipe", "geterrorhandler", "hooksecurefunc", "issecure",
	-- API
	"C_AddOns", "C_Container", "C_Item", "C_NamePlate", "C_Timer", "Enum", "Settings",
	"CreateDataProvider", "CreateFont", "CreateFontFamily", "CreateFrame", "CreateFromMixins",
	"CreateScrollBoxListLinearView", "Mixin", "ScrollUtil",
	"GetCursorPosition", "GetInventoryItemQuality", "GetLocale", "GetPhysicalScreenSize", "GetRealmName",
	"InCombatLockdown", "ReloadUI", "UnitCanAttack", "UnitClass", "UnitName", "UnitPowerType",
	"LOCALIZED_CLASS_NAMES_MALE", "NUM_CHAT_WINDOWS", "NUM_CONTAINER_FRAMES", "OKAY", "UIDROPDOWNMENU_MAXLEVELS",
	-- Blizzard frames and functions hooked or skinned
	"AddonCompartmentFrame", "Minimap", "UIParent",
	"BagItemSearchBox", "ContainerFrameCombinedBags",
	"CharacterFrame", "CharacterFrameCloseButton", "CharacterFrameInset", "CharacterFrameInsetRight",
	"CharacterFrameTitleText", "CharacterStatsPane",
	"CollectionsJournal", "CollectionsJournalCloseButton", "HeirloomsJournal", "HeirloomsJournalSearchBox",
	"MountJournal", "MountJournalSearchBox", "PetJournal", "PetJournalSearchBox", "ToyBox",
	"GameMenuFrame", "GameTooltipStatusBar", "Menu", "MenuStyle1Mixin", "WowStyle1MenuMixin",
	"TooltipDataProcessor", "SharedTooltip_SetBackdropStyle",
	"FCFTab_UpdateColors", "FCF_OpenTemporaryWindow",
	"PanelTemplates_DeselectTab", "PanelTemplates_SelectTab",
}

files["spec/"] = {
	std = "+busted",
	globals = { "_G", "unpack", "C_AddOns" },
	read_globals = { "CreateFrame", "SlashCmdList", "TonicDB" },
}
