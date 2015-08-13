if CLIENT then
    gace.AddHook("PreCommandCall", "InterceptIPCCommands", function(cmd, opts, caller, r)
        if not opts.ipc then return end

        return ATPromise(function(resolver)
            gace.Debug("SEND IPC ", table.ToString(r))
            local netmsg = gace.NetMessageOut(opts.ipc, {args = r})
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
                gace.Debug("RECV IPC ", table.ToString(payload.args))
                cmd.callback_ipc(ply, netmsg, unpack(payload.args))
                break
            end
        end
    end)
end
