gace.Root = gace.VFS.VirtualFolder("root", true)
gace.Root:grantPermission("superadmins", gace.VFS.Permission.EXECUTE)

gace.fs = {}

function gace.fs.resolve(path, parent)
	parent = parent or gace.Root

	if path == "" then return Promise(parent) end

	local firstChildName, rest = gace.path.head(path)

	return parent:child(firstChildName):then_(function(node)
		if rest == "" then
			return node
		else
			return gace.fs.resolve(rest, node)
		end
	end)
end

function gace.fs.ls(auth, path, opts)
	return gace.fs.resolve(path):then_(function(node)
		if node:type() ~= "folder" then return error(gace.VFS.ErrorCode.INVALID_TYPE) end

		return node:listEntries()
	end)
end

gace.AddHook("HandleNetMessage", "HandleFileAccess", function(netmsg)
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

	local function ResolveNode(path, required_perms)
		local normpath = gace.path.normalize(path)
		return gace.fs.resolve(normpath):then_(function(node)
			if not node:hasPermission(ply, required_perms) then
				return error(gace.VFS.ErrorCode.ACCESS_DENIED)
			end
			return node
		end)
	end

	if op == "fetch" then
		ResolveNode(payload.path, gace.VFS.Permission.READ):then_(function(node)
			if node:type() ~= "file" then return error(gace.VFS.ErrorCode.INVALID_TYPE) end

			return node:read():then_(function(content)
				responder_func(ply, reqid, op, {ret="Success", type="file", content=content})
			end)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "save" then
		local normpath = gace.path.normalize(payload.path)
		local par_path, file_name = gace.path.tail(normpath)
		ResolveNode(par_path, gace.VFS.Permission.WRITE):then_(function(node)
			if node:type() ~= "folder" then return error(gace.VFS.ErrorCode.INVALID_TYPE) end

			return node:verifyChildFileExists(file_name)
		end):then_(function(childNode)
			return childNode:write(payload.content):then_(function(content)
				responder_func(ply, reqid, op, {ret="Success"})

				gace.CallHook("PostSave", ply, normpath)
			end)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "mkdir" then
		local par_folder, folder_name = gace.path.tail(gace.path.normalize(payload.path))
		ResolveNode(par_folder, gace.VFS.Permission.WRITE):then_(function(node)
			if node:type() ~= "folder" then return error(gace.VFS.ErrorCode.INVALID_TYPE) end

			return node:createChildNode(folder_name, "folder")
		end):then_(function(childNode)
			responder_func(ply, reqid, op, {ret="Success"})
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "rm" then
		ResolveNode(payload.path, gace.VFS.Permission.WRITE):then_(function(node)
			return node:delete()
		end):then_(function(childNode)
			responder_func(ply, reqid, op, {ret="Success"})
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "find" then
		-- TODO implement
		--responder_func(ply, reqid, op, gace.MakeFindResponse(ply, payload.path, payload.phrase))
	elseif op == "createvfolder" then
		local ctor
		if payload.type == "memory" then ctor = gace.VFS.MemoryFolder
		elseif payload.type == "real-data" then ctor = gace.VFS.RealDataFolder
		elseif payload.type == "real-gaceio" then ctor = gace.VFS.RealGIOFolder
		end

		ResolveNode("", gace.VFS.Permission.WRITE):then_(function(node)
			if node:type() ~= "folder" then return error(gace.VFS.ErrorCode.INVALID_TYPE) end
			if not ctor then return error("invalid vfolder type") end

			local folder = ctor(payload.path, unpack(payload.args or {}))
			return node:addVirtualFolder(folder)
		end):then_(function(childNode)
			responder_func(ply, reqid, op, {ret="Success"})
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	end
end)
