-- /tonic slash command. SLASH_TONIC1 is the global Blizzard's slash system requires.

local T = Tonic
local L = T.L

local commands = {}

local function usage()
	T:Print(L["Commands:"])
	print("  /tonic config  - " .. L["options"])
	print("  /tonic gallery  - " .. L["show every token and primitive (dark and light)"])
	print("  /tonic audit  - " .. L["check the skins against the current patch"])
	print("  /tonic mode dark|light|toggle  - " .. L["color mode"])
	print("  /tonic seed <CLASS>|auto  - " .. L["seed color (auto = your class)"])
	print("  /tonic opacity 0.60-1.00  - " .. L["HUD panel opacity"])
	print("  /tonic version")
end

function commands.config()
	T:OpenConfig()
end
commands.options = commands.config

function commands.gallery()
	T:GetModule("Gallery"):Toggle()
end

function commands.audit()
	local report = T.Skins:Audit()
	if #report == 0 then
		T:Print(L["No skins registered (is Tonic_Skins enabled?)."])
		return
	end
	local problems = 0
	for _, entry in ipairs(report) do
		local line = ("  %s: %s"):format(entry.name, L[entry.status])
		if #entry.missing > 0 then
			line = line .. "  |cffffb4ab" .. L["missing:"] .. " " .. table.concat(entry.missing, ", ") .. "|r"
		end
		if entry.status == "error" or #entry.missing > 0 then problems = problems + 1 end
		print(line)
		if entry.error then print("    |cffffb4ab" .. entry.error .. "|r") end
	end
	T:Print(problems == 0 and L["Audit: everything in place."] or (L["Audit: skins to check:"] .. " " .. problems))
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
	if command == "" then return T:OpenConfig() end
	local handler = commands[command:lower()]
	if handler then handler(arg) else usage() end
end
