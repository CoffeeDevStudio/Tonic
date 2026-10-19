-- Unit frames (player, target, focus, pet): flat bars in the semantic colors, HUD panel,
-- tabular digits. Secret values: health and power are never read; Blizzard keeps
-- passing them to StatusBar:SetValue and SetText, we only set textures, colors, fonts.

local T = Tonic
local L = T.L
local H = T.SkinHelpers

local POWER_TOKENS = { MANA = "mana", RAGE = "rage", ENERGY = "energy", FOCUS = "energy" }

local function powerColor(bar)
	local unit = bar.unit
	if not unit then return "primary" end
	local _, token = UnitPowerType(unit)
	return (POWER_TOKENS[token] or "mana") .. ".bar"
end

local function healthColor()
	return "health.bar"
end

local FRAMES = {
	{
		root = "PlayerFrame",
		content = "PlayerFrame.PlayerFrameContent.PlayerFrameContentMain",
		health = "PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar",
		power = "PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar",
		art = "PlayerFrame.PlayerFrameContainer.FrameTexture",
	},
	{
		root = "TargetFrame",
		content = "TargetFrame.TargetFrameContent.TargetFrameContentMain",
		health = "TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar",
		power = "TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar",
		art = "TargetFrame.TargetFrameContainer.FrameTexture",
	},
	{
		root = "FocusFrame",
		content = "FocusFrame.TargetFrameContent.TargetFrameContentMain",
		health = "FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar",
		power = "FocusFrame.TargetFrameContent.TargetFrameContentMain.ManaBar",
		art = "FocusFrame.TargetFrameContainer.FrameTexture",
	},
	{ root = "PetFrame", health = "PetFrameHealthBar", power = "PetFrameManaBar", art = "PetFrameTexture" },
}

local function skinBarTexts(bar)
	for _, key in ipairs({ "TextString", "LeftText", "RightText" }) do
		if bar[key] then H.SetFont(bar[key], "labelMedium", true) end
	end
end

T.Skins:Register("UnitFrames", {
	label = L["Unit frames"],
	order = 80,
	expects = { "PlayerFrame", "TargetFrame", "FocusFrame",
		"PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar" },
	apply = function()
		local resolve = T.Skins.Resolve
		for _, def in ipairs(FRAMES) do
			local health = resolve(def.health)
			local power = def.power and resolve(def.power)
			if health then
				H.SkinStatusBar(health, healthColor)
				skinBarTexts(health)
			end
			if power then
				H.SkinStatusBar(power, powerColor)
				skinBarTexts(power)
			end
			local art = def.art and resolve(def.art)
			if art then H.Hide(art) end
			-- HUD panel around the bars.
			local container = health and (health:GetParent() or health)
			if container and power then
				local panel = H.Backdrop(container, { usage = "hud" }, -6)
				if panel then
					panel:ClearAllPoints()
					panel:SetPoint("TOPLEFT", health, "TOPLEFT", -T.Scale:Dp(6, health), T.Scale:Dp(6, health))
					panel:SetPoint("BOTTOMRIGHT", power, "BOTTOMRIGHT", T.Scale:Dp(6, power), -T.Scale:Dp(6, power))
				end
			end
		end
		local name = T.Skins.Resolve("TargetFrame.TargetFrameContent.TargetFrameContentMain.Name")
		H.SetFont(name, "labelLarge", false, "onSurface")
	end,
})
