-- This file implemented Drag n Drop functionality in the file tree using Garry's Mod's default VGui dnd functionality

gace.AddHook("FileTreePostNodeCreation", "FileTree_MoveFile", function(mypath, node, type)
	if type ~= "folder" then return end

	node:Receiver("gacefile", function(self, filepanels, dropped)
		if not dropped then return end

		-- Files getting moved to this folder
		for _,fp in pairs(filepanels) do
			local path = fp.NodeId
			-- Fetch contents of this file
			gace.Fetch(path, function(_, _, payload)
				if payload.err then return MsgN("Fail to fetch: ", payload.err) end

				-- Delete old file (this is a move, not a copy after all) and save new file with old contents
				gace.Delete(path)
				gace.Save(mypath .. "/" .. fp.NodeId:match("/?([^/]*)$"), payload.content)

				-- Refresh both old and new folders
				gace.filetree.RefreshPath(mypath)
				local oldfolder = gace.path.tail(path)
				gace.filetree.RefreshPath(oldfolder)
			end)
		end
	end)
end)
