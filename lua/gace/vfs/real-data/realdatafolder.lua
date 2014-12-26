gace.VFS.RealDataFolder = Middleclass("RealDataFolder", gace.VFS.Folder)
local RealDataFolder = gace.VFS.RealDataFolder

RealDataFolder:include(gace.VFS.SimpleName)

function RealDataFolder:initialize(name, fsPath, localPath)
    self.class.super.initialize(self)

    self:setName(name)

    self._fsPath = fsPath
    self._localPath = localPath or ""
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE
function RealDataFolder:capabilities()
    return caps
end

function RealDataFolder:fsLocalPath()
    return gace.NormalizePath(string.format("%s/%s", self._fsPath, self._localPath))
end
function RealDataFolder:fsLocalChildPath(child)
    return gace.NormalizePath(self:fsLocalPath() .. "/" .. child)
end

function RealDataFolder:listEntries(opts)
    return Promise(function(resolver)
        local searchPath = self:fsLocalChildPath("*")

        local files, directories = file.Find(searchPath, "DATA")

        local entries = {}

        for _,v in pairs(directories) do
            -- TODO node should not be created here
            local node = gace.VFS.RealDataFolder(v, self._fsPath, gace.NormalizePath(self._localPath .. "/" .. v))
            node:setParent(self)
            table.insert(entries, node)
        end

        for _,v in pairs(files) do
            -- TODO node should not be created here
            local node = gace.VFS.RealDataFile(v)
            node:setParent(self)
            table.insert(entries, node)
        end

        resolver:resolve(entries)
    end)
end

function RealDataFolder:createChildNode(name, type, opts)
    return Promise(function(resolver)
        local localPath = self:fsLocalChildPath(name)
        if file.Exists(localPath, "DATA") then
            resolver:reject(gace.VFS.ReturnCode.ALREADY_EXISTS)
            return
        end

        if type == "file" then
            file.Write(localPath, "")

            local node = gace.VFS.RealDataFile(localPath)
            node:setParent(self)

            resolver:resolve(node)
            -- TODO call events
        elseif type == "folder" then
            file.CreateDir(localPath)

            local node = gace.VFS.RealDataFolder(v, self._fsPath, gace.NormalizePath(self._localPath .. "/" .. v))
            node:setParent(self)

            resolver:resolve(node)
            -- TODO call events
        else
            resolver:reject(gace.VFS.ReturnCode.INVALID_TYPE)
        end
    end)
end

function RealDataFolder:deleteChildNode(node, opts)
    return Promise(function(resolver)
        local localPath = self:fsLocalChildPath(node:getName())

        if not file.Exists(localPath, "DATA") then
            resolver:reject(gace.VFS.ReturnCode.NOT_FOUND)
            return
        end

        file.Delete(localPath)

        resolver:resolve()
        -- TODO call events
    end)
end
