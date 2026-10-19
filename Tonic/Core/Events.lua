-- Event bus: WoW events (one shared frame) and internal Tonic messages.
-- Handler lists are copy-on-write arrays, so dispatch allocates nothing and
-- (un)registering from inside a handler is safe.

local T = Tonic

---@class TonicEvents
local Events = {}
T.Events = Events

---@alias TonicHandler fun(owner: any, event: string, ...: any)|string

local eventHandlers = {}   ---@type table<string, table[]>
local messageHandlers = {} ---@type table<string, table[]>

local frame = CreateFrame("Frame")

local function add(map, name, owner, fn)
	local old = map[name] or {}
	local list = {}
	for i = 1, #old do
		if old[i].owner ~= owner then list[#list + 1] = old[i] end
	end
	list[#list + 1] = { owner = owner, fn = fn or name }
	map[name] = list
	return #old == 0
end

local function remove(map, name, owner)
	local old = map[name]
	if not old then return false end
	local list = {}
	for i = 1, #old do
		if old[i].owner ~= owner then list[#list + 1] = old[i] end
	end
	map[name] = #list > 0 and list or nil
	return map[name] == nil
end

local function dispatch(list, name, ...)
	if not list then return end
	for i = 1, #list do
		local h = list[i]
		local fn = h.fn
		if type(fn) == "string" then fn = h.owner[fn] end
		if fn then xpcall(fn, geterrorhandler(), h.owner, name, ...) end
	end
end

frame:SetScript("OnEvent", function(_, event, ...)
	dispatch(eventHandlers[event], event, ...)
end)

---Registers owner for a WoW event. fn defaults to owner[event].
---@param event string
---@param owner any
---@param fn? TonicHandler
function Events:RegisterEvent(event, owner, fn)
	if add(eventHandlers, event, owner, fn) then frame:RegisterEvent(event) end
end

---@param event string
---@param owner any
function Events:UnregisterEvent(event, owner)
	if remove(eventHandlers, event, owner) then frame:UnregisterEvent(event) end
end

---Registers owner for an internal message (e.g. "Tonic.ThemeChanged"). fn defaults to owner[message].
---@param message string
---@param owner any
---@param fn? TonicHandler
function Events:RegisterMessage(message, owner, fn)
	add(messageHandlers, message, owner, fn)
end

---@param message string
---@param owner any
function Events:UnregisterMessage(message, owner)
	remove(messageHandlers, message, owner)
end

---Sends an internal message to every listener.
---@param message string
function Events:SendMessage(message, ...)
	dispatch(messageHandlers[message], message, ...)
end
