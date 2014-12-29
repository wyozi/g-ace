gace.VFS.VirtualFolder = Middleclass("VirtualFolder", gace.VFS.Folder)
local VirtualFolder = gace.VFS.VirtualFolder

function VirtualFolder:initialize(name, is_root)
    self.class.super.initialize(self, name)

    self._entries = {}

    self._root = is_root
    if is_root then
        self:grantPermission("players", gace.VFS.Permission.READ)
    end
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE
function VirtualFolder:capabilities()
    local _caps = caps
    if self._root then _caps = _caps + gace.VFS.Capability.ROOT end
    return _caps
end

function VirtualFolder:refresh() end

function VirtualFolder:child(name, opts)
    return Promise(function(resolver)
        local node = self._entries[name]
        if node then
            resolver:resolve(node)
        else
            resolver:reject(gace.VFS.ErrorCode.NOT_FOUND)
        end
    end)
end

function VirtualFolder:listEntries(opts)
    return Promise(function(resolver)
        resolver:resolve(self._entries)
    end)
end

function VirtualFolder:createChildNode(name, type, opts)
    return Promise(function(resolver)
        local ctor

        if type == "file" then
            ctor = gace.VFS.VirtualFile
        elseif type == "folder" then
            ctor = gace.VFS.VirtualFolder
        end

        if ctor then
            local node = ctor(name)

            node:setParent(self)
            self._entries[name] = node
            self:emit("nodeCreated", node)

            resolver:resolve(node)
        else
            resolver:reject(gace.VFS.ErrorCode.INVALID_TYPE)
        end
    end)
end

function VirtualFolder:addVirtualFolder(vfolder)
    return Promise(function(resolver)
        local name = vfolder:getName()

        self._entries[name] = vfolder
        vfolder:setParent(self)
        resolver:resolve()
    end)
end

function VirtualFolder:deleteChildNode(name, opts)
    return Promise(function(resolver)
        if self._entries[name] then
            local node = self._entries[name]
            self._entries[name] = nil

            self:emit("nodeDeleted", node)
            node:emit("deleted")

            resolver:resolve()
        else
            resolver:reject(gace.VFS.ErrorCode.NOT_FOUND)
        end
    end)
end