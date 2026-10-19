std = "lua51"
max_line_length = 140
self = false
unused_args = false

exclude_files = {
	"Tonic/Libs/",
	"Tonic/Theme/Palettes.generated.lua",
	"tools/tokens/node_modules/",
	".luarocks/",
	".lua/",
}

globals = {
	"Tonic",
	"TonicDB",
	"TonicCharDB",
	"SLASH_TONIC1",
	"SlashCmdList",
}

read_globals = {
	"LibStub",
	"C_AddOns",
	"CreateFont",
	"CreateFontFamily",
	"CreateFrame",
	"CreateFromMixins",
	"GetLocale",
	"GetPhysicalScreenSize",
	"GetRealmName",
	"InCombatLockdown",
	"LOCALIZED_CLASS_NAMES_MALE",
	"Mixin",
	"UIParent",
	"UnitClass",
	"UnitName",
	"geterrorhandler",
	"strmatch",
	"unpack",
	"wipe",
}

files["spec/"] = {
	std = "+busted",
	globals = { "_G", "unpack" },
	read_globals = { "CreateFrame", "SlashCmdList", "TonicDB" },
}
