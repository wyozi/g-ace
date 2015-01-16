gace.RegisterCommand("cat", {
    name = "Print file",
    help = "Prints file contents",
    ipc = "cmd-cat",
    args = {
        {type = "string", name = "file", take_rest = true}
    },
    func = function(caller, file)
    	return gace.fs.resolve(gace.path.normalize(file)):then_(function(node)
			if not node:hasPermission(caller, gace.VFS.Permission.READ) then
				return error(gace.VFS.ErrorCode.ACCESS_DENIED)
			end
    		if node:type() ~= "file" then
                return error(gace.VFS.ErrorCode.INVALID_TYPE)
            end

    		return node:read()
    	end)
    end,
    func_ipc = function(caller, request, promise)
        promise:then_(function(str)
            request:CreateResponsePacket("cmd-cat", {data = str}):Send()
        end):catch(function(err)
            request:CreateResponsePacket("cmd-cat", {err = err}):Send()
        end)
    end,
    func_tostring = function(caller, promise)
        promise:then_(function(str)
            caller:GAce_Msg(gace.LOG_INFO, "Not printing " .. #str .. " chars.")
        end):catch(function(err)
            caller:GAce_Msg(gace.LOG_ERROR, err)
        end)
    end
})
