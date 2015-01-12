local gat = gace.AddTest

gat("NetMessage object: Validate parameters", function(t)
    local constructors = {"NetMessageIn", "NetMessageOut"}

    for _,c in pairs(constructors) do
        local cfunc = gace[c]

        t.assertError(cfunc, "no error when calling gace." .. c .. "(nil, nil)")
        t.assertError(cfunc, "error when calling gace." .. c .. "(\"\", nil)", "")
        t.assertNoError(cfunc, "no error when calling gace." .. c .. "(nil, \"\")", nil, "")

        t.assertNoError(cfunc, "no error when calling gace." .. c .. "(\"\", \"\")", "", "")
    end
end)

gat("NetMessage object: Sending", function(t)
    local netmsg = gace.NetMessageOut(0, "", {})
    t.assertTrue(not netmsg.sent, "'sent' false before calling :Send()")

    -- We imitate having already sent the net message by setting 'sent' directly
    netmsg.sent = true
    t.assertError(netmsg.Send, "trying to send more than once errors", netmsg)
end)
