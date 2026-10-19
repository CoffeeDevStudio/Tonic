-- Color schemes (from Palettes.generated.lua) and color math for M3 states.

local T = Tonic

---@alias TonicColor number[] { r, g, b } in 0..1

---@class TonicColorLib
local Color = {}
T.Color = Color

---@param hex string "RRGGBB" or "#RRGGBB"
---@return TonicColor
function Color.FromHex(hex)
	hex = hex:gsub("^#", "")
	return {
		tonumber(hex:sub(1, 2), 16) / 255,
		tonumber(hex:sub(3, 4), 16) / 255,
		tonumber(hex:sub(5, 6), 16) / 255,
	}
end

---@param c TonicColor
---@return string "RRGGBB"
function Color.ToHex(c)
	local floor = math.floor
	return ("%02X%02X%02X"):format(floor(c[1] * 255 + 0.5), floor(c[2] * 255 + 0.5), floor(c[3] * 255 + 0.5))
end

---Linear blend: base with overlay on top at opacity t (an M3 state layer).
---@param base TonicColor
---@param overlay TonicColor
---@param t number 0..1
---@return TonicColor
function Color.Mix(base, overlay, t)
	return {
		base[1] + (overlay[1] - base[1]) * t,
		base[2] + (overlay[2] - base[2]) * t,
		base[3] + (overlay[3] - base[3]) * t,
	}
end

-- M3 state layer opacities.
Color.STATE = {
	hover = 0.08,
	focus = 0.10,
	pressed = 0.10,
	disabledContainer = 0.12,
	disabledContent = 0.38,
}

---@class TonicScheme
local Scheme = {
	DEFAULT_SEED = "DEFAULT",
}
T.Scheme = Scheme

---@param seed string classFile or "DEFAULT"
---@return boolean
function Scheme:HasSeed(seed)
	return T.Palettes.seeds[seed] ~= nil
end

---@return string[]
function Scheme:GetSeeds()
	return T.Palettes.order
end

---Returns the generated palette for a seed and mode, falling back to DEFAULT.
---@param seed string
---@param mode "dark"|"light"
---@return { roles: table<string, TonicColor>, semantic: table<string, table<string, TonicColor>> }
function Scheme:Get(seed, mode)
	local palette = T.Palettes.seeds[seed] or T.Palettes.seeds[self.DEFAULT_SEED]
	return palette[mode] or palette.dark
end

---@param seed string
---@return string "RRGGBB"
function Scheme:GetSeedHex(seed)
	local palette = T.Palettes.seeds[seed] or T.Palettes.seeds[self.DEFAULT_SEED]
	return palette.seed
end
