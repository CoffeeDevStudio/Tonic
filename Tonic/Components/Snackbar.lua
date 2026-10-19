-- M3 snackbar: inverseSurface, shape XS, bottom center, optional action; queued.
--   T.Snackbar:Show("Profile saved", { action = "Undo", onAction = fn, duration = 4 })

local T = Tonic

---@class TonicSnackbar
local Snackbar = {}
T.Snackbar = Snackbar

local queue = {}
local frame, message, action, timer, showing

local function ensureFrames()
	if frame then return end
	frame = T.Surface:Acquire(UIParent, { color = "inverseSurface", shape = "xs" })
	frame:SetFrameStrata("TOOLTIP")
	frame:EnableMouse(true)
	frame:Hide()
	message = T.Text:Acquire(frame, { role = "bodyMedium", color = "inverseOnSurface", wrap = true, maxLines = 2 })
	action = T.Button:Acquire(frame, { variant = "inverseText", text = "" })
end

local function nextInQueue()
	showing = nil
	if #queue > 0 then Snackbar:Display(table.remove(queue, 1)) end
end

---Queues a message. opts: action (text), onAction, duration (seconds, default 4).
---@param text string
---@param opts? { action: string?, onAction: fun()?, duration: number? }
function Snackbar:Show(text, opts)
	local entry = { text = text, opts = opts or {} }
	if showing then
		queue[#queue + 1] = entry
	else
		self:Display(entry)
	end
end

function Snackbar:Display(entry)
	ensureFrames()
	showing = entry
	local opts = entry.opts
	local hasAction = opts.action ~= nil
	action:SetShown(hasAction)
	local actionW = 0
	if hasAction then
		action:Update({ text = opts.action, onClick = function()
			Snackbar:Dismiss()
			if opts.onAction then opts.onAction() end
		end })
		actionW = action:GetWidth() / T.Scale.density + 8
	end
	local width = math.min(568, math.max(344, 32 + actionW + 280))
	message:Update({ text = entry.text, width = width - 32 - actionW })
	local height = math.max(48, message:GetStringHeight() / T.Scale.density + 28)
	frame:Update({ width = width, height = height })
	frame:ClearAllPoints()
	T.Scale:SetPoint(frame, "BOTTOM", UIParent, "BOTTOM", 0, 96)
	message:ClearAllPoints()
	T.Scale:SetPoint(message, "LEFT", frame, "LEFT", 16, 0)
	if hasAction then
		action:SetFrameLevel(frame:GetFrameLevel() + 2)
		action:SyncLevels()
		action:ClearAllPoints()
		T.Scale:SetPoint(action, "RIGHT", frame, "RIGHT", -8, 0)
	end
	frame:Show()
	frame:SetAlpha(0)
	T.Motion:Tween("short4", "emphasizedDecelerate", function(p) frame:SetAlpha(p) end)
	if timer then timer:Cancel() end
	timer = C_Timer.NewTimer(opts.duration or 4, function() Snackbar:Dismiss() end)
end

function Snackbar:Dismiss()
	if not showing then return end
	if timer then timer:Cancel(); timer = nil end
	T.Motion:Tween("short3", "emphasizedAccelerate", function(p) frame:SetAlpha(1 - p) end, function()
		frame:Hide()
		nextInQueue()
	end)
end
