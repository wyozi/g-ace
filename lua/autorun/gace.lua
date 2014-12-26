gace = gace or {}

local function load(file, type)
    type = type or "shared"

    local _server = type == "server" or type == "shared"
    local _client = type == "client" or type == "shared"

    if SERVER then
        if _client then AddCSLuaFile(file) end
        if _server then include(file) end
    end
    if CLIENT then
        if _client then include(file) end
    end
end

-- TODO move somewhere else
function gace.Error(str)
    ErrorNoHalt(str)
end

-- Load libraries
load("gace/_libs/middleclass.lua", "shared")
load("gace/_libs/andthen.lua", "shared")

-- Load GAce files
load("gace/cache/cache.lua")
load("gace/cache/cache_simple.lua")
load("gace/cache/cachesync_filesystem.lua")

load("gace/util/eventemitter.lua")
load("gace/util/path.lua")

load("gace/vfs/_vfs.lua")
load("gace/vfs/node.lua")
load("gace/vfs/file.lua")
load("gace/vfs/folder.lua")

load("gace/vfs/util/simplename.lua")

load("gace/vfs/virtual/virtualfile.lua")
load("gace/vfs/virtual/virtualfolder.lua")

load("gace/vfs/memory/memoryfile.lua")
load("gace/vfs/memory/memoryfolder.lua")

load("gace/vfs/real-data/realdatafile.lua")
load("gace/vfs/real-data/realdatafolder.lua")

-- Load GAce testing lib and tests
load("gace-tests/_gacetests.lua", "shared")
