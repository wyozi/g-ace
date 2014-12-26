gace.VFS.Folder = Middleclass("Folder", gace.VFS.Node)
local Folder = gace.VFS.Folder

function Folder:type()
    return "folder"
end

--- Refreshes folder contents.
-- Mostly used to make sure in-memory entries match what's on filesystem
-- That means it can be no-op if there's no backing filesystem
function Folder:refresh()
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "refresh"))
end

function Folder:child(name, opts)
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "child"))
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
