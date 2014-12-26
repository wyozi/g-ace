gace.Root = gace.VFS.VirtualFolder("root")

local mem = gace.VFS.MemoryFolder("mem")
gace.Root:addVirtualFolder(mem)

local dat = gace.VFS.RealDataFolder("dat", "")
gace.Root:addVirtualFolder(dat)

gace.fs = {}

function gace.fs.resolve(path, parent)
	parent = parent or gace.Root

	if path == "" then return Promise(parent) end

	local folder, rest = gace.path.head(path)

	return parent:child(folder):then_(function(node)
		if rest == "" then
			return node
		else
			return gace.fs.resolve(rest, node)
		end
	end)
end

function gace.fs.ls(auth, path, opts)
	return gace.fs.resolve(path):then_(function(node)
		if node:type() ~= "folder" then return error(gace.VFS.ReturnCode.INVALID_TYPE) end

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

	-- File access
	if op == "ls" then
		local max_depth = 3

		local function traverseFolder(folderNode, par_tbl, rec)
			rec = rec or 0

			local p = Promise(function() end)

			folderNode:listEntries():then_(function(entries)
				local subpromises = {}
				for _,e in pairs(entries) do
					if e:type() == "file" then
						table.insert(par_tbl.fil, e:getName())
					elseif e:type() == "folder" then
						local foltbl = {fol={}, fil={}}
						par_tbl.fol[e:getName()] = foltbl

						if rec < max_depth then
							table.insert(subpromises, traverseFolder(e, foltbl, rec+1))
						else
							foltbl.pendingListing = true
						end
					end
				end
				p:_resolve(subpromises)
			end):catch(function(e) p:_reject(e) end)

			return p:all()
		end

		local normpath = gace.path.normalize(payload.path)
		gace.fs.resolve(normpath):then_(function(node)
			local tree = {fol={}, fil={}}

			traverseFolder(node, tree):then_(function()
				responder_func(ply, reqid, op, {ret="Success", type="filetree", path=normpath, tree=tree})
			end):catch(function(e)
				responder_func(ply, reqid, op, {err=e})
			end)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
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
