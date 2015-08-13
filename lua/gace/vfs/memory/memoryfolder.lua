gace.VFS.MemoryFolder = Middleclass("MemoryFolder", gace.VFS.Folder)
local MemoryFolder = gace.VFS.MemoryFolder

function MemoryFolder:initialize(name)
    self.class.super.initialize(self, name)

    self._entries = {}
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE
function MemoryFolder:capabilities()
    return caps
end

function MemoryFolder:refresh() end

function MemoryFolder:child(name, opts)
    return ATPromise(function(resolver)
        local node = self._entries[name]
        if node then
            resolver:resolve(node)
        else
            resolver:reject(gace.VFS.ErrorCode.NOT_FOUND)
        end
    end)
end

function MemoryFolder:listEntries(opts)
    return ATPromise(function(resolver)
        resolver:resolve(self._entries)
    end)
end

function MemoryFolder:createChildNode(name, type, opts)
    return ATPromise(function(resolver)
        if not self:validateChildName(name) then
            resolver:reject(gace.VFS.ErrorCode.INVALID_NAME)
            return
        end

        local ctor

        if type == "file" then
            ctor = gace.VFS.MemoryFile
        elseif type == "folder" then
            ctor = gace.VFS.MemoryFolder
        end

        if ctor then
            local node = ctor(name)

            node:setParent(self)
            self._entries[name] = node
            self:emit("nodeCreated", node)

            resolver:resolve(node)
        else
            resolver:reject(gace.VFS.ErrorCode.INVALID_TYPE)
        end
    end)
end

function MemoryFolder:deleteChildNode(node, opts)
    local name = node:getName()

    return ATPromise(function(resolver)
        if self._entries[name] then
            local node = self._entries[name]
            self._entries[name] = nil

            self:emit("nodeDeleted", node)
            node:emit("deleted")

            resolver:resolve()
        else
            resolver:reject(gace.VFS.ErrorCode.NOT_FOUND)
        end
    end)
end
