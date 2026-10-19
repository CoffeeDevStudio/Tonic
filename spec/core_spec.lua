local wow = require("spec.helpers.wow")

describe("Combat", function()
	local T

	before_each(function()
		T = wow.LoadAddon()
	end)

	it("runs immediately out of combat", function()
		local ran = false
		assert.is_true(T.Combat:Defer(function() ran = true end))
		assert.is_true(ran)
	end)

	it("queues in combat and flushes on PLAYER_REGEN_ENABLED", function()
		wow.combat = true
		local order = {}
		T.Combat:Defer(function() order[#order + 1] = "a" end)
		T.Combat:Defer(function() order[#order + 1] = "b" end)
		assert.are.equal(2, T.Combat:GetNumQueued())
		wow.combat = false
		wow.Fire("PLAYER_REGEN_ENABLED")
		assert.are.same({ "a", "b" }, order)
		assert.are.equal(0, T.Combat:GetNumQueued())
	end)

	it("keeps only the latest function for a key", function()
		wow.combat = true
		local value
		T.Combat:Defer(function() value = 1 end, "pos")
		T.Combat:Defer(function() value = 2 end, "pos")
		assert.are.equal(1, T.Combat:GetNumQueued())
		wow.combat = false
		wow.Fire("PLAYER_REGEN_ENABLED")
		assert.are.equal(2, value)
	end)

	it("isolates errors of queued functions", function()
		wow.combat = true
		local ran = false
		T.Combat:Defer(function() error("boom") end)
		T.Combat:Defer(function() ran = true end)
		wow.combat = false
		wow.Fire("PLAYER_REGEN_ENABLED")
		assert.is_true(ran)
		assert.are.equal(1, #wow.errors)
	end)
end)

describe("Pool", function()
	it("reuses released objects and resets them", function()
		local T = wow.LoadAddon()
		local created, resets = 0, 0
		local pool = T.CreatePool(function() created = created + 1; return {} end, function() resets = resets + 1 end)
		local a = pool:Acquire()
		pool:Release(a)
		local b, isNew = pool:Acquire()
		assert.are.equal(a, b)
		assert.is_false(isNew)
		assert.are.equal(1, created)
		assert.are.equal(1, resets)
		assert.is_false(pool:Release({}))
	end)
end)

describe("Events", function()
	it("delivers messages and allows unregistering inside a handler", function()
		local T = wow.LoadAddon()
		local owner, calls = {}, 0
		T.Events:RegisterMessage("Test.Msg", owner, function(self, msg, arg)
			calls = calls + 1
			assert.are.equal(owner, self)
			assert.are.equal("Test.Msg", msg)
			assert.are.equal(42, arg)
			T.Events:UnregisterMessage("Test.Msg", self)
		end)
		T.Events:SendMessage("Test.Msg", 42)
		T.Events:SendMessage("Test.Msg", 42)
		assert.are.equal(1, calls)
	end)
end)

describe("Motion", function()
	local T

	before_each(function()
		T = wow.LoadAddon()
	end)

	it("maps the endpoints exactly", function()
		for name in pairs(T.Motion.curves) do
			assert.are.equal(0, T.Motion.Ease(name, 0))
			assert.are.equal(1, T.Motion.Ease(name, 1))
		end
	end)

	it("is monotonic for the standard curve", function()
		local last = 0
		for i = 1, 100 do
			local v = T.Motion.Ease("standard", i / 100)
			assert.is_true(v >= last - 1e-6)
			last = v
		end
	end)

	it("is linear for the linear curve", function()
		assert.is_true(math.abs(T.Motion.Ease("linear", 0.3) - 0.3) < 1e-4)
	end)
end)

describe("Scale", function()
	it("snaps dp to whole physical pixels", function()
		local T = wow.LoadAddon()
		local px = T.Scale:PixelSize()
		assert.is_true(math.abs(px - 768 / 1080) < 1e-9)
		local v = T.Scale:Dp(10)
		local pixels = v / px
		assert.is_true(math.abs(pixels - math.floor(pixels + 0.5)) < 1e-9)
		assert.are.equal(px, T.Scale:Dp(0.1))
		assert.are.equal(0, T.Scale:Dp(0))
	end)
end)
