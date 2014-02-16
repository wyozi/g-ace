gace.VirtualFolders = gace.VirtualFolders or {}
gace.ROOT = {} -- Empty table object indicates uniqueness

function gace.SetupRawVFolder(id, filebrowser_func, access)
	gace.VirtualFolders[id] = {ffunc=filebrowser_func, access=access}
end

function gace.SetupVFolder(id, root, path, access)
	gace.SetupRawVFolder(id, function(curpath)
		curpath = root .. curpath
		local is_dir = curpath == "" or file.IsDir(curpath, path)
		if is_dir then
			local files, folders = file.Find(curpath .. "*", path)
			return "folder", files, folders
		end
		return "file", file.Read(curpath, path), file.Size(curpath, path), file.Time(curpath, path)
	end, access)
end

gace.SetupVFolder("Data", "", "DATA", "superadmin")

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
	if path == "" then
		return gace.ROOT, ""
	end
	local separators = path:Split("/")

	local vfolder = gace.VirtualFolders[separators[1]]
	if not vfolder then return false, "Inexistent virtual folder" end

	return vfolder, table.concat(separators, "/", 2)
end

function gace.TableKeysToList(tbl)
	local keys = {}
	for k,v in pairs(tbl) do table.insert(keys, k) end
	return keys
end

function gace.MakeListResponse(ply, path)
	local vpath, filepath = gace.ParsePath(path)
	if not vpath then return {err=filepath} end

	if vpath == gace.ROOT then
		return {type="folder", files={}, folders=gace.TableKeysToList(gace.VirtualFolders)}
	end

	if not gace.TestAccess(vpath.access, ply, filepath, path) then
		return {err="No access"}
	end

	local type, files, folders = vpath.ffunc(filepath)
	if type == "folder" then
		return {type="folder", files=files, folders=folders}
	end
	return {err="Is a file"}
end

function gace.MakeFetchResponse(ply, path)
	local vpath, filepath = gace.ParsePath(path)
	if not vpath then return {err=filepath} end

	if vpath == gace.ROOT then
		return {err="Is a folder"}
	end

	if not gace.TestAccess(vpath.access, ply, filepath, path) then
		return {err="No access"}
	end

	local type, files, folders = vpath.ffunc(filepath)
	local type, content = vpath.ffunc(filepath)
	if type == "file" then
		return {type="file", content=content}
	end
	return {err="Is a folder"}
end

function gace.HandleNetworking(ply, reqid, op, payload)
	if op == "ls" then
		gace.Send(ply, reqid, op, gace.MakeListResponse(ply, payload.path))
	elseif op == "fetch" then
		gace.Send(ply, reqid, op, gace.MakeFetchResponse(ply, payload.path))
	end
end