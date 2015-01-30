gace.RegisterCommand("write", {
    name = "Write file",
    help = "Write string to file",
    ipc = "cmd-write",
    args = {
        {type = "string", name = "file"},
        {type = "string", name = "string", take_rest = true},
    },
    func = function(caller, file, str)
		local normpath = gace.path.normalize(file)
		local par_path, file_name = gace.path.tail(normpath)
    	return gace.fs.resolve(par_path):then_(function(node)
			if not node:hasPermission(caller, gace.VFS.Permission.WRITE) then
				return error(gace.VFS.ErrorCode.ACCESS_DENIED)
			end
    		if node:type() ~= "folder" then
                return error(gace.VFS.ErrorCode.INVALID_TYPE)
            end

			return node:verifyChildFileExists(file_name)
    	end):then_(function(childNode)
			return childNode:write(str):then_(function(content)
				gace.CallHook("PostSave", ply, normpath)
			end)
        end)
    end,
    func_ipc = function(caller, request, promise)
        promise:then_(function()
            request:CreateResponsePacket("cmd-write", {}):Send()
        end):catch(function(err)
            request:CreateResponsePacket("cmd-write", {err = err}):Send()
        end)
    end,
    func_tostring = function(caller, promise)
        promise:then_(function()
            caller:GAce_Msg(gace.LOG_INFO, "Write succesful")
        end):catch(function(err)
            caller:GAce_Msg(gace.LOG_ERROR, err)
        end)
    end
})
