-- Custom pages of Tonic_Config: skins, profiles, about.

local T = Tonic
local L = T.L
local Config = T.Config
local R = Config.renderers

local STATUS_TEXT = {
	ok = "Active", error = "Error", waiting = "Waiting for its Blizzard addon",
	disabled = "Off (reload to apply)", pending = "Not applied yet",
	missing = "Frames missing in this patch: run the audit",
}

function R.skins(page)
	R.description(page, { label = L["Skins restyle Blizzard windows. Turning a skin off takes effect after reloading the interface."] })
	for _, def in ipairs(T.Skins:GetAll()) do
		local status = L[STATUS_TEXT[def.status] or def.status]
		if def.status == "waiting" and def.addon then status = status .. " (" .. def.addon .. ")" end
		R.toggle(page, {
			label = def.label or def.name,
			desc = (def.desc and (def.desc .. "  ·  ") or "") .. status,
			get = function() return T.Skins:IsEnabled(def.name) end,
			set = function(enabled)
				T.Skins:SetEnabled(def.name, enabled)
				T.Snackbar:Show(L["Reload the interface to apply."], { action = L["Reload"], onAction = ReloadUI })
			end,
		})
	end
	if #T.Skins:GetAll() == 0 then
		R.description(page, { label = L["No skins registered (is Tonic_Skins enabled?)."] })
	end
	R.header(page, { label = L["Tools"] })
	R.button(page, { label = L["Audit"], desc = L["Checks that the frames each skin expects still exist."],
		text = L["Run audit"], icon = "search", onClick = function() SlashCmdList.TONIC("audit") end })
	R.button(page, { label = L["Reload interface"], text = L["Reload"], icon = "refresh", onClick = ReloadUI })
end

local function profileChoices(excludeCurrent)
	local choices = {}
	for _, name in ipairs(T.DB:GetProfiles()) do
		if not (excludeCurrent and name == T.DB:GetProfileName()) then
			choices[#choices + 1] = { value = name, label = name }
		end
	end
	return choices
end

local function confirm(title, text, action, run)
	T.Dialog:Show({ title = title, text = text, icon = "warning", actions = {
		{ text = L["Cancel"] },
		{ text = action, onClick = run },
	} })
end

function R.profiles(page)
	R.description(page, { label = L["Profiles store the appearance and skin settings. Each character can use its own."] })
	R.select(page, {
		label = L["Current profile"],
		get = function() return T.DB:GetProfileName() end,
		set = function(name) T.DB:SetProfile(name) end,
		choices = function() return profileChoices(false) end,
	})

	-- New profile: text field + button.
	local field
	local create = function()
		local name = field and field:GetText() or ""
		name = name:gsub("^%s+", ""):gsub("%s+$", "")
		if name == "" then
			field:Update({ error = L["Enter a name."] })
			return
		end
		T.DB:SetProfile(name)
		T.Snackbar:Show(L["Profile created:"] .. " " .. name)
	end
	field = T.TextField:Acquire(page.parent, { label = L["New profile"], variant = "outlined",
		background = "surfaceContainerLow", width = 240, maxLetters = 48,
		onChange = function(self) if self.props.error then self:Update({ error = false }) end end,
		onSubmit = create })
	local button = T.Button:Acquire(page.parent, { text = L["Create"], variant = "tonal", icon = "add", onClick = create })
	page:Row({ label = L["New profile"], desc = L["Creates an empty profile and switches to it."] }, button, 40)
	field:ClearAllPoints()
	T.Scale:SetPoint(field, "RIGHT", button, "LEFT", -12, 0)
	page:Track(field)

	local others = profileChoices(true)
	if #others > 0 then
		R.select(page, {
			label = L["Copy from"], desc = L["Replaces the current profile with a copy of another one."],
			get = function() return nil end,
			set = function(name)
				confirm(L["Copy profile?"], L["The current profile will be replaced by"] .. " " .. name .. ".", L["Copy"],
					function() T.DB:CopyProfile(name); T.Snackbar:Show(L["Profile copied."]) end)
			end,
			choices = function() return profileChoices(true) end,
		})
		R.select(page, {
			label = L["Delete"], desc = L["Characters using it go back to Default."],
			get = function() return nil end,
			set = function(name)
				confirm(L["Delete profile?"], name .. ": " .. L["this can't be undone."], L["Delete"],
					function() T.DB:DeleteProfile(name); Config:Rebuild(); T.Snackbar:Show(L["Profile deleted."]) end)
			end,
			choices = function() return profileChoices(true) end,
		})
	end
	R.button(page, { label = L["Reset profile"], desc = L["Restores the defaults of the current profile."],
		text = L["Reset"], icon = "refresh", variant = "outlined", onClick = function()
			confirm(L["Reset profile?"], L["All settings of this profile go back to the defaults."], L["Reset"],
				function() T.DB:ResetProfile(); T.Snackbar:Show(L["Profile reset."]) end)
		end })
end

function R.about(page)
	-- One logo, reused on every visit.
	Config.aboutLogo = Config.aboutLogo or T.Logo:Create(page.parent, 96)
	local logo = Config.aboutLogo
	logo:ClearAllPoints()
	T.Scale:SetPoint(logo, "TOPLEFT", page.parent, "TOPLEFT", 0, -page.y)
	logo:SetFrameLevel(page.parent:GetFrameLevel() + 2)
	logo:Show()
	page:Track({ Release = function() logo:Hide() end })
	local top = page.y
	page.y = top + 8
	page:Text({ role = "displaySmall", color = "onSurface", text = "Tonic" }, 120)
	page.y = top + 56
	page:Text({ role = "bodyLarge", color = "onSurfaceVariant", text = L["Material 3 for WoW · your UI in your class colors"] }, 120)
	page.y = top + 80
	page:Text({ role = "labelLarge", color = "primary", numeric = true, text = L["Version"] .. " " .. T.version }, 120)
	page.y = top + 120
	R.description(page, { label = L["Tonic restyles the World of Warcraft interface following Material Design 3. Dynamic color takes your class color as its seed; skins, components and the theme are a framework other addons can use through LibStub(\"Tonic-1.0\")."] })
	R.button(page, { label = L["Gallery"], desc = L["Every token and component, dark and light."], text = L["Open"],
		icon = "palette", onClick = function() T:GetModule("Gallery"):Toggle() end })
	R.header(page, { label = L["Credits"] })
	R.description(page, { label = "Material Design 3 · @material/material-color-utilities · Roboto Serif, Roboto Flex, Material Symbols (SIL OFL 1.1)" })
end
