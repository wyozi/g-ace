
function gace.OpenSession(content)
	content = content:Replace("\"", "\\\"")
	gace.Editor:RunJavascript([[
		var session = ace.createEditSession("]] .. content .. [[", "ace/mode/lua")
		editor.setSession(session);
	]])
end

local VGUI_EDITOR_TAB = {
	Paint = function(self, w, h)
		if self.Hovered then
			surface.SetDrawColor(50, 50, 50)
		else
			surface.SetDrawColor(0, 0, 0)
		end
		surface.DrawRect(0, 0, w, h)
	end
}
VGUI_EDITOR_TAB = vgui.RegisterTable(VGUI_EDITOR_TAB, "DButton") 

concommand.Add("g-ace", function()
	local frame = vgui.Create("DFrame")
	frame:SetSize(900, 500)
	frame:Center()

	gace.Frame = frame

	local tabs = vgui.Create("DHorizontalScroller", frame)
	tabs:Dock(TOP)

	for i=1,10 do
		local btn = vgui.CreateFromTable(VGUI_EDITOR_TAB, tabs)
		btn:SetText("Hello " .. i)
		tabs:AddPanel(btn)
	end

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
						gace.Fetch(ConstructName(filnode), function(_, _, payload)
							gace.OpenSession(payload.content)
						end)
					end
					filnode.Icon:SetImage("icon16/page.png")
				end
			end
		end

		for vfolder,vnode in pairs(payload.tree) do
			local vfolnode = filetree:AddNode(vfolder)
			AddTreeNode(vnode, vfolnode)
		end
	end, true)

	local html = vgui.Create("DHTML", frame)
	html:Dock(FILL)
	html:OpenURL("http://wyozi.github.io/g-ace/editor.html")

	gace.Editor = html

	frame:MakePopup()
end)