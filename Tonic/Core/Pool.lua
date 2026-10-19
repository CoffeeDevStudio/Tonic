-- Generic object pool. Every dynamic frame/region in Tonic is acquired from a pool.

local T = Tonic

---@class TonicPool
---@field create fun(pool: TonicPool): any
---@field reset fun(pool: TonicPool, obj: any)?
---@field free any[]
---@field active table<any, boolean>
local PoolMixin = {}

---@return any obj
---@return boolean isNew
function PoolMixin:Acquire()
	local n = #self.free
	local obj, isNew
	if n > 0 then
		obj = self.free[n]
		self.free[n] = nil
		isNew = false
	else
		obj = self.create(self)
		isNew = true
	end
	self.active[obj] = true
	return obj, isNew
end

---@param obj any
---@return boolean released false if obj was not active in this pool
function PoolMixin:Release(obj)
	if not self.active[obj] then return false end
	self.active[obj] = nil
	if self.reset then self.reset(self, obj) end
	self.free[#self.free + 1] = obj
	return true
end

function PoolMixin:ReleaseAll()
	for obj in pairs(self.active) do self:Release(obj) end
end

---@return number
function PoolMixin:GetNumActive()
	local n = 0
	for _ in pairs(self.active) do n = n + 1 end
	return n
end

---Creates a new pool.
---@param create fun(pool: TonicPool): any
---@param reset? fun(pool: TonicPool, obj: any)
---@return TonicPool
function T.CreatePool(create, reset)
	local pool = setmetatable({ create = create, reset = reset, free = {}, active = {} }, { __index = PoolMixin })
	return pool
end
