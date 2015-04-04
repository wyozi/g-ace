-- This file implemented Drag n Drop functionality in the file tree using Garry's Mod's default VGui dnd functionality

gace.AddHook("FileTreePostNodeCreation", "FileTree_MoveFile", function(target_folderpath, node, type)
	if type ~= "folder" then return end

	node:Receiver("gacefile", function(self, filepanels, dropped)
		if not dropped then return end

		-- Files getting moved to this folder
		for _,fp in pairs(filepanels) do
			local path = fp.NodeId
			local _, source_folder = gace.path.tail(path)
			local newpath = target_folderpath .. "/" .. fp.NodeId:match("/?([^/]*)$")

			local sess = gace.GetSession(path)

			gace.cmd.mv(LocalPlayer(), path, newpath):then_(function()
				gace.filetree.RefreshPath(source_folder)
				gace.filetree.RefreshPath(target_folderpath)

				if sess ~= nil then
					gace.CloseSession(path)
					gace.OpenSession(newpath)
				end
			end):catch(function(e)
				gace.Log(gace.LOG_ERROR, "File move failed: ", e)
			end)
		end
	end)
end)
