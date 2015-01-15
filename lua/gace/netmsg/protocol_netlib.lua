gace.NetMsgListeners = {}
gace.AddHook("HandleNetMessage", "_ResponseToListeners", function(packet)
    local listener = gace.NetMsgListeners[packet:GetReqId()]
    if listener then
        listener(packet:GetReqId(), packet:GetOpcode(), packet:GetPayload())
    end
end)

gace.NetMessageDefaultProtocol = {}
local protocol = gace.NetMessageDefaultProtocol

function protocol.Send(netmsg)
    gace.SendNetMessage(netmsg)
end
function protocol.Listen(netmsg, callback)
    gace.NetMsgListeners[netmsg:GetReqId()] = callback
end

function protocol.EstimateMessageSize(payload)
    local t = type(payload)

    if t == "table" then
        local size = 0
        for k, v in pairs(payload) do
            size = size + protocol.EstimateMessageSize(k)
            size = size + protocol.EstimateMessageSize(v)
        end
        return size
    elseif t == "string" then
        return #t -- lua is "nice" and returns size in bytes instead of individual chars
    end

    -- this is an estimation, we dont really care about few byte differences
    return 4
end
