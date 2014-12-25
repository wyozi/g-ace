gace.VFS.Node = Middleclass("Node")
local Node = gace.VFS.Node

-- Add event methods
Node:include(gace.EventEmitter)

function Node:getName()
    gace.Error(string.format("%s#%s is not implemented", self.class.name, "getName"))
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
