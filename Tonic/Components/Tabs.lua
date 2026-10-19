-- M3 primary tabs: 48 dp, titleSmall labels, 3 dp indicator under the active label,
-- 1 dp divider. The indicator slides with the shared ticker.
--   T.Tabs:Acquire(parent, { width = 600, tabs = { { text = "General" }, { text = "Skins" } },
--     selected = 1, onChange = function(self, index) end })

local T = Tonic

-- ------------------------------------------------------------- tab

---@class TonicTab: TonicComponent
local TabMixin = {}

function TabMixin:Build()
	self.stateLayer = T.StateLayer:Create(self, "BACKGROUND", -4)
	self.label = self:CreateLabel("titleSmall")
	self.label:SetPoint("CENTER")
end

function TabMixin:NaturalWidth()
	self.label:SetText(self.props.text or "")
	return self:TextWidth(self.label) + 32
end

function TabMixin:Layout()
	self.label:SetText(self.props.text or "")
	T.Scale:SetSize(self, self.props.width or self:NaturalWidth(), 48)
	self.stateLayer:Layout("none")
end

function TabMixin:Render(theme, state)
	local active = self.props.active
	self.stateLayer:Paint(theme, active and "primary" or "onSurface", state)
	self.label:SetTextColor(self:ContentColor(theme, state, active and "primary" or "onSurfaceVariant"))
	self.rippleColor = active and "primary" or "onSurface"
end

function TabMixin:OnActivate()
	self.props.owner:Select(self.props.index, true)
end

T:DefineComponent("Tab", { mixin = TabMixin, ripple = true })

-- ------------------------------------------------------------- tabs

---@class TonicTabs: TonicComponent
local TabsMixin = {}

function TabsMixin:Build()
	self.tabs = {}
	self.divider = self:CreateTexture(nil, "BORDER")
	self.divider:SetTexture(T.Shape.white)
	self.indicatorFrame = CreateFrame("Frame", nil, self)
	self.indicator = T.Shape:CreatePieces(self.indicatorFrame, "ARTWORK", 0)
end

function TabsMixin:OnLevelChanged(level)
	self.indicatorFrame:SetFrameLevel(level + 3)
end

function TabsMixin:Layout()
	for i = #self.tabs, 1, -1 do
		self.tabs[i]:Release()
		self.tabs[i] = nil
	end
	local p = self.props
	local defs = p.tabs or {}
	local fixed = p.width and #defs > 0 and p.width / #defs
	local x = 0
	for i, def in ipairs(defs) do
		local tab = T.Tab:Acquire(self, { text = def.text, index = i, owner = self, theme = p.theme,
			active = i == (p.selected or 1), width = fixed or nil })
		tab:ClearAllPoints()
		T.Scale:SetPoint(tab, "TOPLEFT", self, "TOPLEFT", x, 0)
		x = x + tab:GetWidth() / T.Scale.density
		self.tabs[i] = tab
	end
	T.Scale:SetSize(self, p.width or x, 48)
	self.divider:ClearAllPoints()
	self.divider:SetPoint("BOTTOMLEFT")
	self.divider:SetPoint("BOTTOMRIGHT")
	self.divider:SetHeight(T.Scale:Dp(1, self))
	self:PlaceIndicator(p.selected or 1, false)
end

-- Indicator under the label of tab index, optionally animated.
function TabsMixin:PlaceIndicator(index, animate)
	local tab = self.tabs[index]
	if not tab then return end
	local labelW = math.max(24, tab:TextWidth(tab.label))
	local tabX = (tab:GetLeft() and self:GetLeft()) and (tab:GetLeft() - self:GetLeft()) / T.Scale.density or 0
	if tabX == 0 then
		for i = 1, index - 1 do tabX = tabX + self.tabs[i]:GetWidth() / T.Scale.density end
	end
	local toX = tabX + (tab:GetWidth() / T.Scale.density - labelW) / 2
	local fromX, fromW = self.indicatorX or toX, self.indicatorW or labelW
	local function place(p)
		self.indicatorX = fromX + (toX - fromX) * p
		self.indicatorW = fromW + (labelW - fromW) * p
		self.indicatorFrame:ClearAllPoints()
		T.Scale:SetPoint(self.indicatorFrame, "BOTTOMLEFT", self, "BOTTOMLEFT", self.indicatorX, 0)
		T.Scale:SetSize(self.indicatorFrame, self.indicatorW, 3)
		T.Shape:Apply(self.indicator, self.indicatorFrame, 3, nil, true)
	end
	T.Motion:Cancel(self.tween)
	if animate then
		self.tween = T.Motion:Tween("medium2", "emphasizedDecelerate", place, function() self.tween = nil end)
	else
		place(1)
	end
end

---Selects a tab.
---@param index integer
---@param userInput? boolean calls onChange
function TabsMixin:Select(index, userInput)
	if index == self.props.selected and userInput then return end
	self.props.selected = index
	for i, tab in ipairs(self.tabs) do
		tab.props.active = i == index
		tab:Refresh()
	end
	self:PlaceIndicator(index, userInput)
	if userInput and self.props.onChange then self.props.onChange(self, index) end
end

function TabsMixin:Render(theme)
	self.divider:SetVertexColor(theme:RGB("surfaceVariant"))
	self.indicator:SetColor(theme:RGB("primary"))
	for _, tab in ipairs(self.tabs) do
		if self.props.theme then tab:ApplyTheme(theme) end
	end
end

function TabsMixin:OnRelease()
	T.Motion:Cancel(self.tween)
	for i = #self.tabs, 1, -1 do
		self.tabs[i]:Release()
		self.tabs[i] = nil
	end
	self.indicatorX, self.indicatorW, self.tween = nil, nil, nil
end

T:DefineComponent("Tabs", { mixin = TabsMixin, frameType = "Frame", interactive = false, defaults = { selected = 1 } })
