
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
	frame:SetSize(600, 400)
	frame:Center()

	local tabs = vgui.Create("DHorizontalScroller", frame)
	tabs:Dock(TOP)

	for i=1,10 do
		local btn = vgui.CreateFromTable(VGUI_EDITOR_TAB, tabs)
		btn:SetText("Hello " .. i)
		tabs:AddPanel(btn)
	end

	local filetree = vgui.Create("DTree", frame)
	filetree:Dock(LEFT)

	local html = vgui.Create("DHTML", frame)
	html:Dock(FILL)
	html:OpenURL("http://wyozi.github.io/g-ace/editor.html")

	frame:MakePopup()
end)