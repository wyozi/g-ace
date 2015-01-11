gace.VFS.NetFile = Middleclass("NetFile", gace.VFS.File)
local NetFile = gace.VFS.NetFile

function NetFile:initialize(name)
    self.class.super.initialize(self, name)

    self.lastModified = os.time()
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE + gace.VFS.Capability.STAT
function NetFile:capabilities()
    return caps
end

function NetFile:read(options)
    return Promise(function(resolver)
    end)
end

function NetFile:write(data, options)
    return Promise(function(resolver)
    end)
end

function NetFile:size()
    return Promise(function(resolver)
    end)
end

function NetFile:lastModified()
    return Promise(function(resolver)
    end)
end
