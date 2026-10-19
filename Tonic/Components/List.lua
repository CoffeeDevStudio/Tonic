-- M3 list on Blizzard's ScrollBox + DataProvider (element frames are pooled by the view).
-- Items: { headline, supporting?, icon?, trailing?, ... }. One- or two-line rows (56/72 dp).
--   local list = T.List:Acquire(parent, { width = 320, height = 300, items = items,
--     selectable = true, onSelect = function(list, item, index) end })

local T = Tonic

-- ------------------------------------------------------------- row

---@class TonicListRow: Button
local RowMixin = {}

function RowMixin:Setup()
	self.stateLayer = T.StateLayer:Create(self, "BACKGROUND", -4)
	self.selectedFill = T.Shape:CreatePieces(self, "BACKGROUND", -6)
	self.icon = T.Icon:Create(self)
	self.headline = self:CreateFontString(nil, "OVERLAY")
	self.headline:SetFontObject(T.Typography:Get("bodyLarge"))
	self.headline:SetWordWrap(false)
	self.headline:SetJustifyH("LEFT")
	self.supporting = self:CreateFontString(nil, "OVERLAY")
	self.supporting:SetFontObject(T.Typography:Get("bodyMedium"))
	self.supporting:SetWordWrap(false)
	self.supporting:SetJustifyH("LEFT")
	self.trailing = self:CreateFontString(nil, "OVERLAY")
	self.trailing:SetFontObject(T.Typography:Get("labelSmall", true))
	self:SetScript("OnEnter", function() self.hovered = true; self:Paint() end)
	self:SetScript("OnLeave", function() self.hovered = false; self:Paint() end)
	self:SetScript("OnClick", function() self.list:OnRowClick(self) end)
	self.isTonicRow = true
end

function RowMixin:Init(list, data)
	if not self.isTonicRow then Mixin(self, RowMixin); self:Setup() end
	self.list, self.data = list, data
	local left = data.icon and 56 or 16
	self.icon:SetShown(data.icon ~= nil)
	if data.icon then
		self.icon:Update({ name = data.icon, size = 24 })
		self.icon:ClearAllPoints()
		T.Scale:SetPoint(self.icon, "LEFT", self, "LEFT", 16, 0)
	end
	self.headline:SetText(data.headline or "")
	self.supporting:SetText(data.supporting or "")
	self.supporting:SetShown(data.supporting ~= nil)
	self.trailing:SetText(data.trailing or "")
	self.trailing:ClearAllPoints()
	T.Scale:SetPoint(self.trailing, "RIGHT", self, "RIGHT", -24, 0)
	self.headline:ClearAllPoints()
	self.supporting:ClearAllPoints()
	if data.supporting then
		T.Scale:SetPoint(self.headline, "BOTTOMLEFT", self, "LEFT", left, 1)
		T.Scale:SetPoint(self.supporting, "TOPLEFT", self, "LEFT", left, -1)
		T.Scale:SetPoint(self.supporting, "RIGHT", self, "RIGHT", -64, 0)
	else
		T.Scale:SetPoint(self.headline, "LEFT", self, "LEFT", left, 0)
	end
	T.Scale:SetPoint(self.headline, "RIGHT", self, "RIGHT", -64, 0)
	self:Paint()
end

function RowMixin:Paint()
	local theme = self.list and self.list.theme
	if not theme then return end
	T.Shape:Apply(self.selectedFill, self, "none")
	self.stateLayer:Layout("none")
	local selected = self.list.props.selectable and self.list.selectedData == self.data
	self.selectedFill:SetShown(selected and true or false)
	self.selectedFill:SetColor(theme:RGB("secondaryContainer"))
	self.stateLayer:Paint(theme, "onSurface", self.hovered and "hover" or nil)
	self.headline:SetTextColor(theme:RGB(selected and "onSecondaryContainer" or "onSurface"))
	self.supporting:SetTextColor(theme:RGB("onSurfaceVariant"))
	self.trailing:SetTextColor(theme:RGB("onSurfaceVariant"))
	self.icon:SetColor(theme:RGB("onSurfaceVariant"))
end

-- ------------------------------------------------------------- list

---@class TonicList: TonicComponent
local ListMixin = {}

function ListMixin:Build()
	self.scrollBox = CreateFrame("Frame", nil, self, "WowScrollBoxList")
	self.scrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar")
	self.scrollBox:SetPoint("TOPLEFT")
	self.scrollBox:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 0)
	self.scrollBar:SetPoint("TOPLEFT", self.scrollBox, "TOPRIGHT", 2, 0)
	self.scrollBar:SetPoint("BOTTOMLEFT", self.scrollBox, "BOTTOMRIGHT", 2, 0)
	self.view = CreateScrollBoxListLinearView()
	self.view:SetElementInitializer("Button", function(row, data) RowMixin.Init(row, self, data) end)
	ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.view)
	ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.scrollBox, self.scrollBar)
end

function ListMixin:Layout()
	local p = self.props
	T.Scale:SetSize(self, p.width or 320, p.height or 280)
	local twoLine = false
	for _, item in ipairs(p.items or {}) do
		if item.supporting then twoLine = true break end
	end
	self.view:SetElementExtent(T.Scale:Dp(twoLine and 72 or 56, self))
	self.scrollBox:SetDataProvider(CreateDataProvider(p.items or {}))
end

function ListMixin:Render(theme)
	self.scrollBox:ForEachFrame(function(row) if row.Paint then row:Paint() end end)
end

function ListMixin:OnRowClick(row)
	if self.props.selectable then
		self.selectedData = row.data
		self:Refresh()
	end
	if self.props.onSelect then
		local index = self.scrollBox:GetDataProvider():FindIndex(row.data)
		self.props.onSelect(self, row.data, index)
	end
end

function ListMixin:OnRelease()
	self.selectedData = nil
	self.scrollBox:SetDataProvider(CreateDataProvider({}))
end

T:DefineComponent("List", { mixin = ListMixin, frameType = "Frame", interactive = false })
