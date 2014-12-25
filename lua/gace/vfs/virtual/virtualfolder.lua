gace.VFS.VirtualFolder = Middleclass("VirtualFolder", gace.VFS.Folder)
local VirtualFolder = gace.VFS.VirtualFolder

VirtualFolder:include(gace.VFS.SimpleName)

function VirtualFolder:initialize(name)
    self.class.super.initialize(self)

    self:setName(name)
    self._entries = {}
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE
function VirtualFolder:capabilities()
    return caps
end

function VirtualFolder:listEntries(opts)
    return Promise(function(resolver)
        resolver:resolve(self._entries)
    end)
end

function VirtualFolder:createChildNode(name, type, opts)
    return Promise(function(resolver)
        if type == "file" then
            self._entries[name] = gace.VFS.MemoryFile:new(name)
            resolver:resolve()
            -- TODO call events
        elseif type == "folder" then
            self._entries[name] = gace.VFS.VirtualFolder:new(name)
            resolver:resolve()
            -- TODO call events
        else
            resolver:reject(gace.VFS.ReturnCode.INVALID_TYPE)
        end
    end)
end

function VirtualFolder:addVirtualFolder(name, vfolder)
    return Promise(function(resolver)
        self._entries[name] = vfolder
        resolver:resolve()
    end)
end

function VirtualFolder:deleteChildNode(name, opts)
    return Promise(function(resolver)
        if self._entries[name] then
            self._entries[name] = nil -- TODO call events
            resolver:resolve()
        else
            resolver:reject(gace.VFS.ReturnCode.NOT_FOUND)
        end
    end)
end
