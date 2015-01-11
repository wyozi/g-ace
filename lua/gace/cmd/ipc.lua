if CLIENT then
    local reqid = 0
    local function IpcReq()
        reqid = reqid + 1
        return "ipc_" .. math.floor(CurTime()*100) .. "_" .. (reqid)
    end

    gace.AddHook("PreCommandCall", "InterceptIPCCommands", function(cmd, opts, caller, r)
        if not opts.ipc then return end

        return Promise(function(resolver)
            local reqid = IpcReq()

            local netmsg = gace.NetMessageOut(reqid, opts.ipc, {args = r})
        	netmsg:ListenToResponse(function(_, _, pl)
                if pl.err then
                    resolver:reject(pl.err)
                else
                    resolver:resolve(pl)
                end
            end)
        	netmsg:Send()
        end)
    end)
end

if SERVER then
    gace.AddHook("HandleNetMessage", "HandleIPC", function(netmsg)
    	local ply = netmsg:GetSender()
    	local op = netmsg:GetOpcode()
    	local reqid = netmsg:GetReqId()
    	local payload = netmsg:GetPayload()

        for _,cmd in pairs(gace.cmd.Commands) do
            if cmd.ipc == op then
                cmd.callback_ipc(ply, netmsg, unpack(payload.args))
                break
            end
        end
    end)
end
