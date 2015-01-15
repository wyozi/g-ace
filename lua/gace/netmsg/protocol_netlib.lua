gace.NetMsgListeners = {}
gace.AddHook("HandleNetMessage", "_ResponseToListeners", function(packet)
    local listener = gace.NetMsgListeners[packet:GetReqId()]
    if listener then
        listener(packet:GetReqId(), packet:GetOpcode(), packet:GetPayload())
    end
end)

gace.NetMessageDefaultProtocol = {
    Send = function(netmsg)
        gace.SendNetMessage(netmsg)
    end,
    Listen = function(netmsg, callback)
        gace.NetMsgListeners[netmsg:GetReqId()] = callback
    end
}
