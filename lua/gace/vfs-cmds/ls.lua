gace.RegisterCommand("ls", {
    name = "List folder",
    help = "Lists folder contents",
    use_ipc = true,
    args = {
        {type = "string", name = "folder", take_rest = true}
    },
    func = function(caller, folder)
    	return gace.fs.resolve(gace.path.normalize(folder)):then_(function(node)
			if not node:hasPermission(caller, gace.VFS.Permission.READ) then
				return error(gace.VFS.ErrorCode.ACCESS_DENIED)
			end
    		if node:type() ~= "folder" then return error(gace.VFS.ErrorCode.INVALID_TYPE) end

    		return node:listEntries()
    	end)
    end,
    func_tostring = function(caller, promise)
        promise:then_(function(entries)
            caller:GAce_Msg(gace.LOG_INFO, "Entries:")
            for _,e in pairs(entries) do
                caller:GAce_Msg(e:getName())
            end
        end):catch(function(err)
            caller:GAce_Msg(gace.LOG_ERROR, err)
        end)
    end
})
