gace.VFS.RealGIOFolder = Middleclass("RealGIOFolder", gace.VFS.Folder)
local RealGIOFolder = gace.VFS.RealGIOFolder

function RealGIOFolder:initialize(name, fsPath)
    if not gaceio then
        gace.Error("Trying to create RealGIOFolder without gaceio module!")
        return
    end

    self.class.super.initialize(self, name)

    self._fsPath = fsPath

    self._entries = {}
end

local caps = gace.VFS.Capability.READ + gace.VFS.Capability.WRITE + gace.VFS.Capability.REALFILE
function RealGIOFolder:capabilities()
    return caps
end

function RealGIOFolder:fsLocalChildPath(child)
    -- Ok this is a special case.
    -- Gaceio fsPath is usually "./garrysmod" oslt, which would get stripped by normalizer
    -- We don't want that, so we only normalize the child, except if it's empty

    local normchild = gace.path.normalize(child)
    return self._fsPath .. (normchild == "" and "" or ("/" .. normchild))
end

function RealGIOFolder:refresh()
    return ATPromise(function(resolver)
        local searchPath = self:fsLocalChildPath("")
        local files, folders = gaceio.List(searchPath)

        if not files then
            resolver:reject(folders)
            return
        end

        -- List of entries that dont exist on filesystem
        local leftovers = _u.keys(self._entries)

        -- Add unsynced file/folder to _entries and emit events
        local function AddEntry(name, type)
            table.RemoveByValue(leftovers, name)

            if self._entries[name] then return end

            local node

            if     type == "file"   then  node = gace.VFS.RealGIOFile(name)
            elseif type == "folder" then  node = gace.VFS.RealGIOFolder(name, self:fsLocalChildPath(name))
            end

            node:setParent(self)
            self._entries[name] = node

            self:emit("nodeCreated", node)
        end

        for _,v in pairs(folders) do
            AddEntry(v, "folder")
        end
        for _,v in pairs(files) do
            AddEntry(v, "file")
        end

        for _,lo in pairs(leftovers) do
            local node = self._entries[lo]
            self._entries[lo] = nil

            self:emit("nodeDeleted", node)
            node:emit("deleted")
        end

        resolver:resolve()
    end)
end

function RealGIOFolder:child(name, opts)
    return ATPromise(function(resolver)
        self:refresh():then_(function()
            local node = self._entries[name]
            if node then
                resolver:resolve(node)
            else
                resolver:reject(gace.VFS.ErrorCode.NOT_FOUND)
            end
        end)
    end)
end

function RealGIOFolder:listEntries(opts)
    return self:refresh():then_(function()
        return self._entries
    end)
end

function RealGIOFolder:createChildNode(name, type, opts)
    return ATPromise(function(resolver)
        if not self:validateChildName(name) then
            resolver:reject(gace.VFS.ErrorCode.INVALID_NAME)
            return
        end

        local localPath = self:fsLocalChildPath(name)
        if gaceio.Exists(localPath) then
            resolver:reject(gace.VFS.ErrorCode.ALREADY_EXISTS)
            return
        end

        if type == "file" then
            local ret, err = gaceio.Write(localPath, "")
            if ret == false then
                resolver:reject(err)
                return
            end

            self:refresh():then_(function()
                resolver:resolve(self._entries[name])
            end):catch(function(e) resolver:reject(e) end)
        elseif type == "folder" then
            local ret, err = gaceio.CreateDir(localPath)
            if ret == false then
                resolver:reject(err)
                return
            end

            self:refresh():then_(function()
                resolver:resolve(self._entries[name])
            end):catch(function(e) resolver:reject(e) end)
        else
            resolver:reject(gace.VFS.ErrorCode.INVALID_TYPE)
        end
    end)
end

function RealGIOFolder:deleteChildNode(node, opts)
    return ATPromise(function(resolver)
        local localPath = self:fsLocalChildPath(node:getName())

        if not gaceio.Exists(localPath) then
            resolver:reject(gace.VFS.ErrorCode.NOT_FOUND)
            return
        end

        local ret, err = gaceio.Delete(localPath)
        if ret == false then
            resolver:reject(err)
            return
        end

        self:refresh():then_(function()
            resolver:resolve()
        end)
    end)
end

function RealGIOFolder:realPath()
    return ATPromise(function(resolver)
        resolver:resolve(self._fsPath)
    end)
end
