gace.VFS.MemoryFolder = Middleclass("MemoryFolder", gace.VFS.Folder)
local MemoryFolder = gace.VFS.MemoryFolder

MemoryFolder:include(gace.VFS.SimpleName)

function MemoryFolder:initialize(name)
    self.class.super.initialize(self)

    self:setName(name)
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
        if type == "file" then
            local created = gace.VFS.MemoryFile:new(name)
            self._entries[name] = created
            created:setParent(self)
            resolver:resolve()
            -- TODO call events
        elseif type == "folder" then
            local created = gace.VFS.MemoryFolder:new(name)
            self._entries[name] = created
            created:setParent(self)
            resolver:resolve()
            -- TODO call events
        else
            resolver:reject(gace.VFS.ReturnCode.INVALID_TYPE)
        end
    end)
end

function MemoryFolder:deleteChildNode(name, opts)
    return Promise(function(resolver)
        if self._entries[name] then
            self._entries[name] = nil -- TODO call events
            resolver:resolve()
        else
            resolver:reject(gace.VFS.ReturnCode.NOT_FOUND)
        end
    end)
end
