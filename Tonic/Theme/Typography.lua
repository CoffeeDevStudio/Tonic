-- M3 type scale as shared Font objects (one font family per role).
-- Roboto Serif: Display, Headline. Roboto Flex: Title, Body, Label.
-- One file per weight; koKR/zhCN/zhTW fall back to the Blizzard fonts via CreateFontFamily.
-- Fonts are created once: a density change needs /reload.

local T = Tonic

---@class TonicTypography
local Typography = {}
T.Typography = Typography

local FONT_DIR = T.mediaPath .. "Fonts\\"

-- Files expected in Media/Fonts. "*-Tnum" are static instances with tabular digits
-- frozen in (WoW cannot enable OpenType features); missing files fall back.
local FILES = {
	serif = { regular = "RobotoSerif-Regular.ttf", semibold = "RobotoSerif-SemiBold.ttf" },
	flex = { regular = "RobotoFlex-Regular.ttf", medium = "RobotoFlex-Medium.ttf" },
	flexTnum = { regular = "RobotoFlex-Regular-Tnum.ttf", medium = "RobotoFlex-Medium-Tnum.ttf" },
}

-- Role: family, weight, size (sp ~ dp), line height.
Typography.roles = {
	displayLarge   = { "serif", "regular", 57, 64 },
	displayMedium  = { "serif", "regular", 45, 52 },
	displaySmall   = { "serif", "regular", 36, 44 },
	headlineLarge  = { "serif", "regular", 32, 40 },
	headlineMedium = { "serif", "regular", 28, 36 },
	headlineSmall  = { "serif", "regular", 24, 32 },
	titleLarge     = { "flex", "regular", 22, 28 },
	titleMedium    = { "flex", "medium", 16, 24 },
	titleSmall     = { "flex", "medium", 14, 20 },
	bodyLarge      = { "flex", "regular", 16, 24 },
	bodyMedium     = { "flex", "regular", 14, 20 },
	bodySmall      = { "flex", "regular", 12, 16 },
	labelLarge     = { "flex", "medium", 14, 20 },
	labelMedium    = { "flex", "medium", 12, 16 },
	labelSmall     = { "flex", "medium", 11, 16 },
}

Typography.order = {
	"displayLarge", "displayMedium", "displaySmall",
	"headlineLarge", "headlineMedium", "headlineSmall",
	"titleLarge", "titleMedium", "titleSmall",
	"bodyLarge", "bodyMedium", "bodySmall",
	"labelLarge", "labelMedium", "labelSmall",
}

-- Blizzard fonts per alphabet, used when a Tonic file is missing and for CJK.
local FALLBACK = {
	roman = "Fonts\\FRIZQT__.TTF",
	russian = "Fonts\\FRIZQT___CYR.TTF",
	korean = "Fonts\\2002.TTF",
	simplifiedchinese = "Fonts\\ARKai_T.ttf",
	traditionalchinese = "Fonts\\blei00d.TTF",
}

local fonts = {}       ---@type table<string, Font>
local available = {}   ---@type table<string, string|false>
local probe

local function normalize(path)
	return (path or ""):lower():gsub("/", "\\")
end

-- Returns path if WoW can load it, nil otherwise.
local function loadable(path)
	if available[path] == nil then
		probe = probe or CreateFont("TonicFontProbe")
		probe:SetFont(FALLBACK.roman, 12, "")
		local ok = probe:SetFont(path, 12, "")
		available[path] = (ok ~= false and normalize(probe:GetFont()) == normalize(path)) and path or false
	end
	return available[path] or nil
end

local function resolveFile(family, weight, numeric)
	if numeric and FILES.flexTnum[weight] and family == "flex" then
		local tnum = loadable(FONT_DIR .. FILES.flexTnum[weight])
		if tnum then return tnum end
	end
	local file = FILES[family][weight]
	return file and loadable(FONT_DIR .. file) or nil
end

local function build(role, numeric)
	local spec = assert(Typography.roles[role], "Unknown type role: " .. tostring(role))
	local family, weight, size = spec[1], spec[2], spec[3]
	local height = size * T.Scale.density
	local file = resolveFile(family, weight, numeric)
	local name = "TonicFont_" .. role .. (numeric and "_tnum" or "")
	local members = {}
	for alphabet, fallback in pairs(FALLBACK) do
		-- Roboto covers Latin and Cyrillic; CJK always uses Blizzard fonts.
		local useTonic = file and (alphabet == "roman" or alphabet == "russian")
		members[#members + 1] = { alphabet = alphabet, file = useTonic and file or fallback, height = height, flags = "" }
	end
	local font = CreateFontFamily(name, members)
	font:SetJustifyH("LEFT")
	return font
end

---Returns the shared Font object of a role.
---@param role string
---@param numeric? boolean tabular digits (values, counters)
---@return Font
function Typography:Get(role, numeric)
	local key = numeric and role .. "_tnum" or role
	local font = fonts[key]
	if not font then
		font = build(role, numeric)
		fonts[key] = font
	end
	return font
end

---Line height in dp of a role.
---@param role string
---@return number
function Typography:LineHeight(role)
	return self.roles[role][4]
end

---Font size in dp of a role.
---@param role string
---@return number
function Typography:Size(role)
	return self.roles[role][3]
end

---True when the Tonic font files are installed (otherwise Blizzard fonts are used).
---@return boolean
function Typography:HasTonicFonts()
	return loadable(FONT_DIR .. FILES.flex.regular) ~= nil
end
