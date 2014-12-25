gace = gace or {}

local function load(file, type)
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

-- Load GAce files
load("gace/cache/cache.lua", "shared")
load("gace/cache/cache_simple.lua", "shared")
load("gace/cache/cachesync_filesystem.lua", "shared")

-- Load GAce testing lib and tests
load("gace-tests/_gacetests.lua", "shared")
