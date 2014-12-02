local gace_hide_dotfiles = CreateConVar("g-ace-hide-dotfiles", "1", FCVAR_ARCHIVE)

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

-- Calls to v.ffunc should be passed through this function. It validates that everything is correct and filters
--  unwanted things
function gace.ValidateFFunc(ftype, files, folders)
	if not ftype then return ftype, files, folders end
	if type(files) == "folder" and gace_hide_dotfiles:GetBool() then
		folders = gace.Filter(folders, function(v, k)
			return not v:GetFile():StartWith(".")
		end)
	end
	return ftype, files, folders
end

function gace.MakeRecursiveListResponse(ply, path)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		local parts = {}
		for k,v in pairs(gace.VirtualFolders) do
			table.insert(parts, gace.MakeRecursiveListResponse(ply, k))
		end
		return {multipart = true, parts=parts}
	end

	local tree = {fol={}, fil={}}

	local function AddRec(v, ipath, parent, depth)
		if not v.ffunc then return end -- No traversal function

		local type, files, folders = gace.ValidateFFunc(v.ffunc(ipath))
		if not type then return false, files end

		if not gace.TestAccess(v.access, ply, ipath, "ls") then return false, "No access" end
		if type ~= "folder" then return false, "Not a folder" end

		if depth >= 5 then
			parent.fil = parent.fil or {}
			table.insert(parent.fil, "ERR: TOO DEEP")
			return
		end

		for _,fol in pairs(folders) do
			local t = {}
			parent.fol = parent.fol or {}
			parent.fol[fol:GetFile()] = t

			AddRec(v, ipath + fol:GetFile(), t, depth+1)
		end
		for _,fil in pairs(files) do
			parent.fil = parent.fil or {}
			table.insert(parent.fil, fil:GetFile())
		end

		return true
	end

	local ret, err = AddRec(vfolder, pathobj, tree, 0)
	if not ret then
		return {err=err}
	end

	return {ret="Success", type="filetree", path=pathobj:ToString(), tree=tree}
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

	local type, files, folders = gace.ValidateFFunc(vfolder.ffunc(pathobj))
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

	gace.CallHook("PostSave", ply, path)

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

	local type, files, folders = gace.ValidateFFunc(vfolder.ffunc(pathobj))
	if type ~= "folder" then
		return {err="Not a folder"}
	end

	local matches = {}

	local function IterateVFolder(pathobj, files, folders)
		for _,folder in pairs(folders) do
			local fpath = pathobj + folder:GetFile()
			if gace.TestAccess(vfolder.access, ply, fpath, "find") then
				local type, files, folders = gace.ValidateFFunc(vfolder.ffunc(fpath))
				IterateVFolder(fpath, files, folders)
			end
		end

		for _,file in pairs(files) do
			local fpath = pathobj + file:GetFile()
			if gace.TestAccess(vfolder.access, ply, fpath, "find") then
				local type, content = gace.ValidateFFunc(vfolder.ffunc(fpath))

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
	end

	IterateVFolder(pathobj, files, folders)


	return {ret="Success", matches=matches}
end

gace.AddHook("HandleNetMessage", "HandleFileAccessMessages", function(netmsg)
	local ply = netmsg:GetSender()
	local op = netmsg:GetOpcode()
	local reqid = netmsg:GetReqId()
	local payload = netmsg:GetPayload()

	local responder_func = function(ply, reqid, op, payload)
		if payload.multipart then
			for _,part in pairs(payload.parts) do
				netmsg:CreateResponsePacket(op, part):Send()
			end
			return
		end
		netmsg:CreateResponsePacket(op, payload):Send()
	end

	-- If reqid is zero or empty, the client (most likely) doesnt care about response, so we dont send anything
	if reqid == "0" or reqid == "" then
		responder_func = function() end
	end

	-- File access
	if op == "ls" then
		responder_func(ply, reqid, op,
			payload.recursive and gace.MakeRecursiveListResponse(ply, payload.path)
			or  gace.MakeListResponse(ply, payload.path))
	elseif op == "fetch" then
		responder_func(ply, reqid, op, gace.MakeFetchResponse(ply, payload.path))
	elseif op == "save" then
		responder_func(ply, reqid, op, gace.MakeSaveResponse(ply, payload.path, payload.content))
	elseif op == "mkdir" then
		responder_func(ply, reqid, op, gace.MakeMkDirResponse(ply, payload.path))
	elseif op == "rm" then
		responder_func(ply, reqid, op, gace.MakeRmResponse(ply, payload.path))
	elseif op == "find" then
		responder_func(ply, reqid, op, gace.MakeFindResponse(ply, payload.path, payload.phrase))
	end
end)
