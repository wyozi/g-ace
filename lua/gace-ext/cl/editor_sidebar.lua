gace.AddHook("AddPanels", "Editor_AddSideBar", function(frame, basepnl)
	local sb = basepnl:AddSubPanel("SideBar", LEFT)
	sb:SetWide(250)

	gace.FileNodeTree = nil

	local filetree = vgui.Create("DTree")
	filetree.Paint = function(self, w, h)
		surface.SetDrawColor(gace.UIColors.frame_bg)
		surface.DrawRect(0, 0, w, h)
	end

	-- Requests the server to update the whole filetree immediately
	gace.filetree.RefreshPath(filetree, "")

	sb:AddDocked("FileTree", filetree, FILL)
end) 