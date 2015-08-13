gace.VFS.RealGIOFile = Middleclass("RealGIOFile", gace.VFS.File)
local RealGIOFile = gace.VFS.RealGIOFile

function RealGIOFile:initialize(name)
    if not gaceio then
        gace.Error("Trying to create RealGIOFile without gaceio module!")
        return
    end

    self.class.super.initialize(self, name)
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE + gace.VFS.Capability.STAT + gace.VFS.Capability.REALFILE
function RealGIOFile:capabilities()
    return caps
end

function RealGIOFile:read(options)
    return ATPromise(function(resolver)
        local localPath = self:parent():fsLocalChildPath(self:getName())
        local ret, err = gaceio.Read(localPath)
        if ret == false then
            resolver:reject(err)
            return
        end
        resolver:resolve(ret)
    end)
end

function RealGIOFile:write(data, options)
    return ATPromise(function(resolver)
        local localPath = self:parent():fsLocalChildPath(self:getName())

        local ret, err = gaceio.Write(localPath, data)
        if ret == false then
            resolver:reject(err)
            return
        end
        resolver:resolve()
    end)
end

function RealGIOFile:size()
    return ATPromise(function(resolver)
        local ret, err = gaceio.Size(self:parent():fsLocalChildPath(self:getName()))
        if ret == false then
            resolver:reject(err)
            return
        end
        resolver:resolve(ret)
    end)
end

function RealGIOFile:lastModified()
    return ATPromise(function(resolver)
        local ret, err = gaceio.Time(self:parent():fsLocalChildPath(self:getName()))
        if ret == false then
            resolver:reject(err)
            return
        end
        resolver:resolve(ret)
    end)
end

function RealGIOFile:realPath()
    return ATPromise(function(resolver)
        resolver:resolve(self:parent():fsLocalChildPath(self:getName()))
    end)
end
