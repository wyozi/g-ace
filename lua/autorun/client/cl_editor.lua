
-- IMPORTANT TO KNOW
-- Session id is equal to the path (the text in tab)
-- Id and path might be used interchangeably in code

function gace.RunEditorJS(code)
	gace.Editor:RunJavascript(code)
end

function gace.OpenSession(id, content, data)
	if content == "" then -- Using base64encode on empty string returns nil, thus this
		content = ""
	else
		content = util.Base64Encode(content):Replace("\n", "")
	end

	local defens = false
	if data then
		defens = data.defens or defens
	end

	gace.RunEditorJS([[gaceSessions.open("]] .. id ..
		[[", {contentb: "]] .. content ..
		[[", defens: ]] .. tostring(defens) .. [[});]])
end
function gace.OpenPath(id, callback)
	local tab = gace.GetTabFor(id)
	if tab then -- Tab exists, thus session exists, thus we can go to session directly without fetching contents
		gace.OpenSession(id, "") -- Contents not needed; OpenSession doesn't replace them anyway
		return
	end

	gace.Fetch(id, function(_, _, payload)
		if payload.err then
			return MsgN("[G-Ace] Can't open ", id, ": ", payload.err)
		end
		gace.OpenSession(id, payload.content)
		if callback then callback() end
	end)
end
function gace.ReOpenSession(id)
	gace.RunEditorJS([[
		gaceSessions.reopen("]] .. id .. [[");
	]])
end
function gace.CloseSession(id)
	gace.RunEditorJS([[
		gaceSessions.close("]] .. id .. [[");
	]])
	if gace.GetSessionId() == id then
		gace.ResetGaceSession()
	end

	local tab = gace.GetTabFor(id)
	if tab then
		local prev_tab = table.FindPrev(gace.Tabs.Panels, tab)
		local set_session
		if prev_tab and prev_tab.SessionId then
			set_session = prev_tab.SessionId
		end

		tab:Remove()
		table.RemoveByValue(gace.Tabs.Panels, tab) -- uhh, a hack
		gace.Tabs:InvalidateLayout()

		if set_session then
			gace.ReOpenSession(set_session)
		end
	end

	local my_collab = gace.CollabPositions[LocalPlayer()]
	if my_collab == id then
		gace.SendRequest("colsetfile", {path=""})
	end
end

function gace.GetSession()
	return gace.OpenedSession
end
function gace.ResetGaceSession()
	local t = {}
	gace.OpenedSession = t
	return t
end
function gace.GetSessionId()
	local sess = gace.GetSession()
	if sess then return sess.id end
end

-- Strips file extension and path from session id
function gace.GetExtlessSessionId()
	local sessid = gace.GetSessionId()
	if sessid then return string.StripExtension(gace.Path(sessid):GetFile()) end -- StripExtension = a builtin gmod function
end
function gace.GetSessionContent()
	local sess = gace.GetSession()
	if sess then return sess.content end
end
function gace.GetSessionMode()
	local sess = gace.GetSession()
	if sess then return sess.mode end
end

function gace.AskForInput(query, callback, default)
	gace.InputPanel.QueryString = query
	gace.InputPanel.InputCallback = callback

	gace.InputPanel.Input:SetText(default or "")
	gace.InputPanel.Input:RequestFocus()

	gace.InputPanel:Show()
end

gace.UIColors = {
	frame_bg = Color(29,31,33),
	frame_fg = Color(255, 255, 255),

	tab_fg = Color(255, 255, 255),
	tab_bg = Color(78,77,74),
	tab_bg_hover = Color(148,186,101),
	tab_bg_active = Color(39,144,176)
}

gace.AvailableThemes = {
	"ambiance", "chaos", "chrome", "clouds", "clouds_midnight", "cobalt",
	"crimson_editor", "dawn", "dreamweaver", "eclipse", "github", "idle_fingers",
	"katzenmilch", "kr", "kuroir", "merbivore", "merbivore_soft", "mono_industrial",
	"monokai", "pastel_on_dark", "solarized_dark", "solarized_light", "terminal",
	"textmate", "tomorrow", "tomorrow_night", "tomorrow_night_blue",
	"tomorrow_night_bright", "tomorrow_night_eighties", "twilight",
	"vibrant_ink", "xcode",
}

-- Components (DLabel or GAceButton) to be added to title bar
-- If table has "fn", it is a button, otherwise a label.
-- tt = tooltip
gace.TitleBarComponents = {
	{ text = "Run on", width = 40 },
	{
		text = "Self",
		fn = function()
			luadev.RunOnSelf(gace.GetSessionContent(), "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil and gace.GetSessionContent() end,
		tt = "Hotkey in editor: F5"
	},
	{
		text = "Server",
		fn = function()
			luadev.RunOnServer(gace.GetSessionContent(), "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil and gace.GetSessionContent() end,
		tt = "Hotkey in editor: F6"
	},
	{
		text = "Shared",
		fn = function()
			luadev.RunOnShared(gace.GetSessionContent(), "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil and gace.GetSessionContent() end,
		tt = "Hotkey in editor: F7"
	},
	{
		text = "Clients",
		fn = function()
			luadev.RunOnClients(gace.GetSessionContent(), "g-ace: " .. (gace.GetSessionId() or ""))
		end,
		enabled = function() return luadev ~= nil and gace.GetSessionContent() end
	},
	{
		text = "Player",
		fn = function()
			local menu = DermaMenu()
			for _,ply in pairs(player.GetAll()) do
				menu:AddOption(ply:Nick(), function()
					luadev.RunOnClient(gace.GetSessionContent(), ply, "g-ace: " .. (gace.GetSessionId() or ""))
				end)
			end
			menu:Open()
		end,
		enabled = function() return luadev ~= nil and gace.GetSessionContent() end
	},
	{
		text = "ULX Group",
		fn = function()
			local menu = DermaMenu()
			for group,_ in pairs(ULib.ucl.groups) do
				menu:AddOption(group, function()
					local targetplys = gace.FilterSeq(player.GetAll(), function(x) return x:IsUserGroup(group) end)
					luadev.RunOnClient(gace.GetSessionContent(), targetplys, "g-ace: " .. (gace.GetSessionId() or ""))
				end)
			end
			menu:Open()
		end,
		enabled = function() return luadev ~= nil and
									ULib ~= nil and
									ULib.ucl ~= nil and
									ULib.ucl.groups ~= nil and
									gace.GetSessionContent()
							end
	},

	{ text = "", width = 20 },
	{ text = "Custom", width = 40 },
	{
		text = "Reload mode",
		tt = "Reload mode compiles and runs code every time code changes. Useful for e.g. building HUDs.",
		width = 100,
		toggle = true,
		fn = function(state)
			local sess = gace.GetSession()
			if sess then sess.hbmode = state end
		end
	},
	{
		text = "Run as",
		fn = function(state)
			local menu = DermaMenu()

			menu:AddOption("Scripted weapon", function()
				local base = [[
local SWEP = {}
SWEP.Primary = {}
SWEP.Secondary = {}
%s
weapons.Register(SWEP, "%s", true)
				]]

				luadev.RunOnShared(
					string.format(base, gace.GetSessionContent(), gace.GetExtlessSessionId()),
					"g-ace swep: " .. (gace.GetSessionId() or "")
				)
			end)
			menu:AddOption("Scripted entity", function()
				local base = [[
local ENT = {}
ENT.Primary = {}
ENT.Secondary = {}
%s
scripted_ents.Register(ENT, "%s")
				]]

				luadev.RunOnShared(
					string.format(base, gace.GetSessionContent(), gace.GetExtlessSessionId()),
					"g-ace sent: " .. (gace.GetSessionId() or "")
				)
			end)

			menu:Open()
		end,
		enabled = function() return luadev ~= nil and gace.GetSessionContent() end,
		tt = "Runs the code as if it was a SWEP or a SENT"
	},

	{ text = "", width = 20 },
	{ text = "Editor", width = 35 },
	{
		text = "Settings",
		fn = function()
			gace.RunEditorJS("editor.showSettingsMenu();")
		end
	},
	{
		text = "Shortcuts",
		fn = function()
			gace.RunEditorJS("editor.showKeyboardShortcuts();")
		end,
		width = 75
	},
	{
		text = "Theme",
		fn = function()
			local menu = DermaMenu()

			local c_theme = cookie.GetString("gace-theme", "ace/theme/tomorrow_night") or "ace/theme/tomorrow_night"
			local theme_name = c_theme:Split("/")[3]

			for _,theme in pairs(gace.AvailableThemes) do
				local opt = menu:AddOption(theme, function() gace.RunEditorJS("editor.setTheme('ace/theme/" .. theme .. "')") end)
				if theme_name == theme then
					opt:SetChecked(true)
				end
			end
			menu:Open()
		end
	},
	{
		text = "Mode",
		fn = function()
			local menu = DermaMenu()

			local modes = {
				"abap", "actionscript", "ada", "apache_conf", "asciidoc", "assembly_x86", "autohotkey",
				"batchfile", "c9search", "c_cpp", "clojure", "cobol", "coffee", "coldfusion", "csharp",
				"css", "curly", "d", "dart", "diff", "django", "dot", "ejs", "erlang", "forth", "ftl",
				"glsl", "glua", "golang", "groovy", "haml", "handlebars", "haskell", "haxe", "html", "ini",
				"jack", "jade", "java", "javascript", "json","jsoniq", "jsp", "jsx", "julia", "latex", "less",
				"liquid", "lisp", "livescript", "logiql", "lsl", "lua", "luapage", "lucene", "makefile", "markdown",
				"matlab", "mel", "mushcode", "mysql", "nix", "objectivec", "ocaml", "pascal", "perl", "pgsql", "php",
				"plain_text", "powershell", "prolog", "properties", "protobuf", "python", "r", "rdoc", "rhtml", "ruby",
				"rust", "sass", "scad", "scala", "scheme", "scss", "sh", "sjs", "snippets", "soy_template", "space",
				"sql", "stylus", "svg", "tcl", "tex", "text", "textile", "tmsnippet", "toml", "twig", "typescript",
				"vbscript", "velocity", "verilog", "vhdl", "xml", "xquery", "yaml",
			}

			for _,mode in pairs(modes) do
				local mode2 = "ace/mode/" .. mode
				local opt = menu:AddOption(mode, function() gace.RunEditorJS("editor.getSession().setMode('" .. mode2 .. "')") end)
				if gace.GetSessionMode() == mode2 then
					opt:SetChecked(true)
				end
			end
			menu:Open()
		end
	},
}

surface.CreateFont("EditorTabFont", {
	font = "Roboto",
	size = 14
})

function gace.GetTabFor(id)
	local thepanel
	for _,pnl in pairs(gace.Tabs.Panels) do
		if pnl.SessionId == id then thepanel = pnl end
	end
	return thepanel
end

function gace.CreateTab(id)
	if gace.GetTabFor(id) then return end

	local btn = vgui.Create("GAceTab", gace.Tabs)
	btn:Setup(id)
	gace.Tabs:AddPanel(btn)
end

local gacedevurl = CreateConVar("g-ace-devurl", "", FCVAR_ARCHIVE)
local gaceclosewithesc = CreateConVar("g-ace-closewithesc", "1", FCVAR_ARCHIVE)

function gace.CreateFrame()
	local frame = vgui.Create("DFrame")
	frame:SetDeleteOnClose(false)
	frame:SetSizable(true)
	frame:SetTitle("")
	frame.OnClose = function()
		gace.SendRequest("colsetfile", {path=""})
	end
	frame.Paint = function(self, w, h)
		surface.SetDrawColor(gace.UIColors.frame_bg)--22, 31, 50)
		surface.DrawRect(0, 0, w, h)
	end

	local was_esc_down = false

	local oldthink = frame.Think
	function frame:Think()
		local is_esc_down = input.IsKeyDown(KEY_ESCAPE)
		local esc_pressed = is_esc_down ~= was_esc_down and is_esc_down
		was_esc_down = is_esc_down

		if esc_pressed then
			local function CancelGUIOpen()
				if gui.IsGameUIVisible () then
					gui.HideGameUI ()
				else
					gui.ActivateGameUI ()
				end
			end

			if gace.InputPanel:IsVisible() then
				gace.InputPanel:Hide()
				gace.Frame:InvalidateLayout()
				CancelGUIOpen()
			elseif gaceclosewithesc:GetBool() then
				self:SetVisible(false)
				CancelGUIOpen()
			end
		end
		oldthink(self)
	end

	local c_x, c_y, c_w, c_h = cookie.GetNumber("gace-frame-x"),
							   cookie.GetNumber("gace-frame-y"),
							   cookie.GetNumber("gace-frame-w"),
							   cookie.GetNumber("gace-frame-h")
	
	if c_w == 0 then c_w = 900 end
	if c_h == 0 then c_h = 600 end

	frame:SetSize(c_w, c_h)
	if c_x == 0 and c_y == 0 then
		frame:Center()
	else
		frame:SetPos(c_x, c_y)
	end

	timer.Create("gace-frame-cookies", 1, 0, function()
		if not IsValid(frame) then return end

		local x, y = frame:GetPos()
		local w, h = frame:GetSize()

		cookie.Set("gace-frame-x", x)
		cookie.Set("gace-frame-y", y)
		cookie.Set("gace-frame-w", w)
		cookie.Set("gace-frame-h", h)
	end)

	return frame
end

function gace.CreateHTMLPanel()
	local html = vgui.Create("DHTML")

	html:AddFunction("gace", "SetOpenedSession", function(id, content, mode)
		local sess = gace.ResetGaceSession()

		sess.id = id
		sess.content = content

		gace.CreateTab(id)
	end)
	html:AddFunction("gace", "ReportLatestContent", function(content)
		local sess = gace.GetSession()
		if sess then
			sess.content = content
			if sess.hbmode then
				local fn = CompileString(content, "g-ace hbmode code", false)
				if type(fn) == "string" then
					MsgN("[G-Ace] HBMode compilation failed: ", fn)
				elseif fn then
					fn()
				end
			end
		end

		local my_collab = gace.CollabPositions[LocalPlayer()]
		if my_collab ~= gace.GetSessionId() then
			-- This might get called multiple times if player types a lot before new collab file
			-- is broadcasted, but sending packets isn't that expensive.
			--  TODO this might get spammed if user is not allowed to receive their own collab packets
			gace.SendRequest("colsetfile", {path=gace.GetSessionId()})
		end
	end)
	html:AddFunction("gace", "SaveSession", function(content)
		-- If we're trying to save under root folder

		local initial_osi = gace.GetSessionId()

		local function SaveTo(path)
			gace.Save(path, content, function(_, _, pl)
				if pl.err then
					local better_err = pl.err
					if better_err == "Inexistent virtual folder" then
						better_err = "Trying to save to root. Try to save inside a folder instead."
					end
					return MsgN("Unable to save: ", better_err)
				end

				if path ~= initial_osi then
					gace.CloseSession(initial_osi)
					gace.OpenSession(path, content)
				end

				local t = gace.GetTabFor(path)
				if t then t.EditedNotSaved = false end

				gace.filetree.RefreshPath(filetree, gace.Path(path):WithoutFile():ToString())
			end)
		end

		if gace.Path(initial_osi):WithoutVFolder():IsRoot() then
			gace.AskForInput("Where to save? Must be absolute path (e.g. EpicJB/folder/file.txt) and must end in .txt", function(txt)
				SaveTo(txt)
			end)
			return
		end
		SaveTo(initial_osi)
	end)
	html:AddFunction("gace", "SetEditedNotSaved", function(b)
		local t = gace.GetTabFor(gace.GetSessionId())
		if t then t.EditedNotSaved = b end
	end)
	html:AddFunction("gace", "CallLDFunc", function(ldf, content)
		luadev[ldf](content)
	end)
	html:AddFunction("gace", "NewSession", function(name)
		gace.OpenSession(name, "")
	end)
	html:AddFunction("gace", "GracefullyCloseSession", function()
		local tab = gace.GetTabFor(gace.GetSessionId() or "")
		if tab then tab:CloseTab() end
	end)
	html:AddFunction("gace", "GotoPath", function(path, row, col)
		gace.OpenPath(path, function()
			gace.RunEditorJS("editor.moveCursorTo(" .. row .. ", " .. (col or 0) .. ");")
		end)
	end)

	local function RGBStringToColor(str)
		local r, g, b = string.match(str, "(%d+):(%d+):(%d+)")
		return Color(tonumber(r), tonumber(g), tonumber(b))
	end
	html:AddFunction("gace", "ThemeChanged", function(theme, bgColor, fgColor, gutterBgColor)
		gace.UIColors.frame_bg = RGBStringToColor(bgColor)
		gace.UIColors.frame_fg = RGBStringToColor(fgColor)

		gace.UIColors.tab_bg = RGBStringToColor(gutterBgColor)
		gace.UIColors.tab_fg = RGBStringToColor(fgColor)

		cookie.Set("gace-theme", theme)
	end)

	html:AddFunction("gace", "ModeChanged", function(mode)
		local sess = gace.GetSession()
		if sess then sess.mode = mode end
	end)

	html:AddFunction("gace", "EditorReady", function()
		local c_theme = cookie.GetString("gace-theme", "ace/theme/tomorrow_night") or "ace/theme/tomorrow_night"
		local the_theme = "ace/theme/tomorrow_night"
		if table.HasValue(gace.AvailableThemes, c_theme:Split("/")[3]) then
			the_theme = c_theme
		end
		gace.RunEditorJS("editor.setTheme('" .. the_theme .. "')")
	end)

	local oldpaint = html.Paint
	html.Paint = function(self, w, h)
		if self:IsLoading() then
			surface.SetDrawColor(gace.UIColors.frame_bg)
			surface.DrawRect(0, 0, w, h)
			draw.SimpleText("Loading", "Trebuchet24", 10, 10, gace.UIColors.frame_fg)
		else
			html.Paint = oldpaint
		end
	end

	local url = "http://wyozi.github.io/g-ace/editor.html"
	if gacedevurl:GetString() ~= "" then
		url = gacedevurl:GetString()
	end
	
	html:OpenURL(url)
	
	return html
end

concommand.Add("g-ace", function()

	if IsValid(gace.Frame) then
		if gace.Frame:IsVisible() then return end
		gace.Frame:Show()
		gace.SendRequest("colsetfile", {path=gace.GetSessionId()})
		return
	end

	-- Clear some session variables that might've gotten cached
	gace.FileNodeTree = nil
	gace.OpenedSession = nil

	local frame = gace.CreateFrame()

		gace.Frame = frame

	local tabs = vgui.Create("DHorizontalScroller", frame)
		tabs.Paint = function(self, w, h)
			local hh, s, v = ColorToHSV(gace.UIColors.frame_bg)
			surface.SetDrawColor(HSVToColor(hh, s, v-0.1))
			surface.DrawOutlinedRect(0, 0, w, h)
		end
		tabs:Dock(TOP)
		tabs:SetOverlap(-1)

		local tabsel = vgui.Create("GAceTabSelector", tabs)
		tabs:AddPanel(tabsel)

		gace.Tabs = tabs

	local divider = vgui.Create("DHorizontalDivider", frame)
		divider:Dock(FILL)
		divider:SetDividerWidth(4)
		divider:SetLeftWidth(cookie.GetNumber("gace-ftreewidth", 200))
		divider.Think = function(self)
			cookie.Set("gace-ftreewidth", self:GetLeftWidth())
		end

		local filetree = vgui.Create("DTree")
			divider:SetLeft(filetree)
			filetree.Paint = function(self, w, h)
				surface.SetDrawColor(gace.UIColors.frame_bg)
				surface.DrawRect(0, 0, w, h)
			end

			-- Requests the server to update the whole filetree
			gace.filetree.RefreshPath(filetree, "")

		local html = gace.CreateHTMLPanel()
			divider:SetRight(html)

			gace.Editor = html

	-- Input panel that can ask for input

	local inputpanel = vgui.Create("DPanel", frame)
		inputpanel:Dock(BOTTOM)
		inputpanel:Hide()

		gace.InputPanel = inputpanel

		do
			local input = vgui.Create("DTextEntry", inputpanel)
			input:Dock(FILL)
			inputpanel.Input = input

			input.PaintOver = function(self, w, h)
				if self:GetText() == "" then
					draw.SimpleText(inputpanel.QueryString or "bla bla bla", "DermaDefault", 4, h/2, Color(0, 0, 0, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				end
			end

			input.OnEnter = function(self)
				inputpanel.InputCallback(self:GetText())
				inputpanel:Hide()
				gace.Frame:InvalidateLayout()
			end
		end

		-- Action buttons that are in the title bar

		do
			local x = 10
			for _,v in pairs(gace.TitleBarComponents) do
				local is_label = not v.fn

				local comp = vgui.Create(is_label and "DLabel" or "GAceButton", frame)
				comp:SetPos(x, 2)
				comp:SetSize(v.width or 60, 20)
				x = x + (v.width or 60)+2
				comp:SetText(v.text)

				if v.toggle then comp.ToggleMode = true end

				if is_label then
					comp.Think = function(self) self:SetColor(gace.UIColors.frame_fg) end
				end

				if v.tt then comp:SetToolTip(v.tt) end

				if v.enabled and not v.enabled() then
					comp.Think = function(self)
						local b = v.enabled()
						-- Yes, this inverses enabled to disabled, blame Garry for weird naming
						self:SetDisabled(not b)
					end
				end

				if v.fn then
					comp.DoClick = function(self)
						if not self:GetDisabled() then
							if self.ToggleMode then
								self.Toggled = not self.Toggled
							end
							v.fn(self, self.Toggled)
						end
					end
				end
			end
		end

	frame:MakePopup()
end)

concommand.Add("g-ace-refresh", function()
	if IsValid(gace.Frame) then gace.Frame:Remove() end
end)

concommand.Add("g-ace-reset", function()
	if IsValid(gace.Frame) then gace.Frame:Remove() end
	cookie.Set("gace-frame-x", "0")
	cookie.Set("gace-frame-y", "0")
	cookie.Set("gace-frame-w", "900")
	cookie.Set("gace-frame-h", "600")
	cookie.Set("gace-theme", "tomorrow_night")
	cookie.Set("gace-ftreewidth", "200")
end)