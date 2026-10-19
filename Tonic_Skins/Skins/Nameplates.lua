-- Nameplates: flat health bar (health for friends, hostile for enemies), pill track,
-- Tonic font on names. Forbidden plates (instances) are left alone. Health values
-- are never read: Blizzard sets them, we only color.

local T = Tonic
local L = T.L
local H = T.SkinHelpers

local skinned = setmetatable({}, { __mode = "k" })

local function plateColor(bar)
	local frame = bar:GetParent()
	local unit = frame and frame.unit
	if unit and UnitCanAttack("player", unit) then return "hostile.bar" end
	return "health.bar"
end

local function skinPlate(unit)
	local plate = C_NamePlate.GetNamePlateForUnit(unit, issecure())
	if not plate or (plate.IsForbidden and plate:IsForbidden()) then return end
	local frame = plate.UnitFrame
	if not frame or (frame.IsForbidden and frame:IsForbidden()) or not frame.healthBar then return end
	if not skinned[frame] then
		skinned[frame] = true
		local bar = frame.healthBar
		H.Hide(bar.border)
		H.Backdrop(bar, { usage = "track", opacity = "hud" }, -1)
		if frame.name then H.SetFont(frame.name, "labelMedium") end
		H.SkinStatusBar(bar, plateColor)
	else
		-- Reused plate, new unit: the color depends on the unit.
		local bar = frame.healthBar
		local r, g, b = T.Theme:GetTheme():RGB(plateColor(bar))
		bar:SetStatusBarColor(r, g, b)
	end
end

T.Skins:Register("Nameplates", {
	label = L["Nameplates"],
	order = 90,
	expects = { "NamePlateDriverFrame", "C_NamePlate.GetNamePlateForUnit" },
	apply = function()
		local watcher = {}
		function watcher:NAME_PLATE_UNIT_ADDED(_, unit) skinPlate(unit) end
		T.Events:RegisterEvent("NAME_PLATE_UNIT_ADDED", watcher)
		for _, plate in ipairs(C_NamePlate.GetNamePlates(issecure())) do
			if plate.namePlateUnitToken then skinPlate(plate.namePlateUnitToken) end
		end
	end,
})
