gace.VFS.Node = Middleclass("Node")
local Node = gace.VFS.Node

-- Add event methods
Node:include(gace.EventEmitter)

function Node:initialize(name)
    self._name = name
    self._permissions = {
        ["server"] = gace.VFS.ServerPermission
    }
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

function Node:findRelevantPermission(target)
    if not IsValid(target) then
        if self._permissions.server then
            return self._permissions.server
        end
    else
        local group_node = string.format("group:%s", target:GetUserGroup())
        local player_node = string.format("player:%s", target:SteamID())

        local permissionField = 0

        if self._permissions[player_node] then
            permissionField = bit.bor(permissionField, self._permissions[player_node])
        end
        if self._permissions[group_node] then
            permissionField = bit.bor(permissionField, self._permissions[group_node])
        end
        if self._permissions.superadmins and target:IsSuperAdmin() then
            permissionField = bit.bor(permissionField, self._permissions.superadmins)
        end
        if self._permissions.admins and target:IsAdmin() then
            permissionField = bit.bor(permissionField, self._permissions.admins)
        end
        if self._permissions.players then
            permissionField = bit.bor(permissionField, self._permissions.players)
        end

        if permissionField ~= 0 then
            return permissionField
        end
    end

    local par = self:parent()
    if par and not par:hasCapability(gace.VFS.Capability.ROOT) then return par:findRelevantPermission(target) end
end
function Node:hasPermission(target, perm_bit)
    local perm = self:findRelevantPermission(target)
    if not perm then return false end

    return bit.band(perm, perm_bit) == perm_bit
end
function Node:checkPermission(target, perm_bit)
    return ATPromise(function(resolver)
        if self:hasPermission(target, perm_bit) then
            resolver:resolve()
        else
            resolver:reject(gace.VFS.ErrorCode.ACCESS_DENIED)
        end
    end)
end
function Node:grantPermission(perm_node, perm_bit)
    self._permissions[perm_node] = bit.bor((self._permissions[perm_node] or 0), perm_bit)

    self:emit("permissionsChanged")
end
function Node:revokePermission(perm_node, perm_bit)
    self._permissions[perm_node] = bit.band((self._permissions[perm_node] or 0), bit.bnot(perm_bit))

    self:emit("permissionsChanged")
end
function Node:grantPlayerPermission(ply, perm_bit)
    self:grantPermission(string.format("player:%s", ply:SteamID()), perm_bit)
end
function Node:grantGroupPermission(group, perm_bit)
    self:grantPermission(string.format("group:%s", group), perm_bit)
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
    local components = {}

    local par = self
    while par and not par:hasCapability(gace.VFS.Capability.ROOT) do
        table.insert(components, 1, par:getName())
        par = par:parent()
    end

    return table.concat(components, "/")
end

--- If node has CAPABILITY_REALFILE, returns absolute path to the real node
-- Can be relative to "GarrysMod" or absolute
function Node:realPath()
    return ATPromise(function(resolver)
        if not self:hasCapability(gace.VFS.Capability.REALFILE) then
            resolver:reject(gace.VFS.ErrorCode.INSUFFICIENT_CAPS)
            return
        end
        resolver:reject(string.format("%s#%s is not implemented", self.class.name, "realPath"))
    end)
end

function Node:delete()
    local par = self:parent()
    if not par then
        return ATPromise(function(resolver)
            resolver:reject("Unable to delete a node with no parent")
        end)
    end
    return par:deleteChildNode(self)
end

function Node:__tostring()
    return string.format("%s (path:%s) (cls:%s)", self:getName(), self:path(), self.class.name)
end
