gace.AddHook("HandleNetMessage", "HandleCollaboratorNotifications", function(netmsg)
    local ply = netmsg:GetSender()
    local op = netmsg:GetOpcode()
    local reqid = netmsg:GetReqId()
    local payload = netmsg:GetPayload()

	if op == "collab-notify-listen" then
		ply._GAceCollabNotifyListener = true
    elseif op == "collab-notify-open" then
        local normpath = gace.path.normalize(payload.path)
        
		local msg = gace.NetMessageOut("collab-notify-open", { player = ply, path = normpath })
        for _,p in pairs(player.GetHumans()) do
        	if p._GAceCollabNotifyListener then
        		msg:Clone():Send(p)
        	end
        end
    end
end)
