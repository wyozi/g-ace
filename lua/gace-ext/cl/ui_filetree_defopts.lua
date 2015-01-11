-- Adds default context menu options to filetree entries (aka "Delete", "Rename" etc)

gace.AddHook("FileTreeContextMenu", "FileTree_AddFileOptions", function(node, menu, nodetype)
	if nodetype ~= "file" then return end

	local ft = gace.filetree -- Shortcut to filetree library

	menu:AddOption("Duplicate", function()
		gace.ext.ShowTextInputPrompt("Filename? Needs to end in .txt", function(nm)
			local filname = ft.NodeToPath(node, true) .. "/" .. nm
			gace.Fetch(ft.NodeToPath(node), function(_, _, payload)
				if payload.err then return MsgN("Failed to fetch: ", payload.err) end
				gace.OpenSession(filname, payload.content, {defens=true})
			end)
		end)
	end):SetIcon("icon16/page_copy.png")

	menu:AddOption("Rename", function()
		local path = ft.NodeToPath(node)
		local folderpath = ft.NodeToPath(node, true)

		local function DoRename(tab_was_open)
			gace.ext.ShowTextInputPrompt("Filename", function(nm)
				local newpath = folderpath .. "/" .. nm

				gace.Fetch(path, function(_, _, payload)
					if payload.err then return MsgN("Failed to fetch: ", payload.err) end

					if tab_was_open then gace.CloseSession(path) end

					gace.Delete(path)
					gace.Save(newpath, payload.content)

					ft.RefreshPath(filetree, folderpath)

					-- TODO does reopening tab need a delay?
					if tab_was_open then gace.OpenSession(newpath) end
				end)
			end, node:GetText())
		end

		local sess = gace.GetSession(path)
		if sess and not sess:IsSaved() then
			gace.ext.ShowYesCancelPrompt("Rename file without saving? Unsaved contents will be lost.", function(ret)
				if ret == "yes" then
					DoRename(true)
				end
			end)
		else
			DoRename(sess ~= nil)
		end

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

	menu:AddOption("Refresh", function()
		ft.RefreshPath(filetree, ft.NodeToPath(node))
	end):SetIcon("icon16/arrow_refresh.png")

	menu:AddOption("Create File", function()
		gace.ext.ShowTextInputPrompt("Filename", function(nm)
			local filname = ft.NodeToPath(node) .. "/" .. nm
			gace.OpenSession(filname, {content=""})
		end)
	end):SetIcon("icon16/page_add.png")

	menu:AddOption("Create Folder", function()
		gace.ext.ShowTextInputPrompt("Folder name", function(nm)
			local filname = ft.NodeToPath(node) .. "/" .. nm
			gace.MkDir(filname, function(_, _, pl)
				if pl.err then
					gace.Log(gace.LOG_ERROR, "Failed to create folder: ", pl.err)
					return
				end
				ft.RefreshPath(filetree, ft.NodeToPath(node))
			end)
		end)
	end):SetIcon("icon16/folder_add.png")

	local path = ft.NodeToPath(node)
	if path == "root" then
		local csubmenu, csmpnl = menu:AddSubMenu("Create VFolder")
		csmpnl:SetIcon("icon16/folder_brick.png")

		local types = {"memory", "real-data", "real-gaceio"}

		for _,t in pairs(types) do
			csubmenu:AddOption(t, function()
				gace.ext.ShowTextInputPrompt("VFolder name", function(nm)
					gace.SendRequest("createvfolder", {path = nm, type = t}, function(_, _, pl)
						if pl.err then
							gace.Log(gace.LOG_ERROR, "Failed to create vfolder: ", pl.err)
							return
						end
						ft.RefreshPath(filetree, ft.NodeToPath(node, true))
					end)
				end)
			end)
		end
	end

	menu:AddOption("Find", function()
		gace.ext.ShowTextInputPrompt("The phrase to search", function(nm)
			local path = ft.NodeToPath(node)
			gace.Find(path, nm, function(_, _, pl)

				local resdocument = {}
				local function ins(s) table.insert(resdocument, s) end

				-- This weird formatting performs better than string concats, so excuse me

				ins([[
local searchresults = {
phrase = "]] .. nm .. [[",
search_location = "]] .. path .. [[",
num_matches = ]] .. #pl.matches .. [[,
}

print("Note: each match is followed by a 'goto' line.")
print("Place your cursor on a 'goto' line and press Ctrl-Enter to go to that row in that file.")

]])
				ins("local matches = {\n")
				for i,match in ipairs(pl.matches) do
					ins("	[") ins(i) ins("] = {\n")
					ins("		row = ") ins(match.row) ins(", column = ") ins(match.col) ins(",\n")
					ins("		line = [[") ins(match.line) ins("]],\n")

					ins("		link = [[ ")
						ins("goto[f=") ins(match.path) ins(";r=") ins(tostring(match.row))
						ins(";c=") ins(tostring(match.col)) ins("]")
					ins(" ]] -- Ctrl-enter on this line!\n")
					ins("	},\n")
				end
				ins("}")

				gace.OpenSession("find_results_" .. os.time(), {content=table.concat(resdocument, "")})

			end)
		end)
	end):SetIcon("icon16/magnifier.png")
end)
