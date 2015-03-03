gace.VFSDB = {}


if SERVER then

    sql.Query("CREATE TABLE IF NOT EXISTS gacevfs(type TEXT, name TEXT, path TEXT)")

    function gace.VFSDB.list()
        return sql.Query("SELECT * FROM gacevfs") or {}
    end
    function gace.VFSDB.add(type, name, path)
        sql.Query(
            string.format(
                "INSERT INTO gacevfs (type, name, path) VALUES (%s, %s, %s)",
                sql.SQLStr(type),
                sql.SQLStr(name),
                sql.SQLStr(path)
            )
        )
    end
    function gace.VFSDB.clear()
        sql.Query("DELETE FROM gacevfs")
    end

    function gace.CreateVFS(caller, type, name, path)
        local ctor
        if type == "memory" then ctor = gace.VFS.MemoryFolder
        elseif type == "real-data" then ctor = gace.VFS.RealDataFolder
        elseif type == "real-gaceio" then ctor = gace.VFS.RealGIOFolder
        end

        if not ctor then return error("invalid vfolder type") end

        if not path and type ~= "memory" then return error("missing path") end

        return gace.fs.resolve(""):then_(function(node)
            if not node:hasPermission(caller, gace.VFS.Permission.WRITE) then
                return error(gace.VFS.ErrorCode.ACCESS_DENIED)
            end

            local folder = ctor(name, path)
            return node:addVirtualFolder(folder)
        end):then_(function(childNode)
            if IsValid(caller) then
                childNode:grantPlayerPermission(caller, gace.VFS.ServerPermission)
            end
            childNode:grantPermission("superadmins", gace.VFS.ServerPermission)
        end)
    end

    hook.Add("InitPostEntity", "GAceLoadPersistentVFSFolders", function()
        for _,row in pairs(gace.VFSDB.list()) do
            gace.CreateVFS(nil, row.type, row.name, row.path):catch(function(e)
                gace.Log(gace.LOG_ERROR, "Creating permanent vfs folder failed: ", e)
            end)
        end
    end)
end

gace.RegisterCommand("mkvfolder", {
    name = "Create vfolder",
    help = "Creates a vfolder to root",
    ipc = "cmd-mkvfolder",
    args = {
        {type = "string", name = "type"},
        {type = "string", name = "name"},
        {type = "bool", name = "isPermanent"},
        {type = "string", name = "path", optional = true}
    },
    func = function(caller, type, name, isPerm, path)
    	return gace.CreateVFS(caller, type, name, path):then_(function()
            if isPerm then
                gace.VFSDB.add(type, name, path)
            end
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

if SERVER then
    gace.RegisterCommand("clearvfolders", {
        name = "Clear vfolders",
        help = "Removes permanent vfolders",
        args = {
        },
        func = function(caller)
            return gace.fs.resolve(""):then_(function(node)
                if not node:hasPermission(caller, gace.VFS.Permission.WRITE) then
                    return error(gace.VFS.ErrorCode.ACCESS_DENIED)
                end

                gace.VFSDB.clear()
            end)
        end,
        func_tostring = function(caller, promise)
            promise:then_(function()
                caller:GAce_Msg(gace.LOG_INFO, "Permanent vfolders cleared")
            end):catch(function(err)
                caller:GAce_Msg(gace.LOG_ERROR, err)
            end)
        end
    })
end
