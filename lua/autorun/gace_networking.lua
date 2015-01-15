if SERVER then util.AddNetworkString("gace_fileacc") end

net.Receive("gace_fileacc", function(len, cl)
	local reqid = net.ReadString()
	local op = net.ReadString()
	local payload = net.ReadTable()

	gace.Debug("Received net message ", op, " with reqid: ", reqid)
	if gace.IsDebug() then
		gace.Debug("Payload: ")
		PrintTable(payload)
	end

	local netmsg = gace.NetMessageIn(op, reqid, payload)

	if SERVER then
		netmsg:SetSender(cl)
	end

	gace.CallHook("HandleNetMessage", netmsg)
end)

function gace.SendNetMessage(netmsg)
	net.Start("gace_fileacc")

	gace.Debug("Sending net message ", netmsg:GetOpcode(), " with reqid ", netmsg:GetReqId())

	net.WriteString(netmsg:GetReqId() or "")
	net.WriteString(netmsg:GetOpcode())
	net.WriteTable(netmsg:GetPayload())

	if SERVER then
		net.Send(netmsg:GetTarget())
	else
		net.SendToServer()
	end
end
