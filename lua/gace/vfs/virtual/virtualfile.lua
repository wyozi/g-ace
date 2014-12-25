gace.VFS.VirtualFile = Middleclass("VirtualFile", gace.VFS.File)
local VirtualFile = gace.VFS.VirtualFile

VirtualFile:include(gace.VFS.SimpleName)

function VirtualFile:initialize(name)
    self.class.super.initialize(self)

    self:setName(name)
    self.lastModified = os.time()
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE + gace.VFS.Capability.STAT
function VirtualFile:capabilities()
    return caps
end

function VirtualFile:read(options)
    return Promise(function(resolver)
        resolver:resolve(self._contents or "")
    end)
end

function VirtualFile:write(data, options)
    return Promise(function(resolver)
        self._contents = data
        self.lastModified = os.time()
        resolver:resolve()
    end)
end

function VirtualFile:size()
    return Promise(function(resolver)
        resolver:resolve(string.len(self._contents or ""))
    end)
end

function VirtualFile:lastModified()
    return Promise(function(resolver)
        resolver:resolve(self.lastModified)
    end)
end
