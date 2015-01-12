function gace.SendRequest(op, payload, cb)
	local reqid = cb and gace.GenReqId(op) or 0

	local netmsg = gace.NetMessageOut(op, reqid, payload)
	if cb then netmsg:ListenToResponse(cb) end
	netmsg:Send()
end

function gace.SendMultiPartRequest(op, payload, cb)
	-- TODO add the actual multipartness lol
	local reqid = cb and gace.GenReqId(op) or 0

	local netmsg = gace.NetMessageOut(op, reqid, payload)
	if cb then netmsg:ListenToResponse(cb) end
	netmsg:Send()
end
