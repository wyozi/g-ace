-- This file implemented Drag n Drop functionality in the file tree using Garry's Mod's default VGui dnd functionality

gace.AddHook("OnFileTreeNodeCreated", "FileTree_DragNDrop_File", function(node, filetree, nodetype)
	if nodetype ~= "file" then return end

	node:Droppable("gacefile")
end)

gace.AddHook("OnFileTreeNodeCreated", "FileTree_DragNDrop_Folder", function(node, filetree, nodetype)
	if nodetype ~= "folder" then return end

	local ft = gace.filetree -- Shortcut to filetree library
	
	node:Receiver("gacefile", function(self, filepanels, dropped)
		if not dropped then return end

		local mypath = ft.NodeToPath(self)

		-- Files getting moved to this folder
		for _,fp in pairs(filepanels) do
			local path = ft.NodeToPath(fp)
			-- Fetch contents of this file
			gace.Fetch(path, function(_, _, payload)
				if payload.err then return MsgN("Fail to fetch: ", payload.err) end

				-- Delete old file (this is a move, not a copy after all) and save new file with old contents
				gace.Delete(path)
				gace.Save(mypath .. "/" .. fp:GetText(), payload.content)

				-- Refresh both old and new folders
				ft.RefreshPath(filetree, mypath)
				ft.RefreshPath(filetree, ft.NodeToPath(fp, true))
			end)
		end
	end)
end)