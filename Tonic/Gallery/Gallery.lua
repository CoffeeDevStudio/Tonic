-- /tonic gallery: every token and primitive in every state, dark and light side by side,
-- for visual QA after each patch. The preview seed can be cycled without touching the profile.

local T = Tonic
local L = T.L

local Gallery = T:NewModule("Gallery")

local WINDOW_W, WINDOW_H = 1000, 720
local COLUMN_W = 456
local PAD, GAP = 24, 12
local INNER_W = COLUMN_W - 2 * PAD

local ROLE_PAIRS = {
	{ "primary", "onPrimary" }, { "primaryContainer", "onPrimaryContainer" },
	{ "secondary", "onSecondary" }, { "secondaryContainer", "onSecondaryContainer" },
	{ "tertiary", "onTertiary" }, { "tertiaryContainer", "onTertiaryContainer" },
	{ "error", "onError" }, { "errorContainer", "onErrorContainer" },
	{ "surfaceVariant", "onSurfaceVariant" }, { "inverseSurface", "inverseOnSurface" },
	{ "outline", "surface" }, { "outlineVariant", "onSurface" },
}

local USAGES = { "loading", "window", "hud", "menu", "slot" }
local SHAPES = { "xs", "s", "m", "l", "xl", "full" }
local STATES = { "enabled", "hover", "focus", "pressed", "disabled" }
local SEMANTIC = {
	"health", "mana", "rage", "energy", "hostile",
	"chatGuild", "chatParty", "chatWhisper",
	"qualityCommon", "qualityUncommon", "qualityRare", "qualityEpic", "qualityLegendary",
}

local function seedName(seed)
	if seed == T.Scheme.DEFAULT_SEED then return "Tonic" end
	return LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[seed] or seed
end

-- ------------------------------------------------------------- column builder

---@class TonicGalleryColumn
---@field mode "dark"|"light"
---@field items table[] pinned surfaces and texts
---@field panel TonicSurface
---@field y number dp
local Column = {}
Column.__index = Column

function Column:Track(item)
	self.items[#self.items + 1] = item
	return item
end

function Column:Surface(parent, props, x, y)
	props.theme = self.theme
	local s = self:Track(T.Surface:Acquire(parent, props))
	T.Scale:SetPoint(s, "TOPLEFT", parent, "TOPLEFT", x, -y)
	return s
end

function Column:Text(parent, props, point, x, y, relativePoint)
	props.theme = self.theme
	local t = self:Track(T.Text:Acquire(parent, props))
	T.Scale:SetPoint(t, point or "TOPLEFT", parent, relativePoint or point or "TOPLEFT", x or 0, y or 0)
	return t
end

function Column:Heading(text)
	self.y = self.y + 8
	self:Text(self.panel, { role = "titleMedium", color = "primary", text = text }, "TOPLEFT", PAD, -self.y)
	self.y = self.y + 32
end

function Column:Tiles(count, perRow, height, build)
	local w = (INNER_W - (perRow - 1) * GAP) / perRow
	for i = 1, count do
		local col, row = (i - 1) % perRow, math.floor((i - 1) / perRow)
		build(i, PAD + col * (w + GAP), self.y + row * (height + GAP), w)
	end
	self.y = self.y + math.ceil(count / perRow) * (height + GAP)
end

function Column:BuildRoles()
	self:Heading(L["Color roles"])
	self:Tiles(#ROLE_PAIRS, 2, 44, function(i, x, y, w)
		local bg, fg = ROLE_PAIRS[i][1], ROLE_PAIRS[i][2]
		local tile = self:Surface(self.panel, { color = bg, shape = "s", width = w, height = 44 }, x, y)
		self:Text(tile, { role = "labelMedium", color = fg, text = bg }, "LEFT", 12, 0)
	end)
end

function Column:BuildElevation()
	self:Heading(L["Tonal elevation"])
	self:Tiles(#USAGES, 1, 40, function(i, x, y, w)
		local usage = USAGES[i]
		local tile = self:Surface(self.panel, { usage = usage, shape = "s", shadow = 0, outline = "outlineVariant",
			width = w, height = 40 }, x, y)
		local label = usage .. "  ·  " .. T.Elevation:Role(usage)
		if T.Elevation:GetUsage(usage).hud then label = label .. "  ·  HUD " .. L["opacity"] end
		self:Text(tile, { role = "labelMedium", color = "onSurface", text = label }, "LEFT", 12, 0)
	end)
end

function Column:BuildShapes()
	self:Heading(L["Shape"])
	self:Tiles(#SHAPES, 3, 64, function(i, x, y, w)
		local token = SHAPES[i]
		local tile = self:Surface(self.panel, { color = "secondaryContainer", shape = token, width = w, height = 64 }, x, y)
		local radius = T.Shape.tokens[token]
		self:Text(tile, { role = "labelLarge", color = "onSecondaryContainer",
			text = token .. "  " .. (radius == "full" and "full" or radius .. " dp") }, "CENTER")
	end)
end

function Column:BuildShadows()
	self:Heading(L["Shadows (windows and menus only)"])
	self.y = self.y + 4
	self:Tiles(5, 5, 56, function(i, x, y, w)
		local card = self:Surface(self.panel, { color = "surfaceContainerLow", shape = "m", shadow = i,
			width = w, height = 56 }, x, y)
		self:Text(card, { role = "labelLarge", color = "onSurface", text = tostring(i), numeric = true }, "CENTER")
	end)
	self.y = self.y + 8
end

function Column:BuildTypography()
	self:Heading(L["Typography"])
	for _, role in ipairs(T.Typography.order) do
		local line = T.Typography:LineHeight(role)
		self:Text(self.panel, { role = role, color = "onSurface", text = "Tonic 1234" }, "TOPLEFT", PAD, -self.y)
		self:Text(self.panel, { role = "labelSmall", color = "onSurfaceVariant", text = role, justifyH = "RIGHT" },
			"TOPRIGHT", -PAD, -self.y)
		self.y = self.y + line + 4
	end
	self:Text(self.panel, { role = "bodyMedium", color = "onSurfaceVariant", text = L["proportional"] .. "  1111 / 8888" },
		"TOPLEFT", PAD, -self.y)
	self.y = self.y + 22
	self:Text(self.panel, { role = "bodyMedium", color = "onSurface", numeric = true,
		text = L["tabular"] .. "  1111 / 8888" }, "TOPLEFT", PAD, -self.y)
	self.y = self.y + 28
end

function Column:BuildSemantic()
	self:Heading(L["Semantic colors"])
	for _, key in ipairs(SEMANTIC) do
		self:Text(self.panel, { role = "labelMedium", color = "onSurfaceVariant", text = key }, "TOPLEFT", PAD, -(self.y + 6))
		local track = self:Surface(self.panel, { usage = "track", width = 150, height = 8 }, PAD + 128, self.y + 10)
		self:Surface(track, { color = key .. ".bar", shape = "full", width = 105, height = 8 }, 0, 0)
		local chip = self:Surface(self.panel, { color = key .. ".container", shape = "s", width = 48, height = 28 },
			PAD + 290, self.y)
		self:Text(chip, { role = "labelMedium", color = key .. ".onContainer", text = "Aa" }, "CENTER")
		self:Text(self.panel, { role = "labelLarge", color = key .. ".color", numeric = true, text = "12 345",
			justifyH = "RIGHT" }, "TOPRIGHT", -PAD, -(self.y + 6))
		self.y = self.y + 36
	end
end

function Column:BuildStates()
	self:Heading(L["States"])
	self:Tiles(#STATES, 5, 40, function(i, x, y, w)
		local state = STATES[i]
		local tile = self:Surface(self.panel, { color = "primaryContainer", shape = "full", width = w, height = 40 }, x, y)
		local label = self:Text(tile, { role = "labelSmall", color = "onPrimaryContainer", text = L[state] }, "CENTER")
		if state ~= "enabled" then
			tile:SetState(state, "onPrimaryContainer")
			label:SetState(state)
		end
	end)
end

-- Places components left to right, wrapping at the column width.
function Column:Flow(defs, rowHeight)
	local x, rowY = PAD, self.y
	for _, def in ipairs(defs) do
		def.props.theme = self.theme
		local item = self:Track(def.factory:Acquire(self.panel, def.props))
		if def.state then item:SetState(def.state) end
		local w = item:GetWidth() / T.Scale.density
		if x + w > PAD + INNER_W and x > PAD then
			x = PAD
			rowY = rowY + rowHeight + GAP
		end
		item:ClearAllPoints()
		T.Scale:SetPoint(item, "TOPLEFT", self.panel, "TOPLEFT", x, -(rowY + (rowHeight - item:GetHeight() / T.Scale.density) / 2))
		x = x + w + GAP
	end
	self.y = rowY + rowHeight + GAP
end

function Column:BuildButtons()
	self:Heading(L["Buttons"])
	local defs = {}
	for _, variant in ipairs({ "filled", "tonal", "elevated", "outlined", "text" }) do
		defs[#defs + 1] = { factory = T.Button, props = { text = variant, variant = variant } }
	end
	defs[#defs + 1] = { factory = T.Button, props = { text = L["icon"], variant = "filled", icon = "add" } }
	defs[#defs + 1] = { factory = T.Button, props = { text = L["disabled"], variant = "filled", disabled = true } }
	defs[#defs + 1] = { factory = T.Button, props = { text = L["disabled"], variant = "outlined", disabled = true } }
	self:Flow(defs, 40)
	local icons = {}
	for _, variant in ipairs({ "standard", "filled", "tonal", "outlined" }) do
		icons[#icons + 1] = { factory = T.IconButton, props = { icon = "settings", variant = variant, tooltip = variant } }
		icons[#icons + 1] = { factory = T.IconButton, props = { icon = "star", variant = variant, toggle = true, selected = true } }
	end
	icons[#icons + 1] = { factory = T.IconButton, props = { icon = "delete", variant = "filled", disabled = true } }
	self:Flow(icons, 40)
	self:Flow({
		{ factory = T.FAB, props = { icon = "add", size = "small" } },
		{ factory = T.FAB, props = { icon = "edit", color = "secondary" } },
		{ factory = T.FAB, props = { icon = "palette", color = "tertiary" } },
		{ factory = T.FAB, props = { icon = "add", text = L["New"], color = "surface" } },
	}, 56)
end

function Column:BuildSelection()
	self:Heading(L["Selection"])
	self:Flow({
		{ factory = T.Switch, props = { checked = false } },
		{ factory = T.Switch, props = { checked = true } },
		{ factory = T.Switch, props = { checked = true, icons = true } },
		{ factory = T.Switch, props = { checked = false, icons = true } },
		{ factory = T.Switch, props = { checked = true, disabled = true } },
		{ factory = T.Switch, props = { checked = false, disabled = true } },
	}, 40)
	self:Flow({
		{ factory = T.Checkbox, props = { checked = false } },
		{ factory = T.Checkbox, props = { checked = true } },
		{ factory = T.Checkbox, props = { checked = "indeterminate" } },
		{ factory = T.Checkbox, props = { checked = true, error = true } },
		{ factory = T.Checkbox, props = { checked = true, disabled = true } },
		{ factory = T.Checkbox, props = { checked = false, text = L["Label"] } },
	}, 40)
	local group = {}
	self:Flow({
		{ factory = T.Radio, props = { group = group, selected = true, text = L["Dark"] } },
		{ factory = T.Radio, props = { group = group, text = L["Light"] } },
		{ factory = T.Radio, props = { selected = true, disabled = true } },
		{ factory = T.Radio, props = { disabled = true } },
	}, 40)
	self:Flow({
		{ factory = T.Slider, props = { min = 0.6, max = 1, step = 0.01, value = 0.88, width = INNER_W,
			format = function(v) return ("%d%%"):format(v * 100 + 0.5) end } },
	}, 40)
	self:Flow({ { factory = T.Slider, props = { value = 0.4, width = INNER_W, disabled = true } } }, 40)
end

function Column:BuildFields()
	self:Heading(L["Text fields"])
	local w = (INNER_W - GAP) / 2
	self:Flow({
		{ factory = T.TextField, props = { label = L["Filled"], width = w } },
		{ factory = T.TextField, props = { label = L["Outlined"], variant = "outlined", width = w } },
		{ factory = T.TextField, props = { label = L["Name"], text = "Tonic", width = w, supporting = L["Supporting text"] } },
		{ factory = T.TextField, props = { label = L["Name"], variant = "outlined", width = w, error = L["Error text"] } },
	}, 76)
end

function Column:BuildContainers()
	self:Heading(L["Tabs, cards and lists"])
	self:Flow({ { factory = T.Tabs, props = { width = INNER_W, selected = 2,
		tabs = { { text = L["Appearance"] }, { text = L["Skins"] }, { text = L["Profiles"] } } } } }, 48)
	local w = (INNER_W - 2 * GAP) / 3
	self:Flow({
		{ factory = T.Card, props = { variant = "elevated", width = w, height = 96, title = "elevated", text = L["Card text"] } },
		{ factory = T.Card, props = { variant = "filled", width = w, height = 96, title = "filled", text = L["Card text"] } },
		{ factory = T.Card, props = { variant = "outlined", width = w, height = 96, title = "outlined", text = L["Card text"],
			onClick = function() end } },
	}, 96)
	self:Flow({ { factory = T.List, props = { width = INNER_W, height = 3 * 72, selectable = true, items = {
		{ headline = L["Character"], supporting = L["Window, slots, item level"], icon = "person", trailing = "ok" },
		{ headline = L["Bags"], supporting = L["Quality containers"], icon = "search", trailing = "ok" },
		{ headline = L["Tooltips"], supporting = L["Rich tooltip surface"], icon = "info", trailing = "ok" },
		{ headline = L["Chat"], supporting = L["HUD panel and fields"], icon = "menu" },
	} } } }, 3 * 72)
end

function Column:BuildOverlays()
	self:Heading(L["Overlays (current theme)"])
	self:Flow({
		{ factory = T.Button, props = { text = "Dialog", variant = "tonal", onClick = function()
			T.Dialog:Show({ icon = "palette", title = L["Apply the theme?"], text = L["Dialog sample text"],
				actions = { { text = L["Cancel"] }, { text = L["Apply"] } } })
		end } },
		{ factory = T.Button, props = { text = "Snackbar", variant = "tonal", onClick = function()
			T.Snackbar:Show(L["Profile saved"], { action = L["Undo"] })
		end } },
		{ factory = T.Button, props = { text = "Menu", variant = "tonal", onClick = function(button)
			T.Menu:Open(button, {
				{ text = L["Dark"], icon = "dark_mode", checked = true },
				{ text = L["Light"], icon = "light_mode" },
				{ divider = true },
				{ text = L["Options"], icon = "settings", trailing = "/tonic" },
				{ text = L["disabled"], disabled = true },
			})
		end } },
		{ factory = T.Button, props = { text = "Tooltip", variant = "outlined",
			tooltip = { title = L["Rich tooltip"], text = L["Tooltip sample text"] } } },
	}, 40)
end

function Column:ApplyTheme(theme)
	self.theme = theme
	for _, item in ipairs(self.items) do item:ApplyTheme(theme) end
	self.title:SetText(self.mode == "dark" and L["Dark"] or L["Light"])
end

local function buildColumn(parent, mode, theme, x)
	local col = setmetatable({ mode = mode, theme = theme, items = {}, y = PAD }, Column)
	col.panel = col:Surface(parent, { color = "surface", shape = "l", width = COLUMN_W, height = 100 }, x, 0)
	col.title = col:Text(col.panel, { role = "headlineSmall", color = "onSurface" }, "TOPLEFT", PAD, -col.y)
	col.y = col.y + 40
	col:BuildRoles()
	col:BuildElevation()
	col:BuildShapes()
	col:BuildShadows()
	col:BuildTypography()
	col:BuildSemantic()
	col:BuildStates()
	col:BuildButtons()
	col:BuildSelection()
	col:BuildFields()
	col:BuildContainers()
	col:BuildOverlays()
	col.y = col.y + PAD
	col.panel:Update({ height = col.y })
	col:ApplyTheme(theme)
	return col
end

-- ------------------------------------------------------------- window

local function chip(parent, text, onClick)
	local s = T.Surface:Acquire(parent, { color = "secondaryContainer", shape = "full", height = 32, width = 40 })
	local label = T.Text:Acquire(s, { role = "labelLarge", color = "onSecondaryContainer", text = text })
	label:SetPoint("CENTER")
	s.label = label
	s:Update({ width = math.max(40, label:GetStringWidth() / T.Scale.density + 32) })
	s:EnableMouse(true)
	s:SetScript("OnEnter", function(self) self:SetState("hover", "onSecondaryContainer") end)
	s:SetScript("OnLeave", function(self) self:SetState(nil) end)
	s:SetScript("OnMouseDown", function(self) self:SetState("pressed", "onSecondaryContainer") end)
	s:SetScript("OnMouseUp", function(self)
		self:SetState(self:IsMouseOver() and "hover" or nil, "onSecondaryContainer")
		if self:IsMouseOver() then onClick() end
	end)
	return s
end

function Gallery:CycleSeed(step)
	local seeds = T.Scheme:GetSeeds()
	local current = self.seed or T.Theme:GetSeed()
	local index = 1
	for i, seed in ipairs(seeds) do if seed == current then index = i end end
	self.seed = seeds[(index - 1 + step) % #seeds + 1]
	self:Refresh()
end

function Gallery:Refresh()
	if not self.window then return end
	local seed = self.seed or T.Theme:GetSeed()
	self.columns[1]:ApplyTheme(T.Theme:Build(seed, "dark"))
	self.columns[2]:ApplyTheme(T.Theme:Build(seed, "light"))
	self.seedChip.label:SetText(seedName(seed) .. "  #" .. T.Scheme:GetSeedHex(seed))
	self.seedChip:Update({ width = self.seedChip.label:GetStringWidth() / T.Scale.density + 32 })
end

function Gallery:Build()
	local window = T.Surface:Acquire(UIParent, { usage = "window", width = WINDOW_W, height = WINDOW_H })
	self.window = window
	window:SetFrameStrata("DIALOG")
	window:SetPoint("CENTER")
	window:SetClampedToScreen(true)
	window:SetMovable(true)
	window:EnableMouse(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnDragStart", window.StartMoving)
	window:SetScript("OnDragStop", window.StopMovingOrSizing)
	window:EnableKeyboard(true)
	-- SetPropagateKeyboardInput is blocked in combat: there ESC simply does not close the gallery.
	if not InCombatLockdown() then window:SetPropagateKeyboardInput(true) end
	window:SetScript("OnKeyDown", function(frame, key)
		if InCombatLockdown() then return end
		local close = key == "ESCAPE"
		frame:SetPropagateKeyboardInput(not close)
		if close then frame:Hide() end
	end)

	local title = T.Text:Acquire(window, { role = "headlineSmall", color = "onSurface", text = "Tonic Gallery" })
	T.Scale:SetPoint(title, "TOPLEFT", window, "TOPLEFT", PAD, -22)
	local subtitle = T.Text:Acquire(window, { role = "bodySmall", color = "onSurfaceVariant",
		text = T.Typography:HasTonicFonts() and ("v" .. T.version)
			or ("v" .. T.version .. "  ·  " .. L["Tonic fonts not installed: using Blizzard fonts"]) })
	T.Scale:SetPoint(subtitle, "TOPLEFT", title, "BOTTOMLEFT", 0, -2)

	local close = chip(window, L["Close"], function() window:Hide() end)
	T.Scale:SetPoint(close, "TOPRIGHT", window, "TOPRIGHT", -PAD, -20)
	local nextSeed = chip(window, ">", function() self:CycleSeed(1) end)
	T.Scale:SetPoint(nextSeed, "RIGHT", close, "LEFT", -24, 0)
	self.seedChip = chip(window, "", function() self.seed = nil; self:Refresh() end)
	T.Scale:SetPoint(self.seedChip, "RIGHT", nextSeed, "LEFT", -8, 0)
	local prevSeed = chip(window, "<", function() self:CycleSeed(-1) end)
	T.Scale:SetPoint(prevSeed, "RIGHT", self.seedChip, "LEFT", -8, 0)

	local scroll = CreateFrame("ScrollFrame", nil, window)
	T.Scale:SetPoint(scroll, "TOPLEFT", window, "TOPLEFT", PAD, -76)
	T.Scale:SetPoint(scroll, "BOTTOMRIGHT", window, "BOTTOMRIGHT", -PAD, PAD)
	local content = CreateFrame("Frame", nil, scroll)
	scroll:SetScrollChild(content)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(frame, delta)
		local y = frame:GetVerticalScroll() - delta * T.Scale:Dp(64, frame)
		frame:SetVerticalScroll(math.max(0, math.min(y, frame:GetVerticalScrollRange())))
	end)

	local seed = T.Theme:GetSeed()
	self.columns = {
		buildColumn(content, "dark", T.Theme:Build(seed, "dark"), 0),
		buildColumn(content, "light", T.Theme:Build(seed, "light"), COLUMN_W + (WINDOW_W - 2 * PAD - 2 * COLUMN_W)),
	}
	local height = math.max(self.columns[1].y, self.columns[2].y)
	T.Scale:SetSize(content, WINDOW_W - 2 * PAD, height)

	T.Events:RegisterMessage("Tonic.ThemeChanged", self, function() self:Refresh() end)
	self:Refresh()

	-- Fade in with the shared ticker.
	window:SetScript("OnShow", function(frame)
		frame:SetAlpha(0)
		T.Motion:Tween("medium2", "emphasizedDecelerate", function(p) frame:SetAlpha(p) end)
	end)
end

function Gallery:Toggle()
	if not self.window then
		self:Build()
		return
	end
	self.window:SetShown(not self.window:IsShown())
end
