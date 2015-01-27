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
