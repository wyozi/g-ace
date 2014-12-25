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
            local created = gace.VFS.VirtualFile:new(name)
            self._entries[name] = created
            created:setParent(self)
            resolver:resolve()
            -- TODO call events
        elseif type == "folder" then
            local created = gace.VFS.VirtualFolder:new(name)
            self._entries[name] = created
            created:setParent(self)
            resolver:resolve()
            -- TODO call events
        else
            resolver:reject(gace.VFS.ReturnCode.INVALID_TYPE)
        end
    end)
end

function VirtualFolder:addVirtualFolder(vfolder)
    return Promise(function(resolver)
        local name = vfolder:getName()
        
        self._entries[name] = vfolder
        vfolder:setParent(self)
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
