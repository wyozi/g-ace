gace.VFS.MemoryFile = Middleclass("MemoryFile", gace.VFS.File)
local MemoryFile = gace.VFS.MemoryFile

MemoryFile:include(gace.VFS.SimpleName)

function MemoryFile:initialize(name)
    self.class.super.initialize(self)

    self:setName(name)
    self.lastModified = os.time()
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE + gace.VFS.Capability.STAT
function MemoryFile:capabilities()
    return caps
end

function MemoryFile:read(options)
    return Promise(function(resolver)
        resolver:resolve(self._contents or "")
    end)
end

function MemoryFile:write(data, options)
    return Promise(function(resolver)
        self._contents = data
        self.lastModified = os.time()
        resolver:resolve()
    end)
end

function File:size()
    return Promise(function(resolver)
        resolver:resolve(string.len(self._contents or ""))
    end)
end

function File:lastModified()
    return Promise(function(resolver)
        resolver:resolve(self.lastModified)
    end)
end
