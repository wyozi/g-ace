gace.VFS.Node = Middleclass("Node")
local Node = gace.VFS.Node

-- Add event methods
Node:include(gace.EventEmitter)

Node.static.CAPABILITY_READ = bit.lshift(1, 0)
Node.static.CAPABILITY_WRITE = bit.lshift(1, 1)
-- If node has representation on filesystem
Node.static.CAPABILITY_REALFILE = bit.lshift(1, 2)

function Node:getDisplayName()
    return self:getName()
end
function Node:getName()
    return ""
end

function Node:getCapabilities()
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "getCapabilities"))
end
function Node:hasCapability(cap)
    return bit.band(self:getCapabilities(), cap) == cap
end

function Node:getParent()
    return self.parent
end

function Node:path()
    local components = {self:getName()}

    local par = self:getParent()
    while par do
        table.insert(components, 1, par:getName())
        par = par:getParent()
    end

    return table.concat(components, "/")
end
--- If node has CAPABILITY_REALFILE, returns absolute path to the real node
function Node:realPath()
    if not self:hasCapability(Node.CAPABILITY_REALFILE) then
        gace.Error(string.format("%s has no CAPABILITY_REALFILE!", self.class.name))
        return
    end
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "realPath"))
end
