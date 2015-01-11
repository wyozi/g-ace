gace.VFS.NetFolder = Middleclass("NetFolder", gace.VFS.Folder)
local NetFolder = gace.VFS.NetFolder

function NetFolder:initialize(name, is_root)
    self.class.super.initialize(self, name)

    self._entries = {}

    self._root = is_root
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE
function NetFolder:capabilities()
    local _caps = caps
    if self._root then _caps = _caps + gace.VFS.Capability.ROOT end
    return _caps
end

function NetFolder:refresh()
    return Promise(function(resolver)
        gace.cmd.ls(LocalPlayer(), self:path()):then_(function(entries)
            
        end):catch(function(e) resolver:reject(e) end)
    end)
end

function NetFolder:child(name, opts)
    return Promise(function(resolver)
    end)
end

function NetFolder:listEntries(opts)
    return self:refresh():then_(function()
        return self._entries
    end)
end

function NetFolder:createChildNode(name, type, opts)
    return Promise(function(resolver)
    end)
end

function NetFolder:deleteChildNode(name, opts)
    return Promise(function(resolver)
    end)
end
