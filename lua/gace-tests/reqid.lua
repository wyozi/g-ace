local gat = gace.AddTest

gat("NetObj Request Ids: uniqueness", function(t)
    local f = gace.reqid.generate()
    local s = gace.reqid.generate()
    t.assertNonEqual(f, s, "two reqids generated in row should not be equal")
end)

gat("NetObj Request Ids: validation", function(t)
    t.assertTrue(gace.reqid.validate(gace.reqid.generate()), "just-generated reqid should pass validation")

    t.assertTrue(gace.reqid.validate("dfFASD_Ferwgwegää¨ää4#¤**^¤324"), "can be an arbitrary string")

    t.assertFalse(gace.reqid.validate(true), "can't be non-string [bool]")
    t.assertFalse(gace.reqid.validate(32), "can't be non-string [number]")

    t.assertFalse(gace.reqid.validate(nil), "can't be nil")
    t.assertFalse(gace.reqid.validate(""), "can't be an empty string")
end)
