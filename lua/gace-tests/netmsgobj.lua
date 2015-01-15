local gat = gace.AddTest

gat("NetMessage object: validate parameters", function(t)
    local constructors = {"NetMessageIn", "NetMessageOut"}

    for _,c in pairs(constructors) do
        local cfunc = gace[c]

        t.assertError(cfunc, "error when calling gace." .. c .. "(nil, nil)")
        t.assertError(cfunc, "error when calling gace." .. c .. "(nil, \"\")", nil, "")
        t.assertNoError(cfunc, "no error when calling gace." .. c .. "(\"\", nil)", "", nil)

        t.assertNoError(cfunc, "no error when calling gace." .. c .. "(\"\", \"\")", "", "")
    end
end)

local function CreateProtocolStub(send, listen)
    return {
        Send = send,
        Listen = listen
    }
end

gat("NetMessage object: sending", function(t)
    local _protocol = CreateProtocolStub(function(netmsg) end, function(netmsg, callback) end)

    local netmsg = gace.NetMessageOut("", 0, {}, _protocol)

    netmsg:Send()
    t.assertError(netmsg.Send, "trying to send more than once errors", netmsg)
end)
