-- Adds default context menu options to filetree entries (aka "Delete", "Rename" etc)

gace.AddHook("FileTreeContextMenu", "FileTree_AddFileOptions", function(path, menu, nodetype)
	if nodetype ~= "file" then return end

	local ft = gace.filetree -- Shortcut to filetree library

	menu:AddOption("Copy path", function()
		SetClipboardText(path)
	end):SetIcon("icon16/page_link.png")

	menu:AddOption("Duplicate", function()
		gace.ext.ShowTextInputPrompt("Filename? Needs to end in .txt", function(nm)
			local _, folderpath = gace.path.tail(path)
			local newpath = folderpath .. "/" .. nm

			gace.cmd.cp(LocalPlayer(), path, newpath):then_(function()
				ft.RefreshPath(folderpath)
			end):catch(function(e)
				gace.Log(gace.LOG_ERROR, "File duplication failed: ", e)
			end)
		end)
	end):SetIcon("icon16/page_copy.png")

	menu:AddOption("Rename", function()
		local filename, folderpath = gace.path.tail(path)

		local function DoRename(tab_was_open)
			gace.ext.ShowTextInputPrompt("Filename", function(nm)
				local newpath = folderpath .. "/" .. nm

				gace.cmd.mv(LocalPlayer(), path, newpath):then_(function()
					ft.RefreshPath(folderpath)
					if tab_was_open then
						gace.CloseSession(path)
						gace.OpenSession(newpath)
					end
				end):catch(function(e)
					gace.Log(gace.LOG_ERROR, "File rename failed: ", e)
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
			local _, folderpath = gace.path.tail(path)
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

	-- Helper to create folders
	local function CreateFolder(fpath)
		return ATPromise(function(res)
			gace.SendRequest("mkdir", {path = fpath}, function(_, _, pl)
				if pl.err then
					res:reject(pl.err)
					return
				end
				res:resolve(fpath)
			end)
		end)
	end
	local function CreateNestedFolders(basePath, folders)
		local prom = ATPromise(basePath)
		for _,c in pairs(folders:Split("/")) do
			prom = prom:then_(function(curpath)
				local fpath = curpath .. "/" .. c
				return CreateFolder(fpath)
			end)
		end
		return prom
	end

	menu:AddOption("Create File", function()
		gace.ext.ShowTextInputPrompt("Filename", function(nm)
			local function OpenFileSession()
				local filname = path .. "/" .. nm
				gace.OpenSession(filname, {content=""})
			end

			local folders = nm:match("(.*)/[^/]*$")
			if folders then
				CreateNestedFolders(path, folders):done(function()
					ft.RefreshPath(path)
					
					OpenFileSession()
				end)
			else
				OpenFileSession()
			end

		end)
	end):SetIcon("icon16/page_add.png")

	menu:AddOption("Create Folder", function()
		gace.ext.ShowTextInputPrompt("Folder name", function(nm)
			CreateNestedFolders(path, nm):then_(function(curpath)
				ft.RefreshPath(path)
			end):catch(function(e)
				gace.Log(gace.LOG_ERROR, "Failed to create folder: ", e)
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

			local _, folderpath = gace.path.tail(path)
			ft.RefreshPath(folderpath)
		end)
	end):SetIcon("icon16/stop.png")

	menu:AddOption("Search", function()
		gace.ext.ShowTextInputPrompt("Search phrase", function(nm)
			gace.cmd.grep(LocalPlayer(), path, nm):then_(function(t)
				local ins = table.insert
				local content_tbl = {}

				ins(content_tbl, "Searching for \x01" .. nm .. "\x01 in\x01" .. path .. "\x01\x01case sensitive\x01")
				ins(content_tbl, "")

				local res_byfile = {}
				for _,res in pairs(t.results) do
					res_byfile[res.path] = res_byfile[res.path] or {}

					ins(res_byfile[res.path], res)
				end

				local matchno, fileno = 0, 0

				for path, pathres in pairs(res_byfile) do
					ins(content_tbl, path .. ":")
					for _,res in pairs(pathres) do
						ins(content_tbl, "\t" .. res.row .. ": " .. res.linestr)
						matchno = matchno + 1
					end
					ins(content_tbl, "")
					fileno = fileno + 1
				end

				ins(content_tbl, "")
				ins(content_tbl, "Found " .. matchno .. " matches in " .. fileno .. " files")

				gace.OpenSession("searchresults-" .. path, {
					content = table.concat(content_tbl, "\n"),
					mode = "ace/mode/c9search"
				})
			end):catch(function(e)
				gace.Log(gace.LOG_ERROR, "Search failed: ", e)
			end)

		end)
	end):SetIcon("icon16/magnifier.png")
end)
