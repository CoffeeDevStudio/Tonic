local wow = require("spec.helpers.wow")

describe("DB", function()
	local T, DB

	before_each(function()
		T = wow.LoadAddon()
		DB = T.DB
	end)

	describe("MergeDefaults", function()
		it("fills missing keys deeply and keeps existing values", function()
			local target = { a = 1, nested = { x = "mine" } }
			DB.MergeDefaults(target, { a = 2, b = 3, nested = { x = "default", y = true } })
			assert.are.same({ a = 1, b = 3, nested = { x = "mine", y = true } }, target)
		end)

		it("copies default tables instead of sharing them", function()
			local defaults = { list = { 1, 2 } }
			local target = DB.MergeDefaults({}, defaults)
			target.list[1] = 99
			assert.are.equal(1, defaults.list[1])
		end)

		it("keeps a user value of a different type", function()
			local target = DB.MergeDefaults({ opt = false }, { opt = { enabled = true } })
			assert.are.equal(false, target.opt)
		end)
	end)

	describe("StripDefaults", function()
		it("removes values equal to the defaults and empty tables", function()
			local target = { a = 1, b = 5, nested = { x = "default" } }
			DB.StripDefaults(target, { a = 1, b = 3, nested = { x = "default" } })
			assert.are.same({ b = 5 }, target)
		end)

		it("is the inverse of MergeDefaults for untouched data", function()
			local defaults = { theme = { mode = "dark", hudOpacity = 0.88 } }
			local target = DB.MergeDefaults({}, defaults)
			assert.are.same({}, DB.StripDefaults(target, defaults))
		end)
	end)

	describe("RunMigrations", function()
		it("stamps a fresh install without migrating", function()
			local data = {}
			assert.are.equal(0, DB.RunMigrations(data, { [1] = error }, 3))
			assert.are.equal(3, data.schema)
		end)

		it("runs only the pending migrations, in order", function()
			local calls = {}
			local migrations = {
				[2] = function() calls[#calls + 1] = 2 end,
				[3] = function() calls[#calls + 1] = 3 end,
			}
			local data = { schema = 1 }
			assert.are.equal(2, DB.RunMigrations(data, migrations, 3))
			assert.are.same({ 2, 3 }, calls)
			assert.are.equal(3, data.schema)
		end)
	end)

	describe("profiles", function()
		it("creates the Default profile with defaults", function()
			assert.are.equal("Default", DB:GetProfileName())
			assert.are.equal("dark", T.db.profile.theme.mode)
			assert.are.equal("Default", TonicDB.profileKeys["Tester - Realm"])
		end)

		it("switches, copies and deletes profiles", function()
			T.db.profile.theme.mode = "light"
			DB:SetProfile("Raid")
			assert.are.equal("dark", T.db.profile.theme.mode)
			DB:CopyProfile("Default")
			assert.are.equal("light", T.db.profile.theme.mode)
			DB:SetProfile("Default")
			DB:DeleteProfile("Raid")
			assert.are.same({ "Default" }, DB:GetProfiles())
		end)

		it("strips defaults on logout", function()
			T.db.profile.theme.mode = "light"
			wow.Fire("PLAYER_LOGOUT")
			assert.are.same({ theme = { mode = "light" } }, TonicDB.profiles.Default)
		end)
	end)
end)
