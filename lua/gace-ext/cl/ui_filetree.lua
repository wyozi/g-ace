gace.AddHook("AddPanels", "Editor_AddFileTree", function(frame, basepnl)
	local sb = basepnl:GetById("SideBar")

	gace.FileNodeTree = nil

	local scroll = vgui.Create("DScrollPanel")

	local filetree = vgui.Create("GAceTree")
	filetree:Dock(TOP)
	scroll:AddItem(filetree)

	sb:StorePanelId("FileTree", filetree)

	-- Requests the server to update the whole filetree immediately
	gace.filetree.RefreshPath(gace.GetOption("root_path"))

	sb:AddDocked("FileTreeScroll", scroll, FILL)
end)
