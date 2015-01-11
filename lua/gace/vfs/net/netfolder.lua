gace.VFS.NetFolder = Middleclass("NetFolder", gace.VFS.Folder)
local NetFolder = gace.VFS.NetFolder

function NetFolder:initialize(name)
    self.class.super.initialize(self, name)

    self._entries = {}
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE
function NetFolder:capabilities()
    local _caps = caps
    return _caps
end

function NetFolder:refresh()
    return Promise(function(resolver)
    end)
end

function NetFolder:child(name, opts)
    return Promise(function(resolver)
    end)
end

function NetFolder:listEntries(opts)
    return Promise(function(resolver)
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
