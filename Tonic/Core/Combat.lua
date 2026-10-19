-- Combat lockdown queue: positioning and visibility of protected frames go through Defer.

local T = Tonic

---@class TonicCombat
local Combat = {}
T.Combat = Combat

local queue = {}   ---@type function[]
local keyed = {}   ---@type table<any, integer>

---Runs fn now if out of combat, otherwise queues it for PLAYER_REGEN_ENABLED.
---With a key, only the latest fn queued under that key runs (in the position of the first).
---@param fn function
---@param key? any
---@return boolean ranNow
function Combat:Defer(fn, key)
	if not InCombatLockdown() then
		fn()
		return true
	end
	if key ~= nil then
		local index = keyed[key]
		if index then
			queue[index] = fn
			return false
		end
		keyed[key] = #queue + 1
	end
	queue[#queue + 1] = fn
	return false
end

---@return integer
function Combat:GetNumQueued()
	return #queue
end

function Combat:PLAYER_REGEN_ENABLED()
	local pending = queue
	queue = {}
	wipe(keyed)
	for i = 1, #pending do
		xpcall(pending[i], geterrorhandler())
	end
end

T.Events:RegisterEvent("PLAYER_REGEN_ENABLED", Combat)
