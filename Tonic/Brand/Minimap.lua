-- Minimap button (32 dp two-band logo on a circular surface) and the addon compartment
-- entry. Left click: options. Right click: gallery. Drag: move around the minimap.

local T = Tonic
local L = T.L

T.DB:AddDefaults("global", { minimap = { hide = false, angle = 225 } })

local module = T:NewModule("Minimap")
local button

local function place()
	local angle = math.rad(T.db.global.minimap.angle)
	local radius = (Minimap:GetWidth() / 2) + T.Scale:Dp(10, Minimap)
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function onDragUpdate()
	local mx, my = Minimap:GetCenter()
	local x, y = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	T.db.global.minimap.angle = math.deg(math.atan2(y / scale - my, x / scale - mx))
	place()
end

local function create()
	button = CreateFrame("Button", nil, Minimap)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
	T.Scale:SetSize(button, 36, 36)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	local surface = T.Surface:Acquire(button, { color = "surfaceContainerHigh", shape = "full", width = 36, height = 36 })
	surface:SetAllPoints()
	local logo = T.Logo:Create(button, 24)
	logo:SetPoint("CENTER")
	logo:SetFrameLevel(surface:GetFrameLevel() + 1)
	button:SetScript("OnClick", function(_, mouse)
		if mouse == "RightButton" then T:GetModule("Gallery"):Toggle() else T:OpenConfig() end
	end)
	button:SetScript("OnEnter", function(self)
		surface:SetState("hover", "onSurface")
		T.Tooltip:ShowFor(self, { title = "Tonic", text = L["Left click: options. Right click: gallery."] })
	end)
	button:SetScript("OnLeave", function(self)
		surface:SetState(nil)
		T.Tooltip:HideFor(self)
	end)
	-- Our own frame: an OnUpdate only while dragging.
	button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", onDragUpdate) end)
	button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	place()
end

---@param shown boolean
function module:SetShown(shown)
	T.db.global.minimap.hide = not shown
	if shown and not button then create() end
	if button then button:SetShown(shown) end
end

function module:OnEnable()
	if not T.db.global.minimap.hide then create() end
	if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
		AddonCompartmentFrame:RegisterAddon({
			text = "Tonic",
			icon = T.mediaPath .. "Textures\\Icon64",
			notCheckable = true,
			func = function() T:OpenConfig() end,
		})
	end
end
