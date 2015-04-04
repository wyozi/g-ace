gace.RegisterCommand("cp", {
    name = "Copy file",
    help = "Copies file from x to y",
    ipc = "cmd-cp",
    args = {
        {type = "string", name = "source"},
        {type = "string", name = "target", take_rest = true},
    },
    func = function(caller, source, target)
        local source_node
    	return gace.fs.resolve(gace.path.normalize(source)):then_(function(node)
			if not node:hasPermission(caller, gace.VFS.Permission.READ) then
				return error(gace.VFS.ErrorCode.ACCESS_DENIED)
			end
    		if node:type() ~= "file" then
                return error(gace.VFS.ErrorCode.INVALID_TYPE)
            end

            source_node = node

            local _, target_folder = gace.path.tail(target)
            return gace.fs.resolve(gace.path.normalize(target_folder))
    	end):then_(function(target_node)
			if not target_node:hasPermission(caller, gace.VFS.Permission.WRITE) then
				return error(gace.VFS.ErrorCode.ACCESS_DENIED)
			end
    		if target_node:type() ~= "folder" then
                return error(gace.VFS.ErrorCode.INVALID_TYPE)
            end

            local filename = gace.path.tail(target)
            return target_node:createChildNode(filename, "file")
        end):then_(function(created_node)
            return source_node:read():then_(function(data)
                return created_node:write(data)
            end)
        end)
    end,
    func_ipc = function(caller, request, promise)
        promise:then_(function(str)
            request:CreateResponsePacket("cmd-cp", {}):Send()
        end):catch(function(err)
            request:CreateResponsePacket("cmd-cp", {err = err}):Send()
        end)
    end,
    func_tostring = function(caller, promise)
        promise:then_(function(str)
            caller:GAce_Msg(gace.LOG_INFO, "Copy succesful")
        end):catch(function(err)
            caller:GAce_Msg(gace.LOG_ERROR, err)
        end)
    end
})
