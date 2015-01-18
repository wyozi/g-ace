
gace.AddHook("FileTreeContextMenu", "FileTree_AddOTOptions", function(path, menu, nodetype)
	if nodetype ~= "file" then return end

	menu:AddOption("Collaborate on", function()
        local newpath = path .. ".ot"
        gace.OpenSession(newpath, {content=""})
	end):SetIcon("icon16/user_comment.png")
end)

gace.AddHook("SetupHTMLPanel", "OT_Funcs", function(html)
    html:AddFunction("gaceot", "Subscribe", function(id)
        gace.SendRequest("ot-sub", {id = id}, function(_, _, pl)
            if pl.err then
                gace.Log(gace.LOG_ERROR, "Failed to subscribe to ot: ", pl.err)
                return
            end
            gace.Log(gace.LOG_INFO, "Subscribed to gace-ot ", id)
            gace.RunJavascript(
                "gaceCollaborate.onSubscribed('" .. id .. "', '" .. util.TableToJSON {
        			rev = pl.rev,
        			doc = pl.doc
        		} .. "')"
            )
        end)
    end)
    html:AddFunction("gaceot", "Send", function(id, rev, op)
        gace.SendRequest("ot-apply", {
            id = id,
            rev = rev,
            op = util.JSONToTable(op)
        })
    end)
end)

gace.AddHook("HandleNetMessage", "HandleOT", function(netmsg)
	local op = netmsg:GetOpcode()
	local reqid = netmsg:GetReqId()
	local payload = netmsg:GetPayload()

    if op == "ot-apply" then
        local ret = {
            id = payload.id,
            op = payload.op
        }
        if payload.user ~= LocalPlayer() then
            ret.user = payload.user:SteamID()
        end

        local json = util.TableToJSON(ret)
        json = json:Replace("\\", "\\\\")
        gace.RunJavascript(
            "gaceCollaborate.operationReceived('" .. json .. "')"
        )
    end
end)
