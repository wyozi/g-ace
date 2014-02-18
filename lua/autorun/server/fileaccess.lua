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

	local vfolderpath = gace.Path(id)

	-- Returns a function that maps source files (e.g. foo.txt) to full paths (e.g. VFolder/root/foo.txt)
	local function PathAdder(tpath)
		return function(src)
			return vfolderpath + tpath + src
		end
	end

	gace.SetupRawVFolder(id, function(curpath)
		curpath = curpath:WithoutVFolder()
		curpath = root:Add(curpath)

		local is_dir = curpath:IsRoot() or file.IsDir(curpath:ToString(), path)
		if is_dir then
			local files, folders = file.Find(curpath:ToString() .. "/*", path)
			gace.Debug("Crawling ", curpath:ToString() .. "/*", " results to ", #files, " files and ", #folders, " folders")
			
			return "folder", gace.Map(files, PathAdder(curpath)), gace.Map(folders, PathAdder(curpath))
		end
		return "file", file.Read(curpath:ToString(), path), file.Size(curpath:ToString(), path), file.Time(curpath:ToString(), path)
	end, function(curpath, content)
		curpath = curpath:WithoutVFolder()

		if path ~= "DATA" then
			return false, "Unable to save outside data folder"
		end
		if not curpath:GetFile():EndsWith(".txt") then
			return false, "Path must end in .txt"
		end
		file.Write(root .. curpath, content)
		return true
	end, function(curpath, content)
		curpath = curpath:WithoutVFolder()

		if path ~= "DATA" then
			return false, "Unable to save outside data folder"
		end
		file.Delete(root .. curpath)
		return true
	end, access)
end

--gace.SetupVFolder("Data", "", "DATA", "superadmin")
gace.SetupVFolder("EpicJB", gace.Path("epicjb/"), "DATA", "superadmin")

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

	local pathobj = gace.Path(path)

	if pathobj:IsRoot() then return pathobj end

	local vfolder = gace.VirtualFolders[pathobj:GetVFolder()]
	if not vfolder then return false, "Inexistent virtual folder" end

	return pathobj, vfolder
end

function gace.TableKeysToList(tbl)
	local keys = {}
	for k,v in pairs(tbl) do table.insert(keys, k) end
	return keys
end

function gace.MakeRecursiveListResponse(ply, path)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	local tree = {fol={}, fil={}}

	local function AddRec(v, ipath, parent)
		local type, files, folders = v.ffunc(ipath)
		if not gace.TestAccess(v.access, ply, ipath, "ls") then return end
		if type ~= "folder" then return end

		for _,fol in pairs(folders) do
			local t = {}
			parent.fol = parent.fol or {}
			parent.fol[fol:GetFile()] = t

			AddRec(v, ipath + fol:GetFile(), t)
		end
		for _,fil in pairs(files) do
			parent.fil = parent.fil or {}
			table.insert(parent.fil, fil:GetFile())
		end
	end

	if pathobj:IsRoot() then
		for k,v in pairs(gace.VirtualFolders) do
			tree.fol[k] = {}
			AddRec(v, pathobj + k, tree.fol[k])
		end
	else
		AddRec(vfolder, pathobj, tree)
	end

	return {ret="Success", type="filetree", tree=tree}
end

function gace.MakeListResponse(ply, path)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		return {type="folder", files={}, folders=gace.TableKeysToList(gace.VirtualFolders)}
	end

	if not gace.TestAccess(vfolder.access, ply, pathobj, "ls") then
		return {err="No access"}
	end

	local type, files, folders = vfolder.ffunc(pathobj)
	if type == "folder" then
		return {ret="Success", type="folder", files=gace.Map(files, function(x)return x:GetFile() end), folders=gace.Map(folders, function(x)return x:GetFile() end)}
	end
	return {err="Not a folder"}
end

function gace.MakeFetchResponse(ply, path)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		return {err="Not a file"}
	end

	if not gace.TestAccess(vfolder.access, ply, pathobj, "fetch") then
		return {err="No access"}
	end

	local type, content = vfolder.ffunc(pathobj)
	if type == "file" then
		return {ret="Success", type="file", content=content}
	end
	return {err="Not a file"}
end

function gace.MakeSaveResponse(ply, path, content)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		return {err="Not a file"}
	end

	if not gace.TestAccess(vfolder.access, ply, pathobj, "save") then
		return {err="No access"}
	end

	local ret, err = vfolder.svfunc(pathobj, content)
	if not ret then return {err=err} end

	return {ret="Success"}
end

function gace.MakeRmResponse(ply, path, content)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		return {err="Not a file"}
	end

	if not gace.TestAccess(vfolder.access, ply, pathobj, "rm") then
		return {err="No access"}
	end

	local ret, err = vfolder.delfunc(pathobj)
	if not ret then return {err=err} end

	return {ret="Success"}
end

function gace.MakeFindResponse(ply, path, phrase)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		return {err="Is a folder"}
	end

	if not gace.TestAccess(vfolder.access, ply, pathobj, "find") then
		return {err="No access"}
	end

	local type, files, folders = vfolder.ffunc(pathobj)
	if type ~= "folder" then
		return {err="Not a folder"}
	end

	local matches = {}

	for _,file in pairs(files) do
		local fpath = pathobj + file:GetFile()
		if gace.TestAccess(vfolder.access, ply, fpath, "find") then
			local type, content = vfolder.ffunc(fpath)

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
					path = fpath:ToString(),
					row = count
				})

				curindex = findindex+1
			end

			while search() do end
		end
	end
	
	return {ret="Success", matches=matches}
end