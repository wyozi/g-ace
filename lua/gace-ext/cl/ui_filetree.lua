gace.AddHook("AddPanels", "Editor_AddFileTree", function(frame, basepnl)
	local sb = basepnl:GetById("SideBar")

	gace.FileNodeTree = nil

	local filetree = vgui.Create("DTree")
	filetree.Paint = function(self, w, h)
		surface.SetDrawColor(gace.UIColors.frame_bg)
		surface.DrawRect(0, 0, w, h)
	end

	local filetreemeta = gace.ClientCache:get("filetreemeta")
	if filetreemeta then
		gace.FileNodeTreeMeta = filetreemeta
	end

	-- Requests the server to update the whole filetree immediately
	gace.filetree.RefreshPath(filetree, "")

	-- Stores filetree meta to local filecache every 10seconds
	timer.Create("GAceFiletreeMetaPersistance", 10, 0, function()
		gace.ClientCache:set("filetreemeta", gace.FileNodeTreeMeta)
	end)

	sb:AddDocked("FileTree", filetree, FILL)
end) 