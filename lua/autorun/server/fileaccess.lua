gace.VirtualFolders = gace.VirtualFolders or {}
gace.ROOT = {} -- Empty table object indicates uniqueness

function gace.SetupRawVFolder(id, filebrowser_func, save_func, delete_func, access)
	gace.VirtualFolders[id] = {
		ffunc=filebrowser_func,
		svfunc=save_func,
		delfunc=delete_func,
		access=access
	}
end

function gace.SetupVFolder(id, root, path, access)
	gace.SetupRawVFolder(id, function(curpath)
		curpath = root .. curpath
		local is_dir = curpath == "" or file.IsDir(curpath, path)
		if is_dir then
			local files, folders = file.Find(curpath .. "*", path)
			gace.Debug("Crawling ", curpath .. "*", " results to ", #files, " files and ", #folders, " folders")
			return "folder", files, folders
		end
		return "file", file.Read(curpath, path), file.Size(curpath, path), file.Time(curpath, path)
	end, function(curpath, content)
		if path ~= "DATA" then
			return false, "Unable to save outside data folder"
		end
		if not curpath:EndsWith(".txt") then
			return false, "Path must end in .txt"
		end
		file.Write(root .. curpath, content)
		return true
	end, function(curpath, content)
		if path ~= "DATA" then
			return false, "Unable to save outside data folder"
		end
		file.Delete(root .. curpath)
		return true
	end, access)
end

--gace.SetupVFolder("Data", "", "DATA", "superadmin")
gace.SetupVFolder("EpicJB", "epicjb/", "DATA", "superadmin")

function gace.TestAccess(access, ply, ...)
	if access == "admin" then return ply:IsAdmin() end
	if access == "superadmin" then return ply:IsSuperAdmin() end

	if type(access) == "function" then
		return access(ply, ...)
	end
	if type(access) == "string" then
		return ply:IsUserGroup(access)
	end

	return not ply:IsValid()
end

function gace.ParsePath(path)
	if not path then return false, "Provided path is nil" end
	if path == "" then
		return gace.ROOT, "", ""
	end
	local separators = path:Split("/")

	local vfolder = gace.VirtualFolders[separators[1]]
	if not vfolder then return false, "Inexistent virtual folder" end

	return vfolder, table.concat(separators, "/", 2), separators[1]
end

function gace.TableKeysToList(tbl)
	local keys = {}
	for k,v in pairs(tbl) do table.insert(keys, k) end
	return keys
end

function gace.MakeRecursiveListResponse(ply, path)
	local vpath, filepath = gace.ParsePath(path)
	if not vpath then return {err=filepath} end

	local tree = {fol={}, fil={}}

	local function AddRec(v, ipath, parent)
		local type, files, folders = v.ffunc(ipath)
		if not gace.TestAccess(v.access, ply, ipath, "ls") then return end

		for _,fol in pairs(folders) do
			local t = {}
			parent.fol = parent.fol or {}
			parent.fol[fol] = t

			local newpath = ""
			if ipath ~= "" then newpath = ipath .. "/" end
			newpath = newpath .. fol .. "/"

			AddRec(v, newpath, t)
		end
		for _,fil in pairs(files) do
			parent.fil = parent.fil or {}
			table.insert(parent.fil, fil)
		end
	end

	if vpath == gace.ROOT then
		for k,v in pairs(gace.VirtualFolders) do
			tree.fol[k] = {}
			AddRec(v, "", tree.fol[k])
		end
	else
		local nfilepath = filepath
		if nfilepath ~= "" then nfilepath = nfilepath .. "/" end
		AddRec(vpath,  nfilepath, tree)
	end

	return {ret="Success", type="filetree", tree=tree}
end

function gace.MakeListResponse(ply, path)
	local vpath, filepath = gace.ParsePath(path)
	if not vpath then return {err=filepath} end

	if vpath == gace.ROOT then
		return {type="folder", files={}, folders=gace.TableKeysToList(gace.VirtualFolders)}
	end

	if not gace.TestAccess(vpath.access, ply, filepath, "ls") then
		return {err="No access"}
	end

	local type, files, folders = vpath.ffunc(filepath)
	if type == "folder" then
		return {ret="Success", type="folder", files=files, folders=folders}
	end
	return {err="Not a folder"}
end

function gace.MakeFetchResponse(ply, path)
	local vpath, filepath = gace.ParsePath(path)
	if not vpath then return {err=filepath} end

	if vpath == gace.ROOT then
		return {err="Not a file"}
	end

	if not gace.TestAccess(vpath.access, ply, filepath, "fetch") then
		return {err="No access"}
	end

	local type, content = vpath.ffunc(filepath)
	if type == "file" then
		return {ret="Success", type="file", content=content}
	end
	return {err="Not a file"}
end

function gace.MakeSaveResponse(ply, path, content)
	local vpath, filepath = gace.ParsePath(path)
	if not vpath then return {err=filepath} end

	if vpath == gace.ROOT then
		return {err="Not a file"}
	end

	if not gace.TestAccess(vpath.access, ply, filepath, "save") then
		return {err="No access"}
	end

	local ret, err = vpath.svfunc(filepath, content)
	if not ret then return {err=err} end

	return {ret="Success"}
end

function gace.MakeRmResponse(ply, path, content)
	local vpath, filepath = gace.ParsePath(path)
	if not vpath then return {err=filepath} end

	if vpath == gace.ROOT then
		return {err="Not a file"}
	end

	if not gace.TestAccess(vpath.access, ply, filepath, "rm") then
		return {err="No access"}
	end

	local ret, err = vpath.delfunc(filepath)
	if not ret then return {err=err} end

	return {ret="Success"}
end

function gace.MakeFindResponse(ply, path, phrase)
	local vpath, filepath, vfname = gace.ParsePath(path)
	if not vpath then return {err=filepath} end

	if vpath == gace.ROOT then
		return {err="Is a folder"}
	end

	if not gace.TestAccess(vpath.access, ply, filepath, "find") then
		return {err="No access"}
	end

	local type, files, folders = vpath.ffunc(filepath)
	if type ~= "folder" then
		return {err="Not a folder"}
	end

	local matches = {}

	for _,file in pairs(files) do
		local fpath = filepath .. "/" .. file
		if gace.TestAccess(vpath.access, ply, fpath, "find") then
			local type, content = vpath.ffunc(fpath)

			local curindex = 1

			local function search()
				local findindex = string.find(content, phrase, curindex, true)
				if not findindex then return false end

				-- Hacky method of finding which row we're on ::::

				-- First get a string of all text until found index
				local upuntil_src = string.sub(content, 1, findindex)
				-- Then use gsub to count occurrences of newline chars
				local _, count = string.gsub(upuntil_src, "\n", "")

				-- Extremely hacky and expensive, but assuming there aren't a million files it's sufficient

				table.insert(matches, {
					path = vfname .. fpath,
					row = count
				})

				curindex = findindex+1
			end

			while search() do end
		end
	end
	
	return {ret="Success", matches=matches}
end