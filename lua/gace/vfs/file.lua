gace.VFS.File = Middleclass("File", gace.VFS.Node)
local File = gace.VFS.File

function File:type()
    return "file"
end

function File:read(opts)
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "read"))
end

function File:write(data, opts)
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "write"))
end

function File:size()
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "size"))
end

function File:lastModified()
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "lastModified"))
end
