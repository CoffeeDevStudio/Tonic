-- M3 menu: surfaceContainerHigh, shape M, shadow 2, 48 dp items. One menu open at a time;
-- a click outside, Escape or choosing an item closes it.
--   T.Menu:Open(anchor, {
--     { text = "Dark", icon = "dark_mode", checked = true, onClick = fn },
--     { divider = true },
--     { text = "Reset", disabled = true },
--   })

local T = Tonic

---@class TonicMenuItemData
---@field text string?
---@field icon string?
---@field trailing string? trailing text (shortcut, value)
---@field checked boolean?
---@field disabled boolean?
---@field divider boolean?
---@field onClick fun(item: TonicMenuItemData)?

-- ------------------------------------------------------------- item

---@class TonicMenuItem: TonicComponent
local MenuItemMixin = {}

function MenuItemMixin:Build()
	self.stateLayer = T.StateLayer:Create(self, "BACKGROUND", -4)
	self.icon = T.Icon:Create(self.content)
	self.label = self:CreateLabel("labelLarge")
	self.trailing = self:CreateLabel("labelLarge")
	self.check = T.Icon:Create(self.content)
	self.divider = self:CreateTexture(nil, "ARTWORK")
	self.divider:SetTexture(T.Shape.white)
end

---Natural width in dp.
function MenuItemMixin:MeasureWidth()
	local d = self.props.data
	if d.divider then return 112 end
	self.label:SetText(d.text or "")
	self.trailing:SetText(d.trailing or "")
	local w = 12 + (d.icon and 36 or 0) + self:TextWidth(self.label) + 12
	if d.trailing then w = w + 12 + self:TextWidth(self.trailing) end
	if d.checked then w = w + 36 end
	return w
end

function MenuItemMixin:Layout()
	local d = self.props.data
	local isDivider = d.divider
	T.Scale:SetSize(self, self.props.width or 112, isDivider and 17 or 48)
	self:EnableMouse(not isDivider)
	self.divider:SetShown(isDivider and true or false)
	self.label:SetShown(not isDivider)
	self.icon:SetShown(not isDivider and d.icon ~= nil)
	self.check:SetShown(not isDivider and d.checked and true or false)
	self.trailing:SetShown(not isDivider and d.trailing ~= nil)
	if isDivider then
		self.divider:ClearAllPoints()
		self.divider:SetPoint("LEFT")
		self.divider:SetPoint("RIGHT")
		self.divider:SetHeight(T.Scale:Dp(1, self))
		return
	end
	self.label:SetText(d.text or "")
	self.label:ClearAllPoints()
	T.Scale:SetPoint(self.label, "LEFT", self, "LEFT", d.icon and 48 or 12, 0)
	if d.icon then
		self.icon:Update({ name = d.icon, size = 24 })
		self.icon:ClearAllPoints()
		T.Scale:SetPoint(self.icon, "LEFT", self, "LEFT", 12, 0)
	end
	local right = 12
	if d.checked then
		self.check:Update({ name = "check", size = 24 })
		self.check:ClearAllPoints()
		T.Scale:SetPoint(self.check, "RIGHT", self, "RIGHT", -12, 0)
		right = 48
	end
	if d.trailing then
		self.trailing:SetText(d.trailing)
		self.trailing:ClearAllPoints()
		T.Scale:SetPoint(self.trailing, "RIGHT", self, "RIGHT", -right, 0)
	end
	self.stateLayer:Layout("none")
end

function MenuItemMixin:Render(theme, state)
	local d = self.props.data
	if d.divider then
		self.divider:SetVertexColor(theme:RGB("outlineVariant"))
		return
	end
	self.stateLayer:Paint(theme, "onSurface", state)
	self.label:SetTextColor(self:ContentColor(theme, state, "onSurface"))
	self.trailing:SetTextColor(self:ContentColor(theme, state, "onSurfaceVariant"))
	self.icon:SetColor(self:ContentColor(theme, state, "onSurfaceVariant"))
	self.check:SetColor(self:ContentColor(theme, state, "primary"))
end

function MenuItemMixin:OnActivate()
	local d = self.props.data
	T.Menu:Close()
	if d.onClick then d.onClick(d) end
end

T:DefineComponent("MenuItem", { mixin = MenuItemMixin, ripple = true })

-- ------------------------------------------------------------- menu

---@class TonicMenu
local Menu = {}
T.Menu = Menu

local frame, surface, catcher
local items = {}

local function ensureFrames()
	if frame then return end
	catcher = CreateFrame("Button", nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata("FULLSCREEN_DIALOG")
	catcher:RegisterForClicks("AnyUp")
	catcher:SetScript("OnClick", function() Menu:Close() end)
	catcher:Hide()

	frame = CreateFrame("Frame", nil, UIParent)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(catcher:GetFrameLevel() + 10)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:EnableKeyboard(true)
	frame:SetScript("OnKeyDown", function(self, key)
		if InCombatLockdown() then return end
		local close = key == "ESCAPE"
		self:SetPropagateKeyboardInput(not close)
		if close then Menu:Close() end
	end)
	frame:Hide()
	surface = T.Surface:Acquire(frame, { usage = "menu" })
	surface:SetAllPoints()
end

---Opens a menu anchored to a region (or at the cursor when anchor is nil).
---@param anchor Region?
---@param data TonicMenuItemData[]
---@param opts? { point: string?, relativePoint: string?, x: number?, y: number?, minWidth: number? }
function Menu:Open(anchor, data, opts)
	opts = opts or {}
	ensureFrames()
	self:Close()

	local width = opts.minWidth or 112
	for i, d in ipairs(data) do
		local item = T.MenuItem:Acquire(frame, { data = d, disabled = d.disabled })
		items[i] = item
		width = math.max(width, item:MeasureWidth())
	end
	width = math.min(width, 280)
	local y = 8
	for _, item in ipairs(items) do
		item:Update({ width = width })
		item:ClearAllPoints()
		T.Scale:SetPoint(item, "TOPLEFT", frame, "TOPLEFT", 0, -y)
		y = y + (item.props.data.divider and 17 or 48)
	end
	T.Scale:SetSize(frame, width, y + 8)
	surface:Update({ width = width, height = y + 8 })
	surface:SetAllPoints()
	surface:SetFrameLevel(frame:GetFrameLevel())
	for _, item in ipairs(items) do
		item:SetFrameLevel(frame:GetFrameLevel() + 2)
		item:SyncLevels()
	end

	frame:ClearAllPoints()
	if anchor then
		T.Scale:SetPoint(frame, opts.point or "TOPLEFT", anchor, opts.relativePoint or "BOTTOMLEFT", opts.x or 0, opts.y or -4)
	else
		local x, cy = GetCursorPosition()
		local s = UIParent:GetEffectiveScale()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, cy / s)
	end
	catcher:Show()
	frame:Show()
	if not InCombatLockdown() then frame:SetPropagateKeyboardInput(true) end
	frame:SetAlpha(0)
	T.Motion:Tween("short3", "emphasizedDecelerate", function(p) frame:SetAlpha(p) end)
end

function Menu:Close()
	for i = #items, 1, -1 do
		items[i]:Release()
		items[i] = nil
	end
	if frame then
		frame:Hide()
		catcher:Hide()
	end
end

---@return boolean
function Menu:IsOpen()
	return frame ~= nil and frame:IsShown()
end
