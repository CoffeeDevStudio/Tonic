-- Text: a FontString bound to a type role and a theme color.
-- Contract: :ApplyTheme(theme), :SetState(state), :Update(props), :Release().
-- Text values are only forwarded to SetText, never read: safe for secret values.
--
--   local label = T.Text:Acquire(parent, { role = "titleMedium", color = "onSurface", text = "Bags" })

local T = Tonic

---@class TonicTextProps
---@field role string? type role (default "bodyMedium")
---@field color string? theme color name (default "onSurface")
---@field text string? forwarded to SetText
---@field numeric boolean? tabular digits
---@field justifyH JustifyH?
---@field justifyV JustifyV?
---@field wrap boolean? word wrap (default false)
---@field maxLines integer?
---@field width number? dp
---@field alpha number? content emphasis, e.g. 0.38
---@field layer DrawLayer? default "OVERLAY"
---@field theme TonicTheme? pinned theme: not registered with the ThemeManager

---@class TonicText: FontString
---@field props TonicTextProps
---@field theme TonicTheme?
---@field state string?
local TextMixin = {}

function TextMixin:Render()
	local p = self.props
	local role = p.role or "bodyMedium"
	self:SetFontObject(T.Typography:Get(role, p.numeric))
	self:SetJustifyH(p.justifyH or "LEFT")
	self:SetJustifyV(p.justifyV or "MIDDLE")
	self:SetWordWrap(p.wrap or false)
	self:SetMaxLines(p.maxLines or 0)
	-- M3 line height through the spacing between lines.
	local spacing = T.Typography:LineHeight(role) - T.Typography:Size(role)
	self:SetSpacing(p.wrap and T.Scale:Dp(spacing, self) or 0)
	if p.width then self:SetWidth(T.Scale:Dp(p.width, self)) end
	if p.text ~= nil then self:SetText(p.text) end
end

---@param theme TonicTheme
function TextMixin:ApplyTheme(theme)
	self.theme = theme
	local r, g, b = theme:RGB(self.props.color or "onSurface")
	local alpha = self.props.alpha or 1
	if self.state == "disabled" then
		-- M3 disabled content: onSurface at 38%.
		r, g, b = theme:RGB("onSurface")
		alpha = T.Color.STATE.disabledContent
	end
	self:SetTextColor(r, g, b, alpha)
end

---@param state string? nil or "disabled" (other states do not change text)
function TextMixin:SetState(state)
	self.state = state
	if self.theme then self:ApplyTheme(self.theme) end
end

---@param props TonicTextProps
function TextMixin:Update(props)
	for k, v in pairs(props) do self.props[k] = v end
	self:Render()
	if props.theme then
		T.Theme:Unregister(self)
		self:ApplyTheme(props.theme)
	elseif self.theme then
		self:ApplyTheme(self.theme)
	end
end

function TextMixin:Release()
	T.Text.pool:Release(self)
end

-- ------------------------------------------------------------- factory

---@class TonicTextFactory
local Text = {}
T.Text = Text

local host = CreateFrame("Frame")
host:Hide()

Text.pool = T.CreatePool(function()
	local fs = host:CreateFontString(nil, "OVERLAY")
	Mixin(fs, TextMixin)
	return fs
end, function(_, fs)
	T.Theme:Unregister(fs)
	fs:Hide()
	fs:ClearAllPoints()
	fs:SetText("")
	fs:SetParent(host)
	fs.theme, fs.state, fs.props = nil, nil, nil
end)

---Acquires a text from the pool.
---@param parent Frame
---@param props? TonicTextProps
---@return TonicText
function Text:Acquire(parent, props)
	local fs = self.pool:Acquire()
	fs.props = {}
	for k, v in pairs(props or {}) do fs.props[k] = v end
	fs:SetParent(parent)
	fs:SetDrawLayer(fs.props.layer or "OVERLAY")
	fs:Render()
	if fs.props.theme then
		fs:ApplyTheme(fs.props.theme)
	else
		T.Theme:Register(fs)
	end
	fs:Show()
	return fs
end
