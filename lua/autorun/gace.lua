gace = gace or {}
gace.RequestCallbacks = gace.RequestCallbacks or {}

function gace.AddRequestCallback(reqid, fn)
	gace.RequestCallbacks[reqid] = fn
end

function gace.GenReqId(id)
	return util.CRC(id .. os.time() .. math.random())
end

function gace.Debug(...)
	--MsgN("GACE DEBUG: ", ...)
end

if SERVER then util.AddNetworkString("gace_fileacc") end

net.Receive("gace_fileacc", function(len, cl)
	local reqid = net.ReadString()
	local op = net.ReadString()
	local payload = net.ReadTable()

	local cbfn = gace.RequestCallbacks[reqid]

	gace.Debug("Received fileacc ", op, " with reqid: ", reqid, " resolving to req cb fn: ", cbfn)

	if cbfn then
		gace.RequestCallbacks[reqid] = nil
		cbfn(reqid, op, payload)
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