gace.AddHook("AddPanels", "Editor_AddFileTree", function(frame, basepnl)
	local sb = basepnl:GetById("SideBar")

	gace.FileNodeTree = nil

	local filetree = vgui.Create("GAceTree")

	local filetreemeta = gace.ClientCache:get("filetreemeta")
	if filetreemeta then
		gace.FileNodeTreeMeta = filetreemeta
	end

	-- Requests the server to update the whole filetree immediately
	gace.filetree.RefreshPath(gace.GetOption("root_path"))

	-- Stores filetree meta to local filecache every 10seconds
	timer.Create("GAceFiletreeMetaPersistance", 10, 0, function()
		gace.ClientCache:set("filetreemeta", gace.FileNodeTreeMeta)
	end)

	sb:AddDocked("FileTree", filetree, FILL)
end)
