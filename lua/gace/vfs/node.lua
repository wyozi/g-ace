gace.VFS.Node = Middleclass("Node")
local Node = gace.VFS.Node

-- Add event methods
Node:include(gace.EventEmitter)

function Node:displayName()
    return self:getName()
end
function Node:getName()
    return ""
end

function Node:type()
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "type"))
end

function Node:capabilities()
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "capabilities"))
end
function Node:hasCapability(cap)
    return bit.band(self:capabilities(), cap) == cap
end

function Node:parent()
    return self.parent
end

function Node:path()
    local components = {self:getName()}

    local par = self:parent()
    while par do
        table.insert(components, 1, par:getName())
        par = par:parent()
    end

    return table.concat(components, "/")
end
--- If node has CAPABILITY_REALFILE, returns absolute path to the real node
function Node:realPath()
    if not self:hasCapability(gace.VFS.Capability.REALFILE) then
        gace.Error(string.format("%s has no CAPABILITY_REALFILE!", self.class.name))
        return
    end
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "realPath"))
end

function Node:delete()
    local par = self:parent()
    if not par then
        return Promise(function(resolver)
            resolver:reject("Unable to delete a node with no parent")
        end)
    end
    return par:deleteChildNode(self)
end
