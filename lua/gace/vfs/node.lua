gace.VFS.Node = Middleclass("Node")
local Node = gace.VFS.Node

-- Add event methods
Node:include(gace.EventEmitter)

function Node:getName()
end
