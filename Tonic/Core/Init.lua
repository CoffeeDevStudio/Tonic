-- Tonic core bootstrap: creates the single global `Tonic`, registered in LibStub as "Tonic-1.0".
-- Tonic is never embedded: there must be exactly one ThemeManager and fixed media paths.

local ADDON_NAME = ...

local MAJOR, MINOR = "Tonic-1.0", 1

---@class Tonic
---@field name string
---@field version string
---@field mediaPath string
local T = LibStub:NewLibrary(MAJOR, MINOR)
if not T then return end

Tonic = T

T.name = ADDON_NAME
-- The packager replaces @project-version@; an unpackaged checkout shows "dev".
local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
T.version = (version and not version:find("^@")) and version or "dev"
T.mediaPath = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\"

-- Parent of every pooled frame while it is free.
T.hiddenParent = CreateFrame("Frame")
T.hiddenParent:Hide()

local PREFIX = "|cff86d1eaTonic|r:"

---Prints a message to the default chat frame with the Tonic prefix.
function T:Print(...)
	print(PREFIX, ...)
end

---Calls fn in protected mode, routing errors to the default error handler.
---@param fn function
---@return boolean ok
function T.SafeCall(fn, ...)
	return xpcall(fn, geterrorhandler(), ...)
end

-- Localization: English strings are the keys; locales override them.
local L = setmetatable({}, { __index = function(_, key) return key end })
T.L = L

---Registers translations for a locale. Only the active client locale is kept.
---@param locale string
---@param strings table<string, string>
function T:RegisterLocale(locale, strings)
	if locale ~= GetLocale() then return end
	for k, v in pairs(strings) do L[k] = v end
end
