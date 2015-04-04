local gat = gace.AddTest

gat("Utils", function(t)
	t.assertEquals({1,2,3}, {1,2,3}, "sequentical table equality")
	t.assertEquals({a=1}, {a=1}, "string indexed table equality")
	t.assertNonEqual({1,2,3}, {1,2,3,4}, "sequentical table nonequality")
	t.assertNonEqual({a=1}, {a=2}, "string indexed table nonequality")

	t.assertEquals({}, {}, "empty table equality")
	t.assertNonEqual({{}}, {{}}, "empty subtable nonequality")

	t.assertDeepEquals({}, {}, "empty table deep equality")
	t.assertNonDeepEqual({}, {{}}, "subtable deep nonequality")
	t.assertDeepEquals({{}}, {{}}, "subtable deep equality")
	t.assertNonDeepEqual({1}, {}, "deep nonequality")
	t.assertDeepEquals({1, 2, 3}, {1, 2, 3}, "single-dim table equality")
	t.assertDeepEquals({1, {2, 3}}, {1, {2, 3}}, "multi-dim table equality")
	t.assertDeepEquals({a={b={c="hi"}}}, {a={b={c="hi"}}}, "string-key table equality")

	t.assertEquals(
		gace.JSEscape([[ {"key1": "val1", "key2": "{\"subkey\": \"subvalue\"}"} ]]),
		[[ {\"key1\": \"val1\", \"key2\": \"{\\\"subkey\\\": \\\"subvalue\\\"}\"} ]],
		"escape a JSON string"
	)
end)

-- Return second element from varargs
local function sec(...)
	return select(2, ...)
end

gat("Utils: entitypath", function(t)
	local analyze = gace.entitypath.Analyze

	t.assertEquals(analyze("testent.lua"), "testent", "single-comp entity file")
	t.assertEquals(analyze("shared.lua"), "shared", "single-comp entity file (shared)")

	t.assertEquals(analyze("testent/shared.lua"), "testent", "double-comp entity folder (sh)")
	t.assertEquals(analyze("testent/cl_init.lua"), "testent", "double-comp entity folder (cl)")
	t.assertEquals(analyze("testent/init.lua"), "testent", "double-comp entity folder (sv)")

	t.assertEquals(analyze("this/is/a/path/testent.lua"), "testent", "multi-comp entity file")
	t.assertEquals(analyze("this/is/a/path/testent/shared.lua"), "testent", "multi-comp entity folder")

	t.assertEquals(sec(analyze("testent.lua")), "sh", "entity file realm")
	t.assertEquals(sec(analyze("testent/shared.lua")), "sh", "entity folder realm (sh)")
	t.assertEquals(sec(analyze("testent/cl_init.lua")), "cl", "entity folder realm (cl)")
	t.assertEquals(sec(analyze("testent/init.lua")), "sv", "entity folder realm (sv)")
end)

gat("Utils: entitypath includes", function(t)
	local finc = gace.entitypath.FindIncludes

	t.assertDeepEquals(finc([[ include("shared.lua") ]]), {"shared.lua"}, "normal file")
	t.assertDeepEquals(finc([[ include("cl_init.lua") ]]), {"cl_init.lua"}, "underscore file")
	t.assertDeepEquals(finc([[ include("shared.lua") include("cl_init.lua") ]]), {"shared.lua", "cl_init.lua"}, "double include")

	t.assertDeepEquals(finc([[ include( "cl_init.lua" ) ]]), {"cl_init.lua"}, "spaces around filename")
	t.assertDeepEquals(finc([[ include"cl_init.lua" ]]), {"cl_init.lua"}, "omitted braces")

	t.assertDeepEquals(finc([[ include"folder/cl_init.lua" ]]), {}, "omitted subfolder include")
end)