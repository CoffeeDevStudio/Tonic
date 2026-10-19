-- Tonic_Config: renders T.Options with Tonic components (dogfooding).
-- Window: surfaceContainerLow, shape XL, shadow 3; tabs per category; scrolling page.

local T = Tonic
local L = T.L

---@class TonicConfig
local Config = {
	renderers = {}, ---@type table<string, fun(page: TonicConfigPage, option: TonicOption)>
}
T.Config = Config

local WIDTH, HEIGHT = 760, 600
local PAD = 24
local CONTENT_W = WIDTH - 2 * PAD

-- ------------------------------------------------------------- page builder

---@class TonicConfigPage
---@field parent Frame scroll child
---@field items table[] acquired components, released on rebuild
---@field y number dp
local Page = {}
Page.__index = Page
Config.Page = Page

function Page:Track(item)
	self.items[#self.items + 1] = item
	return item
end

function Page:Text(props, x, width)
	props.width = width
	local t = self:Track(T.Text:Acquire(self.parent, props))
	T.Scale:SetPoint(t, "TOPLEFT", self.parent, "TOPLEFT", x or 0, -self.y)
	return t
end

---Label and description on the left; returns the height used by the texts (dp).
function Page:Labels(option, textWidth)
	local top = self.y
	local label = self:Text({ role = "bodyLarge", color = "onSurface", text = option.label or "" }, 0, textWidth)
	local h = label:GetStringHeight() / T.Scale.density
	if option.desc then
		self.y = top + h + 2
		local desc = self:Text({ role = "bodyMedium", color = "onSurfaceVariant", text = option.desc, wrap = true }, 0, textWidth)
		h = h + 2 + desc:GetStringHeight() / T.Scale.density
	end
	self.y = top
	return h
end

---Places a control right-aligned on the current row and advances by the row height.
function Page:Row(option, control, controlHeight)
	local textH = self:Labels(option, CONTENT_W - (control:GetWidth() / T.Scale.density) - 32)
	local rowH = math.max(textH, controlHeight)
	control:ClearAllPoints()
	T.Scale:SetPoint(control, "TOPRIGHT", self.parent, "TOPLEFT", CONTENT_W, -(self.y + (rowH - controlHeight) / 2))
	self:Track(control)
	self.y = self.y + rowH + 20
end

function Page:Release()
	for i = #self.items, 1, -1 do
		self.items[i]:Release()
		self.items[i] = nil
	end
end

-- ------------------------------------------------------------- renderers

local R = Config.renderers
local Options = T.Options

function R.header(page, option)
	page.y = page.y + (page.y > 0 and 12 or 0)
	page:Text({ role = "titleSmall", color = "primary", text = option.label })
	page.y = page.y + 32
end

function R.description(page, option)
	local t = page:Text({ role = "bodyMedium", color = "onSurfaceVariant", text = option.label, wrap = true }, 0, CONTENT_W)
	page.y = page.y + t:GetStringHeight() / T.Scale.density + 16
end

function R.toggle(page, option)
	local switch = T.Switch:Acquire(page.parent, {
		checked = Options:GetValue(option) ~= false,
		disabled = Options:IsDisabled(option),
		onChange = function(_, checked) Options:SetValue(option, checked) end,
	})
	page:Row(option, switch, 32)
end

function R.slider(page, option)
	local holder = { }
	local slider = T.Slider:Acquire(page.parent, {
		min = option.min, max = option.max, step = option.step, width = 220,
		value = Options:GetValue(option), format = option.format,
		disabled = Options:IsDisabled(option),
		onChange = function(_, value)
			Options:SetValue(option, value)
			if holder.value then holder.value:SetText(option.format and option.format(value) or ("%.2f"):format(value)) end
		end,
	})
	page:Row(option, slider, 40)
	local value = option.format and option.format(Options:GetValue(option) or 0) or ("%.2f"):format(Options:GetValue(option) or 0)
	holder.value = page:Track(T.Text:Acquire(page.parent, { role = "labelLarge", color = "onSurfaceVariant",
		numeric = true, text = value, justifyH = "RIGHT" }))
	T.Scale:SetPoint(holder.value, "RIGHT", slider, "LEFT", -12, 0)
end

function R.radio(page, option)
	local group, current = {}, Options:GetValue(option)
	local choices = Options:GetChoices(option)
	local top = page.y
	local textH = page:Labels(option, CONTENT_W - 220)
	for i, choice in ipairs(choices) do
		local radio = page:Track(T.Radio:Acquire(page.parent, {
			group = group, value = choice.value, text = choice.label, selected = choice.value == current,
			disabled = Options:IsDisabled(option),
			onChange = function(_, value) Options:SetValue(option, value) end,
		}))
		T.Scale:SetPoint(radio, "TOPLEFT", page.parent, "TOPLEFT", CONTENT_W - 200, -(top + (i - 1) * 40 - 8))
	end
	page.y = top + math.max(textH, #choices * 40 - 8) + 20
end

local function labelFor(choices, value)
	for _, choice in ipairs(choices) do
		if choice.value == value then return choice.label end
	end
	return tostring(value or "")
end

function R.select(page, option)
	local choices = Options:GetChoices(option)
	local button
	button = T.Button:Acquire(page.parent, {
		variant = "outlined", icon = "expand_more",
		text = labelFor(choices, Options:GetValue(option)) ~= "" and labelFor(choices, Options:GetValue(option))
			or (option.placeholder or L["Choose"]),
		disabled = Options:IsDisabled(option),
		onClick = function(self)
			local items = {}
			local current = Options:GetValue(option)
			for i, choice in ipairs(Options:GetChoices(option)) do
				items[i] = { text = choice.label, checked = choice.value == current, onClick = function()
					Options:SetValue(option, choice.value)
					self:SetText(choice.label)
				end }
			end
			T.Menu:Open(self, items, { minWidth = self:GetWidth() / T.Scale.density })
		end,
	})
	page:Row(option, button, 40)
end

function R.button(page, option)
	local button = T.Button:Acquire(page.parent, { text = option.text or option.label, variant = option.variant or "tonal",
		icon = option.icon, disabled = Options:IsDisabled(option), onClick = function() if option.onClick then option.onClick() end end })
	page:Row({ label = option.text and option.label or nil, desc = option.desc }, button, 40)
end

function R.input(page, option)
	local field = T.TextField:Acquire(page.parent, { label = option.placeholder, variant = "outlined",
		background = "surfaceContainerLow", text = Options:GetValue(option) or "", width = 260,
		onSubmit = function(_, text) Options:SetValue(option, text) end })
	page:Row(option, field, 56)
end

-- ------------------------------------------------------------- window

local window, tabs, scroll, content, page
local categories

function Config:Build()
	window = T.Surface:Acquire(UIParent, { usage = "window", width = WIDTH, height = HEIGHT })
	window:SetFrameStrata("FULLSCREEN")
	window:SetPoint("CENTER")
	window:SetClampedToScreen(true)
	window:SetMovable(true)
	window:EnableMouse(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", window.StartMoving)
	window:SetScript("OnDragStop", window.StopMovingOrSizing)
	window:EnableKeyboard(true)
	if not InCombatLockdown() then window:SetPropagateKeyboardInput(true) end
	window:SetScript("OnKeyDown", function(frame, key)
		if InCombatLockdown() then return end
		local close = key == "ESCAPE" and not T.Menu:IsOpen() and not T.Dialog:IsShown()
		frame:SetPropagateKeyboardInput(not close)
		if close then frame:Hide() end
	end)

	local logo = T.Logo:Create(window, 40)
	T.Scale:SetPoint(logo, "TOPLEFT", window, "TOPLEFT", PAD, -20)
	logo:SetFrameLevel(window:GetFrameLevel() + 2)
	local title = T.Text:Acquire(window, { role = "wordmark", color = "onSurface", text = "Tonic" })
	T.Scale:SetPoint(title, "TOPLEFT", logo, "TOPRIGHT", 12, 2)
	local tagline = T.Text:Acquire(window, { role = "bodySmall", color = "onSurfaceVariant", text = L["A tonic for your UI."] })
	T.Scale:SetPoint(tagline, "TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	local close = T.IconButton:Acquire(window, { icon = "close", tooltip = L["Close"], onClick = function() window:Hide() end })
	T.Scale:SetPoint(close, "TOPRIGHT", window, "TOPRIGHT", -16, -16)

	categories = T.Options:GetCategories()
	local defs = {}
	for i, category in ipairs(categories) do defs[i] = { text = category.title } end
	tabs = T.Tabs:Acquire(window, { tabs = defs, width = CONTENT_W, selected = 1,
		onChange = function(_, index) Config:ShowCategory(index) end })
	T.Scale:SetPoint(tabs, "TOPLEFT", window, "TOPLEFT", PAD, -76)

	scroll = CreateFrame("ScrollFrame", nil, window)
	T.Scale:SetPoint(scroll, "TOPLEFT", window, "TOPLEFT", PAD, -140)
	T.Scale:SetPoint(scroll, "BOTTOMRIGHT", window, "BOTTOMRIGHT", -PAD, PAD)
	content = CreateFrame("Frame", nil, scroll)
	T.Scale:SetSize(content, CONTENT_W, 10)
	scroll:SetScrollChild(content)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(frame, delta)
		local y = frame:GetVerticalScroll() - delta * T.Scale:Dp(64, frame)
		frame:SetVerticalScroll(math.max(0, math.min(y, frame:GetVerticalScrollRange())))
	end)

	page = setmetatable({ parent = content, items = {}, y = 0 }, Page)
	T.Events:RegisterMessage("Tonic.ProfileChanged", self, function() Config:Rebuild() end)
	self:ShowCategory(1)
end

---Renders a category page.
---@param index integer
function Config:ShowCategory(index)
	self.index = index
	page:Release()
	page.y = 0
	local category = categories[index]
	for _, option in ipairs(T.Options:GetOptions(category.id)) do
		local render = R[option.type]
		if render then
			xpcall(render, geterrorhandler(), page, option)
		end
	end
	T.Scale:SetSize(content, CONTENT_W, math.max(page.y, 10))
	scroll:SetVerticalScroll(0)
end

function Config:Rebuild()
	if window and window:IsShown() then self:ShowCategory(self.index or 1) end
end

function Config:Toggle()
	if not window then
		self:Build()
		return
	end
	if window:IsShown() then
		window:Hide()
	else
		window:Show()
		self:Rebuild()
	end
end
