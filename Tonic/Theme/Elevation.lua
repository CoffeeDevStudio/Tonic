-- Elevation: tonal surface roles by usage, and pre-rendered shadow levels.
-- Shadows only on windows and menus; HUD panels stay flat.

local T = Tonic

---@class TonicShadow
---@field blur number dp
---@field y number dp, downwards
---@field alpha number

---@class TonicElevation
local Elevation = {
	tones = {
		lowest = "surfaceContainerLowest",
		low = "surfaceContainerLow",
		container = "surfaceContainer",
		high = "surfaceContainerHigh",
		highest = "surfaceContainerHighest",
	},
	-- What each kind of surface uses: tone, shape and shadow level.
	usage = {
		loading  = { tone = "lowest", shape = "none", shadow = 0 },
		window   = { tone = "low", shape = "xl", shadow = 3 },
		hud      = { tone = "container", shape = "l", shadow = 0, hud = true },
		menu     = { tone = "high", shape = "m", shadow = 2 },
		tooltip  = { tone = "high", shape = "ml", shadow = 0 },
		actionbar = { tone = "high", shape = "full", shadow = 0, hud = true },
		slot     = { tone = "highest", shape = "m", shadow = 0 },
		field    = { tone = "highest", shape = "xs", shadow = 0 },
		track    = { tone = "highest", shape = "full", shadow = 0 },
	},
	---@type table<integer, TonicShadow>
	shadows = {
		[1] = { blur = 3, y = 1, alpha = 0.30 },
		[2] = { blur = 6, y = 2, alpha = 0.34 },
		[3] = { blur = 10, y = 4, alpha = 0.38 },
		[4] = { blur = 14, y = 6, alpha = 0.42 },
		[5] = { blur = 18, y = 8, alpha = 0.46 },
	},
}
T.Elevation = Elevation

---@param usage string
---@return { tone: string, shape: string, shadow: integer, hud: boolean? }?
function Elevation:GetUsage(usage)
	return self.usage[usage]
end

---Scheme role of a tonal elevation name ("low") or of a usage ("window").
---@param name string
---@return string?
function Elevation:Role(name)
	local usage = self.usage[name]
	return self.tones[usage and usage.tone or name]
end

---@param level integer 0..5
---@return TonicShadow?
function Elevation:GetShadow(level)
	return self.shadows[level]
end
