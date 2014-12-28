pcall(require, "luagit")
local luagit_available = git ~= nil

function gace.GitBroadcastFolderStatus(ply, folderpathobj)
	local _, vfolder = gace.ParsePath(folderpathobj:ToString())

	local abspath = vfolder.getabspathfunc(gace.Path(folderpathobj:GetVFolder())) -- root folder's abs path
	local repo = git.Open(abspath)

	local payload = {}

	-- Get all files in the parent folder
	local listresp = gace.MakeListResponse(ply, folderpathobj:ToString())
	if listresp.files then
		for _,file in pairs(listresp.files) do
			local relative_path = folderpathobj:Add(file)
			local status, err = repo:FileStatus(relative_path:WithoutVFolder():ToString())
			if status == false then MsgN(err) end

			if status == nil then status = "empty" end -- If nil the table entry is removed

			payload[relative_path:ToString()] = status
		end
	end
	repo:Free()

	gace.NetMessageOut(0, "git_updstatus", payload):Send(ply)
end

gace.AddHook("PostSave", "Git_BroadcastGitStatus", function(ply, path)
	local pathobj, vfolder = gace.ParsePath(path)
	local vfoldername = pathobj:GetVFolder()

	--gace.GitBroadcastFolderStatus(ply, pathobj:WithoutFile())
end)

gace.git = {}

local function onRepo(repoOrPath, fn)
	if not repoOrPath then
		return error("No repoOrPath given!")
	end

	if type(repoOrPath) == "string" then
		local repo, err = git.Open(repoOrPath)
		if not repo then return false, err end

		local ret = {fn(repo)}
		repo:Free()

		return unpack(ret)
	else
		return fn(repoOrPath)
	end
end

-- Source: somewhere on internet
local function GetServerIP()
	local hostip = GetConVarString( "hostip" )
	hostip = tonumber( hostip )

	local ip = {}
	ip[ 1 ] = bit.rshift( bit.band( hostip, 0xFF000000 ), 24 )
	ip[ 2 ] = bit.rshift( bit.band( hostip, 0x00FF0000 ), 16 )
	ip[ 3 ] = bit.rshift( bit.band( hostip, 0x0000FF00 ), 8 )
	ip[ 4 ] = bit.band( hostip, 0x000000FF )

	return table.concat( ip, "." )
end

function gace.git.identity(ply)
	local cname, cemail = "", ""
	if ply:IsValid() then
		cname = ply:Nick()
		cemail = ply:SteamID():Replace(":", "-") .. "@" .. GetServerIP()
	end
	return {
		name = cname,
		email = cemail
	}
end

function gace.git.add(repoOrPath, pathspec)
	return onRepo(repoOrPath, function(repo)
		local addindex, err = repo:AddPathSpecToIndex("**")

		local changed_paths = {}

		local status, err = repo:Status()
		if not status then
			return false, "Status error: " .. err
		end

		-- All we care about is changes in index
		for _,change in pairs(status.IndexChanges) do
			changed_paths[change.Path] = "m"
		end

		return changed_paths
	end)
end
function gace.git.commit(repoOrPath, msg, opts)
	return onRepo(repoOrPath, function(repo)
		local cname, cemail = "", ""
		if opts and opts.identity then
			cname = opts.identity.name
			cemail = opts.identity.email
		end

		local ret, err = repo:Commit(msg, cname, cemail)
		if not ret then
			return false, err
		end

		return true
	end)
end
function gace.git.push(repoOrPath, remote, branch)
	return onRepo(repoOrPath, function(repo)
		local status, err = repo:Push()
		if not status then
			return false, "Status error: " .. err
		end

		return true
	end)
end

function gace.git.is_repo(path)
	return git.IsRepository(path)
end

function gace.git.status(repoOrPath)
	return onRepo(repoOrPath, function(repo)
		local status, err = repo:Status()
		if not status then
			return false, err
		end

		return status
	end)
end
function gace.git.log(repoOrPath)
	return onRepo(repoOrPath, function(repo)
		local log, err = repo:Log()
		if not log then
			return false, err
		end

		return log
	end)
end

gace.AddHook("HandleNetMessage", "HandleGitMessages", function(netmsg)
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

	local function GetRealPath(path, need_root)
		local normpath = gace.path.normalize(path)

		return gace.fs.resolve(normpath):then_(function(node)
			if need_root then
				local initialNode = node:findInitialFsNode()
				if not initialNode then return error("FS Root not found!!") end
				return initialNode
			end
			return node
		end):then_(function(node)
			if not node:hasCapability(gace.VFS.Capability.REALFILE) then
				return error("path does not support REALFILE")
			end
			return node:realPath()
		end)
	end

	-- Git integration
	if op == "git-status" then
		GetRealPath(payload.path, true):then_(function(realpath)
			if not gace.git.is_repo(realpath) then
				return {ret = "Success", git_enabled = false}
			end

			local ret, err = gace.git.status(realpath)
			if not ret then return error(err) end

			-- Awkward place for this..
			timer.Simple(0, function() gace.GitBroadcastFolderStatus(ply, gace.Path(node:path())) end)

			return {ret = "Success", git_enabled = true, git_branch = ret.Branch}
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "git-log" then
		GetRealPath(payload.path, true):then_(function(realpath)
			local ret, err = gace.git.log(realpath)
			if not ret then return error(err) end

			return {ret = "Success", log = ret}
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "git-push" then
		GetRealPath(payload.path, true):then_(function(realpath)
			local ret, err = gace.git.push(realpath)
			if not ret then return error(err) end

			return {ret = "Success"}
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "git-add" then
		GetRealPath(payload.path, true):then_(function(realpath)
			-- Need to get realpath of payload.path relative to initial fs node
			return GetRealPath(payload.path):then_(function(file_realpath)
				-- This actually works. Nice.
				local relativePath = file_realpath:Replace(realpath .. "/", "")

				local ret, err = gace.git.add(realpath, relativePath)
				if not ret then return error(err) end

				return {ret = "Success"}
			end)
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "git-commit" then
		GetRealPath(payload.path, true):then_(function(realpath)
			local ret, err = gace.git.commit(realpath, payload.msg, {
				identity = gace.git.identity(ply)
			})
			if not ret then return error(err) end

			return {ret = "Success"}
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "git-commitall" then
		GetRealPath(payload.path, true):then_(function(realpath)
			local ret, err = gace.git.add(realpath, "**")
			if not ret then return error(err) end

			local ret, err = gace.git.commit(realpath, payload.msg, {
				identity = gace.git.identity(ply)
			})
			if not ret then return error(err) end

			return {ret = "Success"}
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	end
end)
