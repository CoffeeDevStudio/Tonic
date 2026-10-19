-- /tonic slash command. SLASH_TONIC1 is the global Blizzard's slash system requires.

local T = Tonic
local L = T.L

local commands = {}

local function usage()
	T:Print(L["Commands:"])
	print("  /tonic gallery  - " .. L["show every token and primitive (dark and light)"])
	print("  /tonic mode dark|light|toggle  - " .. L["color mode"])
	print("  /tonic seed <CLASS>|auto  - " .. L["seed color (auto = your class)"])
	print("  /tonic opacity 0.60-1.00  - " .. L["HUD panel opacity"])
	print("  /tonic version")
end

function commands.gallery()
	T:GetModule("Gallery"):Toggle()
end

function commands.mode(arg)
	local current = T.db.profile.theme.mode
	if arg == "toggle" or arg == "" then arg = current == "dark" and "light" or "dark" end
	if arg ~= "dark" and arg ~= "light" then return usage() end
	T.Theme:SetMode(arg)
	T:Print(L["Mode:"], arg)
end

function commands.seed(arg)
	local seed = arg:upper()
	if seed == "AUTO" or seed == "" then
		T.Theme:SetSeed("auto")
	elseif T.Scheme:HasSeed(seed) then
		T.Theme:SetSeed(seed)
	else
		T:Print(L["Unknown seed. Available:"], table.concat(T.Scheme:GetSeeds(), ", "))
		return
	end
	T:Print(L["Seed:"], T.Theme:GetSeed())
end

function commands.opacity(arg)
	local value = tonumber((arg:gsub(",", ".")))
	if not value then return usage() end
	T.Theme:SetHudOpacity(value)
	T:Print(L["HUD opacity:"], ("%.2f"):format(T.db.profile.theme.hudOpacity))
end

function commands.version()
	T:Print(T.version)
end

SLASH_TONIC1 = "/tonic"
SlashCmdList.TONIC = function(input)
	local command, arg = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
	local handler = commands[command:lower()]
	if handler then handler(arg) else usage() end
end
