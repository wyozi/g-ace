gace.AddHook("AddPanels", "Editor_AddFileTree", function(frame, basepnl)
	local sb = basepnl:GetById("SideBar")

	gace.FileNodeTree = nil

	local filetree = vgui.Create("GAceTree")

	-- Requests the server to update the whole filetree immediately
	gace.filetree.RefreshPath(gace.GetOption("root_path"))

	sb:AddDocked("FileTree", filetree, FILL)
end)
