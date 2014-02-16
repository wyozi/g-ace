
function gace.OpenSession(id, content)
	gace.Editor:RunJavascript([[gaceSessions.open("]] .. id ..
		[[", {contentb: "]] .. util.Base64Encode(content):Replace("\n", "") ..
		[["});]])
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
end

local VGUI_EDITOR_TAB = {
	Init = function(self)
		self.CloseButton = vgui.Create("DImageButton", self)
		self.CloseButton:SetIcon("icon16/cancel.png")
		self.CloseButton.DoClick = function()
			self:CloseTab()
		end
	end,
	CloseTab = function(self)
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
			surface.SetDrawColor(52, 152, 219)
		elseif self.SessionId == gace.OpenedSessionId then
			surface.SetDrawColor(44, 62, 80)
		else
			surface.SetDrawColor(127, 140, 141)
		end
		surface.DrawRect(0, 0, w, h)

		draw.SimpleText(self.SessionId, "Trebuchet18", 10, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end,
	Setup = function(self, id)
		self:SetText("")
		self.SessionId = id

		surface.SetFont("Trebuchet18")
		local w = surface.GetTextSize(self.SessionId)
		self:SetWide(w+30)
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

function gace.CreateTab(id)

	local thepanel
	for _,pnl in pairs(gace.Tabs.Panels) do
		if pnl.SessionId == id then thepanel = pnl end
	end

	if thepanel then return end

	local btn = vgui.CreateFromTable(VGUI_EDITOR_TAB, gace.Tabs)
	btn:Setup(id)
	gace.Tabs:AddPanel(btn)
end

local gacedevurl = CreateConVar("g-ace-devurl", "", FCVAR_ARCHIVE)

concommand.Add("g-ace", function()

	if IsValid(gace.Frame) then gace.Frame:Show() return end

	local frame = vgui.Create("DFrame")
	frame:SetSize(900, 500)
	frame:Center()
	frame:SetDeleteOnClose(false)

	gace.Frame = frame

	local tabs = vgui.Create("DHorizontalScroller", frame)
	tabs:Dock(TOP)

	gace.Tabs = tabs

	local filetree = vgui.Create("DTree", frame)
	filetree:Dock(LEFT)
	filetree:SetWide(200)

	local function ConstructName(node)
		local t = {node:GetText()}
		local p = node:GetParentNode()
		while p do
			if p:GetText() == "" then break end

			table.insert(t, p:GetText())
			p = p.GetParentNode and p:GetParentNode()
		end
		return table.concat(table.Reverse(t), "/")
	end

	gace.List("", function(_, _, payload)
		local function AddTreeNode(node, par)
			par = par or filetree
			if node.fol then
				for foldnm,fold in pairs(node.fol) do
					local node = par:AddNode(foldnm)
					AddTreeNode(fold, node)
				end
			end
			if node.fil then
				for _,fil in pairs(node.fil) do
					local filnode = par:AddNode(fil)
					filnode.DoClick = function()
						local id = ConstructName(filnode)
						gace.Fetch(id, function(_, _, payload)
							gace.OpenSession(id, payload.content)
						end)
					end
					filnode.Icon:SetImage("icon16/page.png")
				end
			end
		end

		for vfolder,vnode in pairs(payload.tree) do
			local vfolnode = filetree:AddNode(vfolder)
			AddTreeNode(vnode, vfolnode)
			vfolnode:SetExpanded(true)
		end

	end, true)

	local html = vgui.Create("DHTML", frame)
	html:Dock(FILL)

	local url = "http://wyozi.github.io/g-ace/editor.html"
	if gacedevurl:GetString() ~= "" then
		url = gacedevurl:GetString()
	end
	
	html:OpenURL(url)

	html:AddFunction("gace", "SetOpenedSession", function(id)
		gace.OpenedSessionId = id
		gace.CreateTab(id)
	end)
	html:AddFunction("gace", "SaveSession", function(content)
		gace.Save(gace.OpenedSessionId, content)
	end)

	gace.Editor = html

	frame:MakePopup()
end)

concommand.Add("g-ace-refresh", function()
	if IsValid(gace.Frame) then gace.Frame:Remove() end
end)