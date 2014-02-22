gace.VirtualFolders = gace.VirtualFolders or {}

function gace.SetupRawVFolder(id, access, data)
	gace.VirtualFolders[id] = {
		ffunc=data.filebrowser_func,
		svfunc=data.save_func,
		delfunc=data.delete_func,
		mkdirfunc=data.mkdir_func,
		access=access,
		description=data.description
	}
end

function gace.RemoveVFolder(id)
	local r = gace.VirtualFolders[id] ~= nil
	gace.VirtualFolders[id] = nil
	return r
end

-- Setups a simple virtual folder, which is simple based on a table, where folders are subtables and files are strings.
function gace.SetupSimpleVFolder(id, tbl, access, data)
	data = data or {}

	local function TraversePath(path)
		path = path:WithoutVFolder()

		-- Parent folder, folder
		local parfolder, folder = tbl, tbl

		for _,v in ipairs(path.Parts) do
			if folder then parfolder = folder end
			if not folder then break end

			folder = folder[v]
		end
		return folder, parfolder
	end

	gace.SetupRawVFolder(id, access, {
		filebrowser_func = function(curpath)
			local folder, parfolder = TraversePath(curpath)
			if not folder then return false, "Doesn't exist" end

			if type(folder) == "table" then
				local keys = gace.TableKeys(folder)
				return "folder",
						-- Files
						gace.Map(
							gace.FilterSeq(gace.SortedTable(gace.TableKeys(folder)), function(x) return type(folder[x]) == "string" end),
							function(nm) return curpath + nm end
						),
						-- Folders
						gace.Map(
							gace.FilterSeq(gace.SortedTable(gace.TableKeys(folder)), function(x) return type(folder[x]) == "table" end),
							function(nm) return curpath + nm end
						)
			end
			return "file", folder, 0, 0
		end,
		mkdir_func = function(curpath)
			local folder, parfolder = TraversePath(curpath)
			if not parfolder then return false, "Doesn't exist" end

			parfolder[curpath:GetFile()] = {}
		end,
		save_func = function(curpath, content)
			local folder, parfolder = TraversePath(curpath)
			if not parfolder then return false, "Doesn't exist" end

			parfolder[curpath:GetFile()] = content
		end,
		delete_func = function(curpath)
			local folder, parfolder = TraversePath(curpath)
			if not folder then return false, "Doesn't exist" end

			parfolder[curpath:GetFile()] = nil
		end,
		description = data.description
	})

end

-- Setups a virtual folder that uses Garry's Mod's IO lib (file.Write, file.Read etc)
function gace.SetupGModIOVFolder(id, root, path, access)

	local vfolderpath = gace.Path(id)

	-- Returns a function that maps source files (e.g. foo.txt) to full paths (e.g. VFolder/root/foo.txt)
	local function PathAdder(tpath)
		return function(src)
			return vfolderpath + tpath + src
		end
	end

	gace.SetupRawVFolder(id, access, {
		filebrowser_func = function(curpath)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			if not file.Exists(curpath:ToString(), path) then
				return false, "Doesn't exist"
			end

			local is_dir = curpath:IsRoot() or file.IsDir(curpath:ToString(), path)
			if is_dir then
				local files, folders = file.Find(curpath:ToString() .. "/*", path)
				gace.Debug("Crawling ", curpath:ToString() .. "/*", " results to ", #files, " files and ", #folders, " folders")
				
				return "folder", gace.Map(gace.SortedTable(files), PathAdder(curpath)), gace.Map(gace.SortedTable(folders), PathAdder(curpath))
			end
			return "file", file.Read(curpath:ToString(), path), file.Size(curpath:ToString(), path), file.Time(curpath:ToString(), path)
		end,
		save_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			if path ~= "DATA" then
				return false, "Unable to do IO outside data folder"
			end
			if not curpath:GetFile():EndsWith(".txt") then
				return false, "Path must end in .txt"
			end
			file.Write(curpath:ToString(), content)
			return true
		end,
		mkdir_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			if path ~= "DATA" then
				return false, "Unable to do IO outside data folder"
			end
			file.CreateDir(curpath:ToString())
			return true
		end,
		delete_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			if path ~= "DATA" then
				return false, "Unable to do IO outside data folder"
			end
			--if not file.Exists(curpath:ToString(), path) then
			--	return false, "Doesn't exist"
			--end

			file.Delete(curpath:ToString())
			return true
		end
	})
end

-- GaceIO support (https://github.com/wyozi/g-ace-io)
local module_loaded = pcall(require, "gaceio") and (gaceio ~= nil)

function gace.SetupGaceIOVFolder(id, root, access)
	if not module_loaded then
		error("Trying to setup a GaceIO VFolder when GaceIO module isn't loaded")
	end

	local vfolderpath = gace.Path(id)

	-- Returns a function that maps source files (e.g. foo.txt) to full paths (e.g. VFolder/root/foo.txt)
	local function PathAdder(tpath)
		return function(src)
			return vfolderpath + tpath + src
		end
	end
	-- Turns path into a string that can be passed to gaceio
	local function GIOPath(path)
		return "./garrysmod/" .. path:ToString()
	end

	gace.SetupRawVFolder(id, access, {
		filebrowser_func = function(curpath)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			if not gaceio.Exists(GIOPath(curpath)) then
				return false, "Doesn't exist"
			end

			local is_dir = curpath:IsRoot() or gaceio.IsFolder(GIOPath(curpath))
			if is_dir then
				local files, folders = gaceio.List(GIOPath(curpath))
				return "folder", gace.Map(gace.SortedTable(files), PathAdder(curpath)), gace.Map(gace.SortedTable(folders), PathAdder(curpath))
			end
			return "file", gaceio.Read(GIOPath(curpath)), 0, 0
		end,
		save_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			gaceio.Write(GIOPath(curpath), content)
			return true
		end,
		mkdir_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			gaceio.CreateFolder(GIOPath(curpath))
			return true
		end,
		delete_func = function(curpath, content)
			curpath = curpath:WithoutVFolder()
			curpath = root:Add(curpath)

			gaceio.Delete(GIOPath(curpath))
			return true
		end
	})
end

--gace.SetupVFolder("Data", "", "DATA", "superadmin")
--gace.SetupGModIOVFolder("EpicJB", gace.Path("epicjb/"), "DATA", "superadmin")

--gace.SetupSimpleVFolder("test", {}, "superadmin")

--pcall(function()
	--gace.SetupGaceIOVFolder("gaceiotest", gace.Path("lua"), "superadmin")
--end)

function gace.TestAccess(access, ply, ...)
	-- Invalid player (aka console) overrides all access right checks
	if not ply:IsValid() then return true end

	if access == "admin" then return ply:IsAdmin() or ply:IsSuperAdmin() end
	if access == "superadmin" then return ply:IsSuperAdmin() end

	if type(access) == "function" then
		return access(ply, ...)
	end
	if type(access) == "string" then
		return ply:IsUserGroup(access)
	end

	-- Invalid usergroup given?
	return false
end

function gace.ParsePath(path)
	if not path then return false, "Provided path is nil" end

	local pathobj = gace.Path(path)

	if pathobj:IsRoot() then return pathobj end

	local vfolder = gace.VirtualFolders[pathobj:GetVFolder()]
	if not vfolder then return false, "Inexistent virtual folder" end

	return pathobj, vfolder
end

function gace.MakeRecursiveListResponse(ply, path)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	local tree = {fol={}, fil={}}

	local function AddRec(v, ipath, parent)
		if not v.ffunc then return end -- No traversal function

		local type, files, folders = v.ffunc(ipath)
		if not type then return false, files end

		if not gace.TestAccess(v.access, ply, ipath, "ls") then return false, "No access" end
		if type ~= "folder" then return false, "Not a folder" end

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

		return true
	end

	if pathobj:IsRoot() then
		for k,v in pairs(gace.VirtualFolders) do
			tree.fol[k] = {}
			AddRec(v, pathobj + k, tree.fol[k])
		end
	else
		local ret, err = AddRec(vfolder, pathobj, tree)
		if not ret then
			return {err=err}
		end
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
	if not type then return {err=files} end

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
	if not type then return {err=files} end

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

function gace.MakeMkDirResponse(ply, path, content)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		return {err="Not a folder"}
	end

	if not gace.TestAccess(vfolder.access, ply, pathobj, "mkdir") then
		return {err="No access"}
	end

	local ret, err = vfolder.mkdirfunc(pathobj)
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

			-- Go line by line. Might be slow but works for our purpose and keeps code clean
			for i,line in pairs(content:Split("\n")) do
				local curcolumn = 1

				local function search()
					local findindex = string.find(line, phrase, curcolumn, true)
					if not findindex then return false end

					table.insert(matches, {
						path = fpath:ToString(),
						row = (i-1),
						col = (findindex-1),
						line = line
					})

					curcolumn = findindex+1

					return true
				end

				while search() do end
			end
		end
	end
	
	return {ret="Success", matches=matches}
end