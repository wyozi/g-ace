require("luagit")
local luagit_available = git ~= nil

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

	local abspath = vfolder.getabspathfunc(pathobj)

	local tbl = {ret="Success"}
	if not git.IsRepository(abspath) then
		tbl.git_enabled = false
	else
		tbl.git_enabled = true

		local repo = git.Open(abspath)
		local status = repo:Status()
		repo:Free()

		tbl.git_branch = status.Branch
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

	local abspath = vfolder.getabspathfunc(pathobj)

	local tbl = {ret="Success"}

	local repo = git.Open(abspath)
	local status = repo:Status()

	PrintTable(status)

	local fcount = 0
	for _,t in pairs(status.UntrackedFiles) do
		repo:Add(t.Path)
		fcount = fcount + 1
	end
	for _,t in pairs(status.WorkDirChanges) do
		repo:Add(t.Path)
		fcount = fcount + 1
	end
	for _,t in pairs(status.IndexChanges) do
		fcount = fcount + 1
	end

	local ret, err = repo:Commit(cmsg)

	repo:Free()

	if not ret then
		return {err=err}
	end

	local tbl = {ret="Success", branch=status.Branch, fcount=fcount}
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

	local abspath = vfolder.getabspathfunc(pathobj)

	local repo = git.Open(abspath)
	local ret, err = repo:Push()
	repo:Free()

	if ret then return {ret="Success"} end
	return {err=err}
end