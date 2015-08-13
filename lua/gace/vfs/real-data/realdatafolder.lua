gace.VFS.RealDataFolder = Middleclass("RealDataFolder", gace.VFS.Folder)
local RealDataFolder = gace.VFS.RealDataFolder

function RealDataFolder:initialize(name, fsPath)
    self.class.super.initialize(self, name)

    self._fsPath = fsPath

    self._entries = {}
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE
function RealDataFolder:capabilities()
    return caps
end

function RealDataFolder:fsLocalChildPath(child)
    return gace.path.normalize(self._fsPath .. "/" .. child)
end

function RealDataFolder:refresh()
    return ATPromise(function(resolver)
        local searchPath = self:fsLocalChildPath("*")
        local files, directories = file.Find(searchPath, "DATA")

        -- List of entries that dont exist on filesystem
        local leftovers = _u.keys(self._entries)

        -- Add unsynced file/folder to _entries and emit events
        local function AddEntry(name, type)
            table.RemoveByValue(leftovers, name)

            if self._entries[name] then return end

            local node

            if     type == "file"   then  node = gace.VFS.RealDataFile(name)
            elseif type == "folder" then  node = gace.VFS.RealDataFolder(name, self:fsLocalChildPath(name))
            end

            node:setParent(self)
            self._entries[name] = node

            self:emit("nodeCreated", node)

        end

        for _,v in pairs(directories) do
            AddEntry(v, "folder")
        end
        for _,v in pairs(files) do
            AddEntry(v, "file")
        end

        for _,lo in pairs(leftovers) do
            local node = self._entries[lo]
            self._entries[lo] = nil

            self:emit("nodeDeleted", node)
            node:emit("deleted")
        end

        resolver:resolve()
    end)
end

function RealDataFolder:child(name, opts)
    return ATPromise(function(resolver)
        self:refresh():then_(function()
            local node = self._entries[name]
            if node then
                resolver:resolve(node)
            else
                resolver:reject(gace.VFS.ErrorCode.NOT_FOUND)
            end
        end)
    end)
end

function RealDataFolder:listEntries(opts)
    return ATPromise(function(resolver)
        self:refresh():then_(function()
            resolver:resolve(self._entries)
        end)
    end)
end

function RealDataFolder:createChildNode(name, type, opts)
    return ATPromise(function(resolver)
        if not self:validateChildName(name) then
            resolver:reject(gace.VFS.ErrorCode.INVALID_NAME)
            return
        end

        local localPath = self:fsLocalChildPath(name)
        if file.Exists(localPath, "DATA") then
            resolver:reject(gace.VFS.ErrorCode.ALREADY_EXISTS)
            return
        end

        if type == "file" then
            file.Write(localPath, "")

            self:refresh():then_(function()
                resolver:resolve(self._entries[name])
            end):catch(function(e) resolver:reject(e) end)
        elseif type == "folder" then
            file.CreateDir(localPath)

            self:refresh():then_(function()
                resolver:resolve(self._entries[name])
            end):catch(function(e) resolver:reject(e) end)
        else
            resolver:reject(gace.VFS.ErrorCode.INVALID_TYPE)
        end
    end)
end

function RealDataFolder:deleteChildNode(node, opts)
    return ATPromise(function(resolver)
        local localPath = self:fsLocalChildPath(node:getName())

        if not file.Exists(localPath, "DATA") then
            resolver:reject(gace.VFS.ErrorCode.NOT_FOUND)
            return
        end

        file.Delete(localPath)

        self:refresh():then_(function()
            resolver:resolve()
        end)
    end)
end
