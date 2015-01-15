-- Adds default context menu options to filetree entries (aka "Delete", "Rename" etc)

gace.AddHook("FileTreeContextMenu", "FileTree_AddFileOptions", function(path, menu, nodetype)
	if nodetype ~= "file" then return end

	local ft = gace.filetree -- Shortcut to filetree library

	menu:AddOption("Copy path", function()
		SetClipboardText(path)
	end):SetIcon("icon16/page_link.png")

	menu:AddOption("Duplicate", function()
		gace.ext.ShowTextInputPrompt("Filename? Needs to end in .txt", function(nm)
			local folderpath = gace.path.tail(path)
			local filname = folderpath .. "/" .. nm
			gace.SendRequest("fetch", {path = path}, function(_, _, payload)
				if payload.err then return MsgN("Failed to fetch: ", payload.err) end
				gace.OpenSession(filname, {
					content = payload.content
				})
			end)
		end)
	end):SetIcon("icon16/page_copy.png")

	menu:AddOption("Rename", function()
		local folderpath, filename = gace.path.tail(path)

		local function DoRename(tab_was_open)
			gace.ext.ShowTextInputPrompt("Filename", function(nm)
				local newpath = folderpath .. "/" .. nm

				gace.SendRequest("fetch", {path = path}, function(_, _, payload)
					if payload.err then return MsgN("Failed to fetch: ", payload.err) end

					if tab_was_open then gace.CloseSession(path) end

					gace.SendRequest("rm", {path = path})
					gace.SendRequest("save", {path = newpath, content = payload.content})

					ft.RefreshPath(folderpath)

					-- TODO does reopening tab need a delay?
					if tab_was_open then gace.OpenSession(newpath) end
				end)
			end, filename)
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
		gace.SendRequest("rm", {path = path}, function(_, _, pl)
			if pl.err then
				gace.Log(gace.LOG_ERROR, "Failed to delete file: ", pl.err)
				return
			end
			local folderpath = gace.path.tail(path)
			ft.RefreshPath(folderpath)
		end)
	end):SetIcon("icon16/stop.png")
end)

gace.AddHook("FileTreeContextMenu", "FileTree_AddFolderOptions", function(path, menu, nodetype)
	if nodetype ~= "folder" then return end

	local ft = gace.filetree -- Shortcut to filetree library

	menu:AddOption("Refresh", function()
		ft.RefreshPath(path)
	end):SetIcon("icon16/arrow_refresh.png")

	menu:AddOption("Create File", function()
		gace.ext.ShowTextInputPrompt("Filename", function(nm)
			local filname = path .. "/" .. nm
			gace.OpenSession(filname, {content=""})
		end)
	end):SetIcon("icon16/page_add.png")

	menu:AddOption("Create Folder", function()
		gace.ext.ShowTextInputPrompt("Folder name", function(nm)
			local filname = path .. "/" .. nm
			gace.SendRequest("mkdir", {path = filname}, function(_, _, pl)
				if pl.err then
					gace.Log(gace.LOG_ERROR, "Failed to create folder: ", pl.err)
					return
				end
				ft.RefreshPath(path)
			end)
		end)
	end):SetIcon("icon16/folder_add.png")

	local csubmenu, csmpnl = menu:AddSubMenu("Delete", function() end)
	csmpnl:SetIcon( "icon16/cross.png" )

	csubmenu:AddOption("Are you sure?", function()
		gace.SendRequest("rm", {path = path}, function(_, _, pl)
			if pl.err then
				gace.Log(gace.LOG_ERROR, "Failed to delete folder: ", pl.err)
				return
			end
			gace.Log(gace.LOG_INFO, "Note: if folder wasn't deleted, make sure it is empty!")

			local folderpath = gace.path.tail(path)
			ft.RefreshPath(folderpath)
		end)
	end):SetIcon("icon16/stop.png")

	--[==[OBSOLETE
	menu:AddOption("Find", function()
		gace.ext.ShowTextInputPrompt("The phrase to search", function(nm)
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
	]==]
end)
