
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
		surface.DrawTexturedRect(3, 3, 16, 16)
	end
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
                "gaceCollaborate.onSubscribed(\"" .. gace.JSEscape(id) .. "\", \"" .. gace.JSEscape(util.TableToJSON {
        			rev = pl.rev,
        			doc = pl.doc
        		}) .. "\")"
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

    if op == "ot-apply" then
        local ret = {
            id = payload.id,
            op = payload.op
        }
        if payload.user ~= LocalPlayer() then
            ret.user = payload.user:SteamID()
        end

        gace.RunJavascript(
            "gaceCollaborate.operationReceived(\"" .. gace.JSEscape(util.TableToJSON(ret)) .. "\")"
        )
    elseif op == "ot-cursor" then
        local cursor = payload.cursor
        local js = "gaceCollaborate.updateCursor(\"" .. gace.JSEscape(payload.id) .. "\", \"" .. gace.JSEscape(tostring(payload.cursorid)) .. "\", " .. (cursor.start) .. ", " .. cursor["end"] .. ")"

        gace.RunJavascript(
            js
        )
    end
end)