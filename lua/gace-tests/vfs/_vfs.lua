local gat = gace.AddTest

function gace.CreateVFSClassTests(cls, data)
    gat("VFS Class: " .. cls, function(t)
        t.async()
        t.done()

    end)
end

function gace.CreateVFSFakePly(params)
    return {
        IsValid = function()
            return not params.server
        end,
        IsAdmin = function()
            return params.admin or params.superadmin
        end,
        IsSuperAdmin = function()
            return params.superadmin
        end,
        SteamID = function()
            return params.steamid or "STEAM_0:1:1"
        end,
        GetUserGroup = function()
            return params.group or "user" -- ??
        end
    }
end
