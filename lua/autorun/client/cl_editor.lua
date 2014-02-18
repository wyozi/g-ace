
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

	gace.Editor:RunJavascript([[gaceSessions.open("]] .. id ..
		[[", {contentb: "]] .. content ..
		[[", defens: ]] .. tostring(defens) .. [[});]])
end
function gace.ReOpenSession(id)
	gace.Editor:RunJavascript([[
		gaceSessions.reopen("]] .. id .. [[");
	]])
end
function gace.CloseSession(id)
	gace.Editor:RunJavascript([[
		gaceSessions.close("]] .. id .. [[");
	]])
	if gace.OpenedSessionId == id then
		gace.OpenedSessionId = nil
		gace.SendRequest("colsetfile", {path=""})
	end
end

function gace.AskForInput(query, callback)
	gace.InputPanel.QueryString = query
	gace.InputPanel.InputCallback = callback

	gace.InputPanel.Input:RequestFocus()

	gace.InputPanel:Show()
end

gace.UIColors = {
	frame_bg = Color(29,31,33),

	tab_bg = Color(78,77,74),
	tab_bg_hover = Color(148,186,101),
	tab_bg_active = Color(39,144,176),

	filetree_bg = Color(29,31,33)
}

surface.CreateFont("EditorTabFont", {
	font = "Roboto",
	size = 14
})

local VGUI_EDITOR_TAB = {
	Init = function(self)
		self.CloseButton = vgui.Create("DImageButton", self)
		self.CloseButton:SetIcon("icon16/cancel.png")
		self.CloseButton.DoClick = function()
			self:CloseTab()
		end
	end,
	CloseTab = function(self, force)
		if not force and self.EditedNotSaved then
			local menu = DermaMenu()
			menu:AddOption("Unsaved changes. Are you sure you want to close the tab?", function()
				self:CloseTab(true)
			end):SetIcon("icon16/stop.png")
			menu:Open()
			return
		end
		gace.CloseSession(self.SessionId)
		self:Remove()
		table.RemoveByValue(gace.Tabs.Panels, self) -- uhh
		gace.Tabs:InvalidateLayout()
	end,
	PerformLayout = function(self)
		self.CloseButton:SetPos(self:GetWide() - 18, self:GetTall()/2-16/2)
		self.CloseButton:SetSize(16, 16)
	end,
	Paint = function(self, w, h)
		if self.Hovered then
			surface.SetDrawColor(gace.UIColors.tab_bg_hover)--52, 152, 219)
		elseif self.SessionId == gace.OpenedSessionId then
			surface.SetDrawColor(gace.UIColors.tab_bg_active)--44, 62, 80)
		else
			surface.SetDrawColor(gace.UIColors.tab_bg)--127, 140, 141)
		end
		surface.DrawRect(0, 0, w, h)

		draw.SimpleText(self.SessionId, "EditorTabFont", w-22, h/2, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	
		if self.EditedNotSaved then
			surface.SetDrawColor(HSVToColor(CurTime()*3, 0.5, 0.95))
			local lx, ly
			for x=0,w,5 do
				local y = h-2-math.sin(CurTime()*2+x)*2
				if lx then
					surface.DrawLine(lx, ly, x, y)
				end
				lx, ly = x, y
			end
		end

	end,
	Setup = function(self, id)
		self:SetText("")
		self.SessionId = id
		self:SetToolTip(id)

		surface.SetFont("EditorTabFont")
		local w = surface.GetTextSize(self.SessionId)

		self:SetWide(140)--math.min(w+34, 160))
	end,
	DoClick = function(self)
		gace.ReOpenSession(self.SessionId)
	end,
	DoRightClick = function(self)
		local menu = DermaMenu()
		menu:AddOption("Close", function() self:CloseTab() end)
		menu:Open()
	end,
}
VGUI_EDITOR_TAB = vgui.RegisterTable(VGUI_EDITOR_TAB, "DButton") 

function gace.GetTabFor(id)
	local thepanel
	for _,pnl in pairs(gace.Tabs.Panels) do
		if pnl.SessionId == id then thepanel = pnl end
	end
	return thepanel
end

function gace.CreateTab(id)
	if gace.GetTabFor(id) then return end

	local btn = vgui.CreateFromTable(VGUI_EDITOR_TAB, gace.Tabs)
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
	html:Dock(FILL)

	local url = "http://wyozi.github.io/g-ace/editor.html"
	if gacedevurl:GetString() ~= "" then
		url = gacedevurl:GetString()
	end
	
	html:OpenURL(url)

	html:AddFunction("gace", "SetOpenedSession", function(id)
		gace.OpenedSessionId = id
		gace.CreateTab(id)
		gace.SendRequest("colsetfile", {path=id})
	end)
	html:AddFunction("gace", "ReportLatestContent", function(content)
		gace.OpenedSessionContent = content
	end)
	html:AddFunction("gace", "SaveSession", function(content)
		gace.Save(gace.OpenedSessionId, content, function()
			local t = gace.GetTabFor(gace.OpenedSessionId)
			if t then t.EditedNotSaved = false end

			local tb = gace.OpenedSessionId:Split("/")
			local par = table.concat(tb, "/", 1, #tb-1)

			gace.List(par, function(_, _, payload)
				ListPath(par, payload.tree)
			end, true)
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

	local oldpaint = html.Paint
	html.Paint = function(self, w, h)
		if self:IsLoading() then
			surface.SetDrawColor(0, 0, 0)
			surface.DrawRect(0, 0, w, h)
			draw.SimpleText("Loading", "Trebuchet24", 10, 10)
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

	gace.Tabs = tabs

	local filetree = vgui.Create("DTree", frame)
	filetree.Paint = function(self, w, h)
		surface.SetDrawColor(gace.UIColors.filetree_bg)
		surface.DrawRect(0, 0, w, h)
	end
	filetree:Dock(LEFT)
	filetree:SetWide(200)

	-- Requests the server to update the whole filetree
	gace.filetree.RefreshPath(filetree, "")

	local html = gace.CreateHTMLPanel()
	html:SetParent(frame)

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
			{	text = "Self",
				fn = function()
					luadev.RunOnSelf(gace.OpenedSessionContent)
				end,
				enabled = function() return luadev ~= nil end,
				tt = "Hotkey in editor: F5"},
			{	text = "Server",
				fn = function()
					luadev.RunOnServer(gace.OpenedSessionContent)
				end,
				enabled = function() return luadev ~= nil end,
				tt = "Hotkey in editor: F6"},
			{	text = "Shared",
				fn = function()
					luadev.RunOnShared(gace.OpenedSessionContent)
				end,
				enabled = function() return luadev ~= nil end,
				tt = "Hotkey in editor: F7"},
			{ text = "", width = 10},
		}

		local x = 10
		for _,v in pairs(btns) do
			local btn = vgui.Create(v.fn and "DButton" or "DLabel", frame)
			btn:SetPos(x, 2)
			btn:SetSize(v.width or 60, 20)
			x = x + (v.width or 62)
			btn:SetText(v.text)

			if v.tt then btn:SetToolTip(v.tt) end

			if v.enabled and not v.enabled() then
				btn:SetEnabled(false)
			elseif v.fn then
				btn.DoClick = v.fn
			end
		end
	end

	frame:MakePopup()
end)

concommand.Add("g-ace-refresh", function()
	if IsValid(gace.Frame) then gace.Frame:Remove() end
	cookie.Set("gace-frame-x", "0")
	cookie.Set("gace-frame-y", "0")
	cookie.Set("gace-frame-w", "900")
	cookie.Set("gace-frame-h", "600")
end)