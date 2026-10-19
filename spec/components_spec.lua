local wow = require("spec.helpers.wow")

describe("Components", function()
	local T, parent

	before_each(function()
		T = wow.LoadAddon()
		parent = CreateFrame("Frame")
	end)

	local FACTORIES = {
		Button = { text = "Save" }, IconButton = { icon = "close" }, FAB = { icon = "add", text = "New" },
		Card = { title = "Card", text = "Body" }, Switch = { checked = true }, Checkbox = { checked = true, text = "x" },
		Radio = { selected = true, text = "x" }, Slider = { value = 0.5 }, TextField = { label = "Name" },
		Tabs = { tabs = { { text = "A" }, { text = "B" } } }, List = { items = { { headline = "x" } } },
	}

	it("acquire, theme, every state and release without errors", function()
		for name, props in pairs(FACTORIES) do
			local factory = T[name]
			assert.is_not_nil(factory)
			local before = factory.pool:GetNumActive()
			local c = factory:Acquire(parent, props)
			for _, state in ipairs({ "hover", "focus", "pressed", "disabled" }) do c:SetState(state) end
			c:SetState(nil)
			c:Update({ disabled = true })
			T.Theme:SetMode("light")
			T.Theme:SetMode("dark")
			c:Release()
			assert.are.equal(before, factory.pool:GetNumActive())
		end
		assert.are.same({}, wow.errors)
	end)

	it("toggles a switch and reports the change", function()
		local changed
		local s = T.Switch:Acquire(parent, { checked = false, onChange = function(_, v) changed = v end })
		s:OnActivate()
		assert.is_true(changed)
		assert.is_true(s.props.checked)
	end)

	it("keeps one radio selected in a group", function()
		local group = {}
		local a = T.Radio:Acquire(parent, { group = group, value = "a", selected = true })
		local b = T.Radio:Acquire(parent, { group = group, value = "b" })
		b:OnActivate()
		assert.is_false(a.props.selected)
		assert.is_true(b.props.selected)
	end)

	it("cycles a checkbox from indeterminate to checked", function()
		local c = T.Checkbox:Acquire(parent, { checked = "indeterminate" })
		c:OnActivate()
		assert.is_true(c.props.checked)
	end)

	it("does not click disabled buttons", function()
		local clicks = 0
		local b = T.Button:Acquire(parent, { text = "x", disabled = true, onClick = function() clicks = clicks + 1 end })
		b:GetScript("OnClick")(b, "LeftButton")
		assert.are.equal(0, clicks)
		b:Update({ disabled = false })
		b:GetScript("OnClick")(b, "LeftButton")
		assert.are.equal(1, clicks)
	end)

	it("opens and closes menus, dialogs and snackbars", function()
		local chosen
		T.Menu:Open(parent, { { text = "A", onClick = function() chosen = "A" end }, { divider = true } })
		assert.is_true(T.Menu:IsOpen())
		T.Menu:Close()
		assert.is_false(T.Menu:IsOpen())
		T.Dialog:Show({ title = "T", text = "x", actions = { { text = "OK", onClick = function() chosen = "ok" end } } })
		assert.is_true(T.Dialog:IsShown())
		T.Dialog:Cancel()
		assert.is_false(T.Dialog:IsShown())
		T.Snackbar:Show("one")
		T.Snackbar:Show("two")
		wow.FlushTimers()
		assert.are.same({}, wow.errors)
		assert.is_nil(chosen)
	end)
end)

describe("Options", function()
	local T

	before_each(function()
		T = wow.LoadAddon()
	end)

	it("reads and writes dotted paths", function()
		local t = {}
		T.Options.SetPath(t, "a.b.c", 1)
		assert.are.equal(1, T.Options.GetPath(t, "a.b.c"))
		assert.is_nil(T.Options.GetPath(t, "a.x.c"))
	end)

	it("sets profile values and calls the setter", function()
		local called
		T.Options:AddCategory("test", { title = "Test" })
		local option = { type = "toggle", key = "theme.ripple", set = function(v) called = v end }
		T.Options:Add("test", option)
		T.Options:SetValue(option, false)
		assert.is_false(T.db.profile.theme.ripple)
		assert.is_false(called)
		assert.is_false(T.Options:GetValue(option))
	end)

	it("sorts categories by order", function()
		local ids = {}
		for i, c in ipairs(T.Options:GetCategories()) do ids[i] = c.id end
		assert.are.same({ "appearance", "skins", "profiles", "about" }, ids)
	end)
end)

describe("Tonic_Config", function()
	it("renders every category without errors", function()
		local T = wow.LoadAddon()
		SlashCmdList.TONIC("config")
		assert.is_not_nil(T.Config)
		for i = 1, #T.Options:GetCategories() do T.Config:ShowCategory(i) end
		T.DB:SetProfile("Second")
		T.Config:ShowCategory(3)
		assert.are.same({}, wow.errors)
	end)
end)
