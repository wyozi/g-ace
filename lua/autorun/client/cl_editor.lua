
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
function gace.ReOpenSession(id)
	gace.RunEditorJS([[
		gaceSessions.reopen("]] .. id .. [[");
	]])
end
function gace.CloseSession(id)
	gace.RunEditorJS([[
		gaceSessions.close("]] .. id .. [[");
	]])
	if gace.OpenedSessionId == id then
		gace.OpenedSessionId = nil
		gace.OpenedSessionContent = nil
	end

	local my_collab = gace.CollabPositions[LocalPlayer()]
	if my_collab == id then
		gace.SendRequest("colsetfile", {path=""})
	end
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

	local oldthink = frame.Think
	function frame:Think()
		if input.IsKeyDown(KEY_ESCAPE) and gaceclosewithesc:GetBool() then
			self:SetVisible(false)

			if gui.IsGameUIVisible () then
				gui.HideGameUI ()
			else
				gui.ActivateGameUI ()
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

	local url = "http://wyozi.github.io/g-ace/editor.html"
	if gacedevurl:GetString() ~= "" then
		url = gacedevurl:GetString()
	end
	
	html:OpenURL(url)

	html:AddFunction("gace", "SetOpenedSession", function(id, content)
		gace.OpenedSessionId = id
		gace.OpenedSessionContent = content

		gace.CreateTab(id)
	end)
	html:AddFunction("gace", "ReportLatestContent", function(content)
		gace.OpenedSessionContent = content

		local my_collab = gace.CollabPositions[LocalPlayer()]
		if my_collab ~= gace.OpenedSessionId then
			-- This might get called multiple times if player types a lot before new collab file
			-- is broadcasted, but sending packets isn't that expensive.
			--  TODO this might get spammed if user is not allowed to receive their own collab packets
			gace.SendRequest("colsetfile", {path=gace.OpenedSessionId})
		end
	end)
	html:AddFunction("gace", "SaveSession", function(content)
		gace.Save(gace.OpenedSessionId, content, function(_, _, pl)
			if pl.err then
				local better_err = pl.err
				if better_err == "Inexistent virtual folder" then
					better_err = "Trying to save to root. Try to save inside a folder instead."
				end
				return MsgN("Unable to save: ", better_err)
			end
			local t = gace.GetTabFor(gace.OpenedSessionId)
			if t then t.EditedNotSaved = false end

			local tb = gace.OpenedSessionId:Split("/")
			local par = table.concat(tb, "/", 1, #tb-1)

			gace.filetree.RefreshPath(filetree, par)
		end)
	end)
	html:AddFunction("gace", "SetEditedNotSaved", function(b)
		local t = gace.GetTabFor(gace.OpenedSessionId)
		if t then t.EditedNotSaved = b end
	end)
	html:AddFunction("gace", "CallLDFunc", function(ldf, content)
		luadev[ldf](content)
	end)
	html:AddFunction("gace", "NewSession", function(name)
		gace.OpenSession(name, "")
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

	html:AddFunction("gace", "EditorReady", function()
		local c_theme = cookie.GetString("gace-theme")
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

	return html
end

concommand.Add("g-ace", function()

	if IsValid(gace.Frame) then
		if gace.Frame:IsVisible() then return end
		gace.Frame:Show()
		gace.SendRequest("colsetfile", {path=gace.OpenedSessionId})
		return
	end

	-- Clear some session variables that might've gotten cached
	gace.OpenedSessionId = nil
	gace.FileNodeTree = nil

	local frame = gace.CreateFrame()

		gace.Frame = frame

	local tabs = vgui.Create("DHorizontalScroller", frame)
		tabs:Dock(TOP)
		tabs:SetOverlap(-1)

		local tabsel = vgui.Create("GAceTabSelector", tabs)
		tabs:AddPanel(tabsel)

		gace.Tabs = tabs

	local splitter = vgui.Create("GAceSplitter", frame)
	splitter:Dock(FILL)

		local filetree = vgui.Create("DTree")
			splitter:SetPanel(1, filetree)
			filetree.Paint = function(self, w, h)
				surface.SetDrawColor(gace.UIColors.frame_bg)
				surface.DrawRect(0, 0, w, h)
			end
			--filetree:Dock(LEFT)
			filetree:SetWide(200)

			-- Requests the server to update the whole filetree
			gace.filetree.RefreshPath(filetree, "")

		local html = gace.CreateHTMLPanel()
			splitter:SetPanel(2, html, 4)

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
			local btns = {
				{ text = "Run on", width = 40 },
				{
					text = "Self",
					fn = function()
						luadev.RunOnSelf(gace.OpenedSessionContent)
					end,
					enabled = function() return luadev ~= nil and gace.OpenedSessionContent end,
					tt = "Hotkey in editor: F5"
				},
				{
					text = "Server",
					fn = function()
						luadev.RunOnServer(gace.OpenedSessionContent)
					end,
					enabled = function() return luadev ~= nil and gace.OpenedSessionContent end,
					tt = "Hotkey in editor: F6"
				},
				{
					text = "Shared",
					fn = function()
						luadev.RunOnShared(gace.OpenedSessionContent)
					end,
					enabled = function() return luadev ~= nil and gace.OpenedSessionContent end,
					tt = "Hotkey in editor: F7"
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
						for _,theme in pairs(gace.AvailableThemes) do
							menu:AddOption(theme, function() gace.RunEditorJS("editor.setTheme('ace/theme/" .. theme .. "')") end)
						end
						menu:Open()
					end
				},
			}

			local x = 10
			for _,v in pairs(btns) do
				local is_label = not v.fn

				local comp = vgui.Create(is_label and "DLabel" or "GAceButton", frame)
				comp:SetPos(x, 2)
				comp:SetSize(v.width or 60, 20)
				x = x + (v.width or 60)+2
				comp:SetText(v.text)

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
					comp.DoClick = function(self, ...)
						if not self:GetDisabled() then
							v.fn(self, ...)
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
end)