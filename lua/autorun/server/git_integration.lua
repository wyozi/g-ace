pcall(require, "luagit")
local luagit_available = git ~= nil

-- Stores VFolders that are git enabled
gace.ValidGitVFolders = gace.ValidGitVFolders or {}

function gace.Git_MakeStatusResponse(ply, path)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		return {err="Can't git-status root"}
	end

	if not gace.TestAccess(vfolder.access, ply, pathobj, "git-status") then
		return {err="No access"}
	end

	if not luagit_available then
		return {err="No luagit available"}
	end

	if not vfolder.getabspathfunc then
		return {err="No runcmdfunc in vfolder"}
	end

	gace.ValidGitVFolders[pathobj:GetVFolder()] = true

	local abspath = vfolder.getabspathfunc(gace.Path(pathobj:GetVFolder()))

	local tbl = {ret="Success"}
	if not git.IsRepository(abspath) then
		tbl.git_enabled = false
	else
		tbl.git_enabled = true

		local repo = git.Open(abspath)
		local status, err = repo:Status()
		repo:Free()

		if not status then return {err = err} end

		tbl.git_branch = status.Branch

		-- we want to send this after player receives git updates
		timer.Simple(0, function() gace.GitBroadcastFolderStatus(ply, gace.Path(pathobj:GetVFolder())) end)
	end

	return tbl
end
function gace.Git_MakeLogResponse(ply, path)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		return {err="Can't git-status root"}
	end

	if not gace.TestAccess(vfolder.access, ply, pathobj, "git-status") then
		return {err="No access"}
	end

	if not luagit_available then
		return {err="No luagit available"}
	end

	if not vfolder.getabspathfunc then
		return {err="No runcmdfunc in vfolder"}
	end
	local abspath = vfolder.getabspathfunc(gace.Path(pathobj:GetVFolder()))

	local repo = git.Open(abspath)
	if not repo then return {err="Unable to open repo"} end

	local tbl = {ret="Success"}

	local log, err = repo:Log()
	if not log then return {err = err} end

	tbl.log = log

	repo:Free()

	return tbl
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

function gace.Git_MakeCommitAllResponse(ply, path, cmsg)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		return {err="Can't git-commitall root"}
	end

	if not gace.TestAccess(vfolder.access, ply, pathobj, "git-commitall") then
		return {err="No access"}
	end

	if not luagit_available then
		return {err="No luagit available"}
	end

	if not vfolder.getabspathfunc then
		return {err="No runcmdfunc in vfolder"}
	end

	local abspath = vfolder.getabspathfunc(gace.Path(pathobj:GetVFolder()))

	local tbl = {ret="Success"}

	local repo = git.Open(abspath)

	local addindex, err = repo:AddPathSpecToIndex("**")
	if addindex == false then
		return {err="AddToIndex error: " .. tostring(err)}
	end

	local cname, cemail = "", ""
	if ply:IsValid() then
		cname = ply:Nick()
		cemail = ply:SteamID():Replace(":", "-") .. "@" .. GetServerIP()
	end
	local ret, err = repo:Commit(cmsg, cname, cemail)

	repo:Free()

	if not ret then
		return {err="Commit error: " .. tostring(err)}
	end

	timer.Simple(0, function() gace.GitBroadcastFolderStatus(ply, gace.Path(pathobj:GetVFolder())) end)

	local tbl = {ret="Success"}
	return tbl
end
function gace.Git_MakePushResponse(ply, path, cmsg)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		return {err="Can't git-push root"}
	end

	if not gace.TestAccess(vfolder.access, ply, pathobj, "git-push") then
		return {err="No access"}
	end

	if not luagit_available then
		return {err="No luagit available"}
	end

	if not vfolder.getabspathfunc then
		return {err="No runcmdfunc in vfolder"}
	end

	local abspath = vfolder.getabspathfunc(gace.Path(pathobj:GetVFolder()))

	local repo = git.Open(abspath)
	local ret, err = repo:Push()
	repo:Free()

	if ret then return {ret="Success"} end
	return {err=err}
end

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

	if not gace.ValidGitVFolders[vfoldername] then return end

	gace.GitBroadcastFolderStatus(ply, pathobj:WithoutFile())
end)


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
		responder_func(ply, reqid, op, gace.Git_MakeStatusResponse(ply, payload.path))
	elseif op == "git-log" then
		responder_func(ply, reqid, op, gace.Git_MakeLogResponse(ply, payload.path))
	elseif op == "git-push" then
		responder_func(ply, reqid, op, gace.Git_MakePushResponse(ply, payload.path))
	elseif op == "git-commitall" then
		responder_func(ply, reqid, op, gace.Git_MakeCommitAllResponse(ply, payload.path, payload.msg))
	end
end)
