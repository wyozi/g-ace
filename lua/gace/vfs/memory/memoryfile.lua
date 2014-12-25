gace.VFS.MemoryFile = Middleclass("MemoryFile", gace.VFS.File)
local MemoryFile = gace.VFS.MemoryFile

function MemoryFile:read(options)
    return Promise(function(resolver)
        resolver:resolve(self._contents or "")
    end)
end

function MemoryFile:write(data, options)
    return Promise(function(resolver)
        self._contents = data
        resolver:resolve()
    end)
end
