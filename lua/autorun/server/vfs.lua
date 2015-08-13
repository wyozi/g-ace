gace.Root = gace.VFS.VirtualFolder("root", true)

local gace_sadmin_defperms = CreateConVar("gace_superadmin_defperms", "1", FCVAR_ARCHIVE, "Should superadmins have all permissions on root folder by default")

if gace_sadmin_defperms:GetBool() then
	gace.Root:grantPermission("superadmins", gace.VFS.ServerPermission)
end

gace.fs = {}

function gace.fs.resolve(path, parent)
	parent = parent or gace.Root

	if path == "" then return ATPromise(parent) end

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

	if op == "mkdir" then
		local folder_name, par_path = gace.path.tail(gace.path.normalize(payload.path))
		ResolveNode(par_path, gace.VFS.Permission.WRITE):then_(function(node)
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
	end
end)
