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

function MemoryFolder:listEntries(opts)
    return Promise(function(resolver)
        resolver:resolve(self._entries)
    end)
end

function MemoryFolder:createChildNode(name, type, opts)
    return Promise(function(resolver)
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
            resolver:reject(gace.VFS.ReturnCode.INVALID_TYPE)
        end
    end)
end

function MemoryFolder:deleteChildNode(name, opts)
    return Promise(function(resolver)
        if self._entries[name] then
            local node = self._entries[name]
            self._entries[name] = nil

            self:emit("nodeDeleted", node)
            node:emit("deleted")

            resolver:resolve()
        else
            resolver:reject(gace.VFS.ReturnCode.NOT_FOUND)
        end
    end)
end
