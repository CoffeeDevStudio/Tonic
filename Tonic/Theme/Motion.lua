-- M3 motion: easing curves, durations and the single shared ticker for every tween.
-- The ticker frame only has an OnUpdate while at least one tween is running.

local T = Tonic

---@class TonicMotion
local Motion = {
	-- Seconds.
	durations = {
		short1 = 0.05, short2 = 0.1, short3 = 0.15, short4 = 0.2,
		medium1 = 0.25, medium2 = 0.3, medium3 = 0.35, medium4 = 0.4,
		long1 = 0.45, long2 = 0.5, long3 = 0.55, long4 = 0.6,
	},
	-- Cubic bezier control points (x1, y1, x2, y2).
	curves = {
		linear = { 0, 0, 1, 1 },
		standard = { 0.2, 0, 0, 1 },
		standardDecelerate = { 0, 0, 0, 1 },
		standardAccelerate = { 0.3, 0, 1, 1 },
		emphasizedDecelerate = { 0.05, 0.7, 0.1, 1 },
		emphasizedAccelerate = { 0.3, 0, 0.8, 0.15 },
	},
	enabled = true,
}
T.Motion = Motion

local abs = math.abs

local function bezier(a1, a2, t)
	-- Bezier with P0 = 0, P3 = 1.
	local u = 1 - t
	return 3 * u * u * t * a1 + 3 * u * t * t * a2 + t * t * t
end

local function bezierSlope(a1, a2, t)
	local u = 1 - t
	return 3 * u * u * a1 + 6 * u * t * (a2 - a1) + 3 * t * t * (1 - a2)
end

---Evaluates an easing curve at progress x in 0..1.
---@param curve string|number[]
---@param x number
---@return number
function Motion.Ease(curve, x)
	if x <= 0 then return 0 end
	if x >= 1 then return 1 end
	local c = type(curve) == "table" and curve or Motion.curves[curve] or Motion.curves.standard
	local x1, y1, x2, y2 = c[1], c[2], c[3], c[4]
	-- Solve bezierX(t) = x: Newton, then bisection as a fallback.
	local t = x
	for _ = 1, 8 do
		local err = bezier(x1, x2, t) - x
		if abs(err) < 1e-5 then return bezier(y1, y2, t) end
		local slope = bezierSlope(x1, x2, t)
		if abs(slope) < 1e-6 then break end
		t = t - err / slope
	end
	local lo, hi = 0, 1
	t = x
	for _ = 1, 30 do
		local v = bezier(x1, x2, t)
		if abs(v - x) < 1e-5 then break end
		if v < x then lo = t else hi = t end
		t = (lo + hi) / 2
	end
	return bezier(y1, y2, t)
end

-- ------------------------------------------------------------- ticker

---@class TonicTween
---@field duration number
---@field curve string|number[]
---@field onUpdate fun(progress: number)
---@field onDone fun()?
---@field elapsed number

local active = {} ---@type table<TonicTween, boolean>
local ticker = CreateFrame("Frame")

local finished = {}

local function onUpdate(_, elapsed)
	for tween in pairs(active) do
		tween.elapsed = tween.elapsed + elapsed
		local x = tween.elapsed / tween.duration
		xpcall(tween.onUpdate, geterrorhandler(), Motion.Ease(tween.curve, x))
		if x >= 1 then
			active[tween] = nil
			finished[#finished + 1] = tween
		end
	end
	-- onDone runs after the loop: it may start new tweens.
	for i = 1, #finished do
		local done = finished[i].onDone
		finished[i] = nil
		if done then xpcall(done, geterrorhandler()) end
	end
	if next(active) == nil then ticker:SetScript("OnUpdate", nil) end
end

---Starts a tween. With motion disabled it jumps to the end.
---@param duration number|string seconds or a duration token
---@param curve string|number[]
---@param update fun(progress: number)
---@param done? fun()
---@return TonicTween
function Motion:Tween(duration, curve, update, done)
	local tween = {
		duration = type(duration) == "string" and self.durations[duration] or duration,
		curve = curve,
		onUpdate = update,
		onDone = done,
		elapsed = 0,
	}
	if not self.enabled or tween.duration <= 0 then
		update(1)
		if done then done() end
		return tween
	end
	update(0)
	active[tween] = true
	ticker:SetScript("OnUpdate", onUpdate)
	return tween
end

---Stops a tween where it is, without calling onDone.
---@param tween TonicTween?
function Motion:Cancel(tween)
	if tween then active[tween] = nil end
end
