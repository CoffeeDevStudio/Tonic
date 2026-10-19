-- M3 basic dialog: scrim, surfaceContainerHigh, shape XL, shadow 3; optional icon,
-- headline, supporting text and text-button actions aligned right.
--   T.Dialog:Show({ title = "Delete profile?", text = "This can't be undone.",
--     actions = { { text = "Cancel" }, { text = "Delete", onClick = fn } } })

local T = Tonic

---@class TonicDialogAction
---@field text string
---@field onClick fun()?
---@field variant string? button variant, default "text"
---@field keepOpen boolean?

---@class TonicDialogOptions
---@field title string?
---@field text string?
---@field icon string?
---@field width number? dp, 280..560, default 312
---@field actions TonicDialogAction[]?
---@field onCancel fun()? Escape or click on the scrim

---@class TonicDialog
local Dialog = {}
T.Dialog = Dialog

local scrim, scrimTex, card, icon, title, text
local buttons = {}
local current

local function ensureFrames()
	if scrim then return end
	scrim = CreateFrame("Button", nil, UIParent)
	scrim:SetAllPoints(UIParent)
	scrim:SetFrameStrata("FULLSCREEN_DIALOG")
	scrim:RegisterForClicks("AnyUp")
	scrim:SetScript("OnClick", function() Dialog:Cancel() end)
	scrim:EnableKeyboard(true)
	scrim:SetScript("OnKeyDown", function(self, key)
		if InCombatLockdown() then return end
		local close = key == "ESCAPE"
		self:SetPropagateKeyboardInput(not close)
		if close then Dialog:Cancel() end
	end)
	scrimTex = scrim:CreateTexture(nil, "BACKGROUND")
	scrimTex:SetAllPoints()
	scrimTex:SetTexture(T.Shape.white)
	scrim:Hide()

	card = T.Surface:Acquire(scrim, { usage = "dialog" })
	card:SetPoint("CENTER")
	card:EnableMouse(true)
	icon = T.Icon:Acquire(card, { name = "info", size = 24, color = "secondary" })
	title = T.Text:Acquire(card, { role = "headlineSmall", color = "onSurface", wrap = true })
	text = T.Text:Acquire(card, { role = "bodyMedium", color = "onSurfaceVariant", wrap = true })

	T.Theme:Register({ ApplyTheme = function(_, theme)
		local r, g, b = theme:RGB("scrim")
		scrimTex:SetVertexColor(r, g, b, 0.32)
	end })
end

---Shows a dialog (replacing the one open, if any).
---@param opts TonicDialogOptions
function Dialog:Show(opts)
	ensureFrames()
	self:Close()
	current = opts
	local width = math.min(560, math.max(280, opts.width or 312))
	local inner = width - 48
	local y = 24

	icon:SetShown(opts.icon ~= nil)
	if opts.icon then
		icon:Update({ name = opts.icon })
		icon:ClearAllPoints()
		T.Scale:SetPoint(icon, "TOP", card, "TOP", 0, -y)
		y = y + 24 + 16
	end
	title:SetShown(opts.title ~= nil)
	if opts.title then
		title:Update({ text = opts.title, width = inner, justifyH = opts.icon and "CENTER" or "LEFT" })
		title:ClearAllPoints()
		T.Scale:SetPoint(title, "TOPLEFT", card, "TOPLEFT", 24, -y)
		y = y + title:GetStringHeight() / T.Scale.density + 16
	end
	text:SetShown(opts.text ~= nil)
	if opts.text then
		text:Update({ text = opts.text, width = inner })
		text:ClearAllPoints()
		T.Scale:SetPoint(text, "TOPLEFT", card, "TOPLEFT", 24, -y)
		y = y + text:GetStringHeight() / T.Scale.density + 24
	end

	-- Actions, right to left.
	local x = 24
	local actions = opts.actions or { { text = OKAY or "OK" } }
	for i = #actions, 1, -1 do
		local action = actions[i]
		local button = T.Button:Acquire(card, { text = action.text, variant = action.variant or "text",
			onClick = function()
				if not action.keepOpen then Dialog:Close() end
				if action.onClick then action.onClick() end
			end })
		button:SetFrameLevel(card:GetFrameLevel() + 2)
		button:SyncLevels()
		T.Scale:SetPoint(button, "BOTTOMRIGHT", card, "BOTTOMRIGHT", -x, 24)
		x = x + button:GetWidth() / T.Scale.density + 8
		buttons[#buttons + 1] = button
	end
	y = y + 40 + 24
	card:Update({ width = width, height = y })

	scrim:Show()
	if not InCombatLockdown() then scrim:SetPropagateKeyboardInput(true) end
	scrim:SetAlpha(0)
	T.Motion:Tween("medium2", "emphasizedDecelerate", function(p) scrim:SetAlpha(p) end)
end

function Dialog:Cancel()
	local opts = current
	self:Close()
	if opts and opts.onCancel then opts.onCancel() end
end

function Dialog:Close()
	for i = #buttons, 1, -1 do
		buttons[i]:Release()
		buttons[i] = nil
	end
	current = nil
	if scrim then scrim:Hide() end
end

---@return boolean
function Dialog:IsShown()
	return scrim ~= nil and scrim:IsShown()
end
