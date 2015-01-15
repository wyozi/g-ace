local gat = gace.AddTest

gat("Networking: request id uniqueness", function(t)
    local f = gace.GenReqId()
    local s = gace.GenReqId()
    t.assertNonEqual(f, s, "two reqids generated in row should not be equal")
end)

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

    local netmsg = gace.NetMessageOut("", {}, _protocol)

    netmsg:Send()
    t.assertError(netmsg.Send, "trying to send more than once errors", netmsg)
end)

gat("NetMessage object: response message", function(t)
    local _protocol = CreateProtocolStub(function(netmsg) end, function(netmsg, callback) end)

    local netmsg = gace.NetMessageIn("test_op", "test_reqid", {})

    local response_msg = netmsg:CreateResponseMessage(nil, {})
    t.assertEquals(response_msg:GetOpcode(), netmsg:GetOpcode(), "use request's opcode if not given")

    local response_msg = netmsg:CreateResponseMessage("new_op", {})
    t.assertEquals(response_msg:GetOpcode(), "new_op", "use explicitly given opcode if given")

    local response_msg = netmsg:CreateResponseMessage(nil, {})
    t.assertEquals(response_msg:GetReqId(), netmsg:GetReqId(), "use request's reqid for response")

    local response = gace.NetMessageOut("test_op", {})
    t.assertNil(response:GetReqId(), "out message should not have reqid by default")

    local response = gace.NetMessageOut("test_op", {}, _protocol)
    response:ListenToResponse(function() end)
    t.assertNonNil(response:GetReqId(), "listening to response should compute a reqid if it's nonexistent")

    local response = gace.NetMessageOut("test_op", {}, _protocol)
    response:SetReqId("--reqid--")
    response:ListenToResponse(function() end)
    t.assertEquals(response:GetReqId(), "--reqid--", "listening to response should use existent reqid if it exists")
end)
