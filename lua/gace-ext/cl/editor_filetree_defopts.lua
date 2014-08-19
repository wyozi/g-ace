-- Adds default context menu options to filetree entries (aka "Delete", "Rename" etc)

gace.AddHook("FileTreeContextMenu", "FileTree_AddFileOptions", function(node, menu, nodetype)
	if nodetype ~= "file" then return end

	local ft = gace.filetree -- Shortcut to filetree library

	menu:AddOption("Duplicate", function()
		gace.AskForInput("Filename? Needs to end in .txt", function(nm)
			local filname = ft.NodeToPath(node, true) .. "/" .. nm
			gace.Fetch(ft.NodeToPath(node), function(_, _, payload)
				if payload.err then return MsgN("Failed to fetch: ", payload.err) end
				gace.OpenSession(filname, payload.content, {defens=true})
			end)
		end)
	end):SetIcon("icon16/page_copy.png")

	menu:AddOption("Rename", function()
		gace.AskForInput("Filename? Needs to end in .txt", function(nm)
			local folderpath = ft.NodeToPath(node, true)
			local filname = folderpath .. "/" .. nm

			local oldpath = ft.NodeToPath(node)
			gace.Fetch(oldpath, function(_, _, payload)
				if payload.err then return MsgN("Failed to fetch: ", payload.err) end

				gace.Delete(oldpath)
				gace.Save(filname, payload.content)

				ft.RefreshPath(filetree, folderpath)
			end)
		end, node:GetText())
	end):SetIcon("icon16/page_edit.png")

	local csubmenu, csmpnl = menu:AddSubMenu("Delete", function() end)
	csmpnl:SetIcon( "icon16/cross.png" )

	csubmenu:AddOption("Are you sure?", function()
		gace.Delete(ft.NodeToPath(node))
		ft.RefreshPath(filetree, ft.NodeToPath(node, true))
	end):SetIcon("icon16/stop.png")
end)

gace.AddHook("FileTreeContextMenu", "FileTree_AddFolderOptions", function(node, menu, nodetype)
	if nodetype ~= "folder" then return end

	local ft = gace.filetree -- Shortcut to filetree library

	menu:AddOption("Duplicate", function()
		gace.AskForInput("Filename? Needs to end in .txt", function(nm)
			local filname = ft.NodeToPath(node, true) .. "/" .. nm
			gace.Fetch(ft.NodeToPath(node), function(_, _, payload)
				if payload.err then return MsgN("Failed to fetch: ", payload.err) end
				gace.OpenSession(filname, payload.content, {defens=true})
			end)
		end)
	end):SetIcon("icon16/page_copy.png")

	menu:AddOption("Rename", function()
		gace.AskForInput("Filename? Needs to end in .txt", function(nm)
			local folderpath = ft.NodeToPath(node, true)
			local filname = folderpath .. "/" .. nm

			local oldpath = ft.NodeToPath(node)
			gace.Fetch(oldpath, function(_, _, payload)
				if payload.err then return MsgN("Failed to fetch: ", payload.err) end

				gace.Delete(oldpath)
				gace.Save(filname, payload.content)

				ft.RefreshPath(filetree, folderpath)
			end)
		end, node:GetText())
	end):SetIcon("icon16/page_edit.png")

	local csubmenu, csmpnl = menu:AddSubMenu("Delete", function() end)
	csmpnl:SetIcon( "icon16/cross.png" )

	csubmenu:AddOption("Are you sure?", function()
		gace.Delete(ft.NodeToPath(node))
		ft.RefreshPath(filetree, ft.NodeToPath(node, true))
	end):SetIcon("icon16/stop.png")
end)