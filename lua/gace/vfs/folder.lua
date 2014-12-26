gace.VFS.Folder = Middleclass("Folder", gace.VFS.Node)
local Folder = gace.VFS.Folder

function Folder:type()
    return "folder"
end

function Folder:listEntries(opts)
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "listEntries"))
end

function Folder:createChildNode(name, type, opts)
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "createChildNode"))
end

function Folder:deleteChildNode(node, opts)
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "deleteChildNode"))
end
