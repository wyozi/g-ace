local gat = gace.AddTest

if SERVER then
    gat("Operational transformation: utf8 support", function(t)
        t.assertEquals(gace.ot.TextOperation.opLen("äöå"), 3, "utf8 characters should count as single characters")
    end)
end
