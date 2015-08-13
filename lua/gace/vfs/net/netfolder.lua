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
    return ATPromise(function(resolver)
        gace.cmd.ls(LocalPlayer(), self:path()):then_(function(pl)
            local entries = pl.entries

            -- List of entries that dont exist on filesystem
            local leftovers = _u.keys(self._entries)

            -- Add unsynced file/folder to _entries and emit events
            local function AddEntry(name, type)
                table.RemoveByValue(leftovers, name)

                if self._entries[name] then return end

                local node

                if     type == "file"   then  node = gace.VFS.NetFile(name)
                elseif type == "folder" then  node = gace.VFS.NetFolder(name)
                end

                node:setParent(self)
                self._entries[name] = node

                self:emit("nodeCreated", node)
            end

            for nm,e in pairs(entries) do
                if e.type == "folder" then
                    AddEntry(nm, "folder")
                elseif e.type == "file" then
                    AddEntry(nm, "file")
                end
            end

            for _,lo in pairs(leftovers) do
                local node = self._entries[lo]
                self._entries[lo] = nil

                self:emit("nodeDeleted", node)
                node:emit("deleted")
            end

            resolver:resolve()
        end):catch(function(e) resolver:reject(e) end)
    end)
end

function NetFolder:child(name, opts)
    return ATPromise(function(resolver)
        local node = self._entries[name]
        if node then
            resolver:resolve(node)
        else
            resolver:reject(gace.VFS.ErrorCode.NOT_FOUND)
        end
    end)
end

function NetFolder:listEntries(opts)
    return ATPromise(self._entries)
end

function NetFolder:createChildNode(name, type, opts)
    return ATPromise(function(resolver)
    end)
end

function NetFolder:deleteChildNode(name, opts)
    return ATPromise(function(resolver)
    end)
end
