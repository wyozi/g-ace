gace.RegisterCommand("mkvfolder", {
    name = "Create vfolder",
    help = "Creates a vfolder to root",
    ipc = "cmd-mkvfolder",
    args = {
        {type = "string", name = "type"},
        {type = "string", name = "name"},
        {type = "string", name = "path", optional = true}
    },
    func = function(caller, type, name, path)
		local ctor
		if type == "memory" then ctor = gace.VFS.MemoryFolder
		elseif type == "real-data" then ctor = gace.VFS.RealDataFolder
		elseif type == "real-gaceio" then ctor = gace.VFS.RealGIOFolder
		end

        if not ctor then return error("invalid vfolder type") end

        if not path and type ~= "memory" then return error("missing path") end

    	return gace.fs.resolve(""):then_(function(node)
			local folder = ctor(name, path)
			return node:addVirtualFolder(folder)
		end):then_(function(childNode)
			if caller:IsValid() then
                childNode:grantPlayerPermission(caller, gace.VFS.ServerPermission)
            end
            childNode:grantPermission("superadmins", gace.VFS.ServerPermission)
		end)
    end,
    func_ipc = function(caller, request, promise)
        promise:then_(function(entries)
            request:CreateResponsePacket("cmd-mkvfolder", {}):Send()
        end):catch(function(err)
            request:CreateResponsePacket("cmd-mkvfolder", {err = err}):Send()
        end)
    end,
    func_tostring = function(caller, promise)
        promise:then_(function()
            caller:GAce_Msg(gace.LOG_INFO, "VFolder created! Run 'gace-reopen'")
        end):catch(function(err)
            caller:GAce_Msg(gace.LOG_ERROR, err)
        end)
    end
})
