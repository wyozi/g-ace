gace.VFS.File = Middleclass("File", gace.VFS.Node)
local File = gace.VFS.File

function File:read(opts)
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "read"))
end

function File:write(data, opts)
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "write"))
end
