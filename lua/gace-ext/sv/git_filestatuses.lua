
function gace.GitBroadcastRepoStatus(ply, path)
    if not gace.git then
        MsgN("gace.git nil in gace.GitBroadcastRepoStatus. git_commands.lua removed?")
        return
    end

	gace.git.virt_to_real(path):then_(function(realpath)
		local status, err = gace.git.status(realpath)
		if not status then
			MsgN("gace.GitBroadcastRepoStatus failed for '", path, "': ", err)
			return
		end

		gace.git.virt_to_real(path, false, true):then_(function(fsRootNode)
			local payload = {}

			--Same file can be in both IndexChganes and WDChanges, but WD takes
			--priority so it needs to be after

			for _,ic in pairs(status.IndexChanges) do
				payload[fsRootNode:path() .. "/" .. ic.Path] = "i_" .. ic.Status:sub(1, 1)
			end

			for _,wdc in pairs(status.WorkDirChanges) do
				payload[fsRootNode:path() .. "/" .. wdc.Path] = "wd_" .. wdc.Status:sub(1, 1)
			end

			local vfolder = gace.path.head(path)
			gace.NetMessageOut(0, "git_updstatus", {vfolder = vfolder, changes = payload}):Send(ply)
		end)

	end):catch(print)
end

gace.AddHook("PostSave", "Git_BroadcastGitStatus", function(ply, path)
	gace.GitBroadcastRepoStatus(ply, path)
end)
