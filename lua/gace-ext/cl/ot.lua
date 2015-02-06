
gace.AddHook("FileTreeContextMenu", "FileTree_AddOTOptions", function(path, menu, nodetype)
    if nodetype ~= "file" then return end

    menu:AddOption("Collaborate on", function()
        local newpath = path .. ".ot"
        gace.OpenSession(newpath, {content=""})
    end):SetIcon("icon16/user_comment.png")
end)

local collab_mat = Material("icon16/group.png")
gace.AddHook("PreDrawTab", "HighlightOTTabs", function(tab, id)
    if id:EndsWith(".ot") then
        tab.TextLeftPadding = 20
    end
end)
gace.AddHook("PostDrawTab", "HighlightOTTabs", function(tab, id)
    if id:EndsWith(".ot") then
        surface.SetMaterial(collab_mat)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect(2, 2, 16, 16)
    end
end)

gace.AddHook("FileTreeFileNodePostPaint", "OT_FileNodeIcon", function(node, vars)
    if not node.NodeId:EndsWith(".ot") then return end

    surface.SetMaterial(collab_mat)
    surface.SetDrawColor(255, 255, 255)
    surface.DrawTexturedRect(vars.draw_x + 16, 10, 12, 12)
end)

gace.AddHook("SetupHTMLPanel", "OT_Funcs", function(html)
    html:AddFunction("gaceot", "Subscribe", function(id)
        gace.SendRequest("ot-sub", {id = id}, function(_, _, pl)
            if pl.err then
                gace.Log(gace.LOG_ERROR, "Failed to subscribe to ot: ", pl.err)
                return
            end
            gace.Log(gace.LOG_INFO, "Subscribed to gace-ot ", id)
            gace.JSBridge().gaceCollaborate.onSubscribed(id, {rev = pl.rev, doc = pl.doc})
        end)
    end)
    html:AddFunction("gaceot", "UnSubscribe", function(id)
        gace.SendRequest("ot-unsub", {id = id})
    end)
    html:AddFunction("gaceot", "Send", function(id, rev, op)
        gace.Debug("Sending ot-apply for " .. id .. " with rev " .. rev)
        gace.SendRequest("ot-apply", {
            id = id,
            rev = rev,
            op = util.JSONToTable(op)
        })
    end)
    html:AddFunction("gaceot", "UpdateCursor", function(id, start, _end)
        gace.SendRequest("ot-cursor", {
            id = id,
            start = start,
            ["end"] = _end
        })
    end)
end)

gace.AddHook("HandleNetMessage", "HandleOT", function(netmsg)
    local op = netmsg:GetOpcode()
    local reqid = netmsg:GetReqId()
    local payload = netmsg:GetPayload()

    if op == "ot-applysv" then
        local ret = {
            id = payload.id,
            op = payload.op
        }
        if payload.user ~= LocalPlayer() then
            ret.user = payload.user:SteamID()
        end

        gace.JSBridge().gaceCollaborate.operationReceived(ret)
    elseif op == "ot-cursorsv" then
        local cursor = payload.cursor
        gace.JSBridge().gaceCollaborate.updateCursor(payload.id, tostring(payload.cursorid), cursor.start, cursor["end"])
    end
end)
