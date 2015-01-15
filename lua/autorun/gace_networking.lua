
gace.RequestCallbacks = gace.RequestCallbacks or {}

local req_num = 0
function gace.GenReqId()
	req_num = req_num + 1
	return math.floor(CurTime()) .. "_" .. req_num
end

if SERVER then util.AddNetworkString("gace_fileacc") end

net.Receive("gace_fileacc", function(len, cl)
	local reqid = net.ReadString()
	local op = net.ReadString()
	local payload = net.ReadTable()

	local cbtbl = gace.RequestCallbacks[reqid]

	gace.Debug("Received net message ", op, " with reqid: ", reqid, " resolving to req cb tbl: ", cbtbl)
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

	net.WriteString(netmsg:GetReqId())
	net.WriteString(netmsg:GetOpcode())
	net.WriteTable(netmsg:GetPayload())

	if SERVER then
		net.Send(netmsg:GetTarget())
	else
		net.SendToServer()
	end
end
