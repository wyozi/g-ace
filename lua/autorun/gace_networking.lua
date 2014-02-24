
gace.RequestCallbacks = gace.RequestCallbacks or {}

function gace.AddRequestCallback(reqid, fn, manual_del)
	gace.RequestCallbacks[reqid] = {fn=fn, manual_del = manual_del}
end

function gace.GenReqId(id)
	return util.CRC(id .. os.time() .. math.random())
end

if SERVER then util.AddNetworkString("gace_fileacc") end

net.Receive("gace_fileacc", function(len, cl)
	local reqid = net.ReadString()
	local op = net.ReadString()
	local payload = net.ReadTable()

	local cbtbl = gace.RequestCallbacks[reqid]

	gace.Debug("Received fileacc ", op, " with reqid: ", reqid, " resolving to req cb tbl: ", cbtbl)

	if cbtbl then
		cbtbl.fn(reqid, op, payload)
		if not cbtbl.manual_del or payload.mp_final then
			gace.RequestCallbacks[reqid] = nil
		end
		return
	end

	if SERVER then
		gace.HandleNetworking(cl, reqid, op, payload)
	else
		gace.HandleNetworking(reqid, op, payload)
	end
end)

function gace.Send(target, reqid, op, payload)
	net.Start("gace_fileacc")

	gace.Debug("Sending gace msg ", op, " with reqid ", reqid)

	net.WriteString(reqid)
	net.WriteString(op)
	net.WriteTable(payload)

	if SERVER then
		net.Send(target)
	else
		net.SendToServer()
	end
end