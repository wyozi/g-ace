gace.VFS.Node = Middleclass("Node")
local Node = gace.VFS.Node

-- Add event methods
Node:include(gace.EventEmitter)

function Node:initialize(name)
    self._name = name
end

function Node:displayName()
    return self:getName()
end

function Node:getName()
    return self._name
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
    return self._parent
end
function Node:setParent(par)
    self._parent = par
end

--- Traverses up the inheritance tree and tries to find the initial node that
-- was created using a constructor
function Node:findInitialFsNode()
    local n = self:type() == "folder" and self or self:parent()

    while n and not n:isInitialFsNode() do
        n = n:parent()
    end

    return n
end

function Node:path()
    local components = {self:getName()}

    local par = self:parent()
    while par and not par:hasCapability(gace.VFS.Capability.ROOT) do
        table.insert(components, 1, par:getName())
        par = par:parent()
    end

    return table.concat(components, "/")
end

--- If node has CAPABILITY_REALFILE, returns absolute path to the real node
-- Can be relative to "GarrysMod" or absolute
function Node:realPath()
    return Promise(function(resolver)
        if not self:hasCapability(gace.VFS.Capability.REALFILE) then
            resolver:reject(string.format("%s has no CAPABILITY_REALFILE!", self.class.name))
            return
        end
        resolver:reject(string.format("%s#%s is not implemented", self.class.name, "realPath"))
    end)
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

function Node:__tostring()
    return string.format("%s (%s)", self:path(), self.class.name)
end
