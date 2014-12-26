gace.VFS.RealDataFile = Middleclass("RealDataFile", gace.VFS.File)
local RealDataFile = gace.VFS.RealDataFile

RealDataFile:include(gace.VFS.SimpleName)

function RealDataFile:initialize(name)
    self.class.super.initialize(self)

    self:setName(name)
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE + gace.VFS.Capability.STAT
function RealDataFile:capabilities()
    return caps
end

function RealDataFile:read(options)
    return Promise(function(resolver)
        local localPath = self:parent():fsLocalChildPath(self:getName())
        resolver:resolve(file.Read(localPath, "DATA"))
    end)
end

function RealDataFile:write(data, options)
    return Promise(function(resolver)
        local localPath = self:parent():fsLocalChildPath(self:getName())

        file.Write(localPath, data)
        resolver:resolve()
    end)
end

function RealDataFile:size()
    return Promise(function(resolver)
        resolver:resolve(file.Size(self:parent():fsLocalChildPath(self:getName()), "DATA"))
    end)
end

function RealDataFile:lastModified()
    return Promise(function(resolver)
        resolver:resolve(file.Time(self:parent():fsLocalChildPath(self:getName()), "DATA"))
    end)
end
