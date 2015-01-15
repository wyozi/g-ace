function gace.SendRequest(op, payload, cb)
	local netmsg = gace.NetMessageOut(op, payload)
	if cb then netmsg:ListenToResponse(cb) end
	netmsg:Send()
end
