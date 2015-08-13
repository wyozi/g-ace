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

function Folder:validateChildName(name)
    return #name >= 1 and gace.path.validate_comp(name)
end

function Folder:createChildNode(name, type, opts)
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "createChildNode"))
end

function Folder:deleteChildNode(node, opts)
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "deleteChildNode"))
end

-- Alright, this is a bit hacky
-- To figure out if this node is the initial root folder of a VFS
-- (ie this is the node that was created using a constructor in vfs.lua)
-- we check if parent is not same class as this node
--
-- Because parents can only be foldernodes, this should work
function Folder:isInitialFsNode()
    local par = self:parent()
    if not par then return false end

    return self.class ~= par.class
end

--- Creates child node if it doesnt exist.
function Folder:verifyChildFileExists(name)
    return self:child(name):then_(function(node)
        if node:type() == "file" then
            return node
        end
        return gace.RejectedATPromise(gace.VFS.ErrorCode.INVALID_TYPE)
    end):catch(function(e)
        if e == gace.VFS.ErrorCode.NOT_FOUND then
            return self:createChildNode(name, "file"):then_(function(node)
                return node
            end)
        end
    end)
end
