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
		local status = repo:Status()
		repo:Free()

		tbl.git_branch = status.Branch

		-- we want to send this after player receives git updates
		timer.Simple(0, function() gace.GitBroadcastFolderStatus(ply, gace.Path(pathobj:GetVFolder())) end)
	end

	return tbl
end

function gace.Git_MakeDiffResponse(ply, path)
	local pathobj, vfolder = gace.ParsePath(path)
	if not pathobj then return {err=vfolder} end

	if pathobj:IsRoot() then
		return {err="Can't git-diff root"}
	end

	if not gace.TestAccess(vfolder.access, ply, pathobj, "git-diff") then
		return {err="No access"}
	end

	if not luagit_available then
		return {err="No luagit available"}
	end

	if not vfolder.getabspathfunc then
		return {err="No runcmdfunc in vfolder"}
	end

	local ret, msg = vfolder.runcmdfunc(pathobj, "git diff")

	return {ret="Success", diff=msg}
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

	local ret, err = repo:Commit(cmsg)

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

	gace.Send(ply, 0, "git_updstatus", payload)
end

gace.AddHook("PostSave", "Git_BroadcastGitStatus", function(ply, path)
	local pathobj, vfolder = gace.ParsePath(path)
	local vfoldername = pathobj:GetVFolder()

	if not gace.ValidGitVFolders[vfoldername] then return end

	gace.GitBroadcastFolderStatus(ply, pathobj:WithoutFile())
end)