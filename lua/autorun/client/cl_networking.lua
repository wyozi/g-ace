function gace.SendRequest(op, payload, cb)
	local reqid = 0
	if cb then
		reqid = gace.GenReqId(op)
		gace.AddRequestCallback(reqid, cb)
	end
	gace.Send(nil, reqid, op, payload)
end

function gace.HandleNetworking(reqid, op, payload)
end