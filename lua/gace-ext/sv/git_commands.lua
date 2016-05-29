pcall(require, "luagit")
local luagit_available = git ~= nil

gace.git = {}

function gace.git.available()
	return luagit_available
end

-- Helper function
function gace.git.virt_to_real(path, dont_find_root, return_node_instead)
	local normpath = gace.path.normalize(path)

	return gace.fs.resolve(normpath):then_(function(node)
		if dont_find_root then return node end

		local initialNode = node:findInitialFsNode()
		if not initialNode then return error("FS Root not found!!") end
		return initialNode
	end):then_(function(node)
		-- TODO better git permission handling. atm we assume all git ops need rw
		if not node:hasPermission(ply, gace.VFS.Permission.READ + gace.VFS.Permission.WRITE) then
			return error(gace.VFS.ErrorCode.ACCESS_DENIED)
		end
		if not node:hasCapability(gace.VFS.Capability.REALFILE) then
			return error(gace.VFS.ErrorCode.INSUFFICIENT_CAPS)
		end
		if return_node_instead then return node end
		return node:realPath()
	end)
end

local function onRepo(repoOrPath, fn)
	if not repoOrPath then
		return error("No repoOrPath given!")
	end

	if type(repoOrPath) == "string" then
		local repo, err = git.Open(repoOrPath)
		if not repo then return false, err end

		local ret = {fn(repo)}

		return unpack(ret)
	else
		return fn(repoOrPath)
	end
end

function gace.git.identity(ply)
	local cname, cemail = "", ""
	if ply:IsValid() then
		cname = ply:Nick()
		cemail = ply:SteamID():Replace(":", "-") .. "@" .. game.GetIPAddress()
	end
	return {
		name = cname,
		email = cemail
	}
end

function gace.git.add_pathspec(repoOrPath, pathspec)
	return onRepo(repoOrPath, function(repo)
		local ret, err = repo:AddPathSpecToIndex(pathspec)
		if ret == false then
			return false, err
		end

		return true
	end)
end
function gace.git.add(repoOrPath, path)
	return onRepo(repoOrPath, function(repo)
		local ret, err = repo:AddIndexEntry(path)
		if ret == false then
			return false, err
		end

		return true
	end)
end
function gace.git.rm(repoOrPath, path)
	return onRepo(repoOrPath, function(repo)
		local ret, err = repo:RemoveIndexEntry(path)
		if ret == false then
			return false, err
		end

		return true
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

function gace.git.fileStatus(repoOrPath, path)
	return onRepo(repoOrPath, function(repo)
		local status, err = repo:FileStatus(path)
		if not status then
			return false, err
		end

		return status
	end)
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
function gace.git.diff_headwd(repoOrPath)
	return onRepo(repoOrPath, function(repo)
		local diff, err = repo:DiffHEADToWorkdir()
		if not diff then
			return false, err
		end

		return diff
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

	-- Git integration
	if op == "git-status" then
		gace.git.virt_to_real(payload.path):then_(function(realpath)
			gace.Debug("git-status: checking " .. realpath .. " for repo validity")
			if not gace.git.is_repo(realpath) then
				return {ret = "Success", git_enabled = false}
			end

			local ret, err = gace.git.status(realpath)
			if not ret then return error(err) end

			-- Awkward place for this..
			timer.Simple(0, function() gace.GitBroadcastRepoStatus(ply, payload.path) end)

			return {ret = "Success", git_enabled = true, git_branch = ret.Branch}
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "git-log" then
		gace.git.virt_to_real(payload.path):then_(function(realpath)
			local ret, err = gace.git.log(realpath)
			if not ret then return error(err) end

			return {ret = "Success", log = ret}
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "git-diff-headwd" then
		gace.git.virt_to_real(payload.path):then_(function(realpath)
			local ret, err = gace.git.diff_headwd(realpath)
			if not ret then return error(err) end

			return {ret = "Success", diff = ret}
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "git-push" then
		gace.git.virt_to_real(payload.path):then_(function(realpath)
			local ret, err = gace.git.push(realpath)
			if not ret then return error(err) end

			return {ret = "Success"}
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "git-add" then
		gace.git.virt_to_real(payload.path):then_(function(realpath)
			-- Need to get realpath of payload.path relative to initial fs node
			return gace.git.virt_to_real(payload.path, true):then_(function(file_realpath)
				-- This actually works. Nice.
				local relativePath = file_realpath:Replace(realpath .. "/", "")

				local ret, err = gace.git.add(realpath, relativePath)
				if not ret then return error(err) end

				gace.GitBroadcastRepoStatus(ply, payload.path)

				return {ret = "Success"}
			end)
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "git-commit" then
		gace.git.virt_to_real(payload.path):then_(function(realpath)
			local ret, err = gace.git.commit(realpath, payload.msg, {
				identity = gace.git.identity(ply)
			})
			if not ret then return error(err) end

			gace.GitBroadcastRepoStatus(ply, payload.path)

			return {ret = "Success"}
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	elseif op == "git-commitall" then
		gace.git.virt_to_real(payload.path):then_(function(realpath)
			local ret, err = gace.git.add_pathspec(realpath, "**")
			if not ret then return error(err) end

			-- To add deleted files, we need to get status
			local ret, err = gace.git.status(realpath)
			if not ret then return error(err) end

			-- Go through each one and add manually. Expensive but we dont
			-- delete stuff that often, do we
			for _,wdc in pairs(ret.WorkdirChanges) do
				if wdc.Status == "deleted" then
					local ret, err = gace.git.rm(realpath, wdc.Path)
					if not ret then return error(err) end
				end
			end

			local ret, err = gace.git.commit(realpath, payload.msg, {
				identity = gace.git.identity(ply)
			})
			if not ret then return error(err) end

			gace.GitBroadcastRepoStatus(ply, payload.path)

			return {ret = "Success"}
		end):then_(function(tbl)
			responder_func(ply, reqid, op, tbl)
		end):catch(function(e)
			responder_func(ply, reqid, op, {err=e})
		end)
	end
end)
