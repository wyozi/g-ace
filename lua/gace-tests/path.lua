local gat = gace.AddTest

gat("Path library: validation", function(t)
    local gpv = gace.path.validate

	t.assertTrue(gpv("file"), "extensionless name")
    t.assertTrue(gpv("file.txt"), "normal name")
	t.assertTrue(gpv(".git"), "dot file")
    t.assertTrue(gpv("file-name.txt"), "name with a dash")
    t.assertTrue(gpv("file_name.txt"), "name with an underscore")

    t.assertTrue(gpv("path/file.txt"), "file path")
    t.assertFalse(gpv("path\\file.txt"), "backwards slash")

    t.assertFalse(gpv("äää.txt"), "name with non-ASCII")
end)

gat("Path library: component validation", function(t)
    local gpv = gace.path.validate_comp

	t.assertTrue(gpv("file"), "extensionless name")
    t.assertFalse(gpv("path/file.txt"), "file path")
end)

gat("Path library: normalization", function(t)
    local gpn = gace.path.normalize

	t.assertTrue(gpn("test") == "test", "return valid path as is")
	t.assertTrue(gpn("/test") == "test", "strip leading slash")
    t.assertTrue(gpn("test/") == "test", "strip trailing slash")

    t.assertTrue(gpn("abc\\def") == "abc/def", "convert backward slash to forward")

    t.assertTrue(gpn("abc//def") == "abc/def", "remove empty path components")

    t.assertTrue(gpn("abc/def/../ghi") == "abc/ghi", "double-dot notation")

    t.assertTrue(gpn("abc/def/./ghi") == "abc/def/ghi", "dot notation")
end)

gat("Path library: head/tail", function(t)
    local head, tail = gace.path.head, gace.path.tail

    t.assertTrue(head("a/b/c") == "a", "return valid head")
    t.assertTrue(select(2, head("a/b/c")) == "b/c", "return valid head rest")
    t.assertTrue(head("a") == "a", "return valid head (1-comp)")
    t.assertTrue(select(2, head("a")) == "", "return valid head rest (1-comp)")

    t.assertTrue(tail("a/b/c") == "c", "return valid tail")
    t.assertTrue(select(2, tail("a/b/c")) == "a/b", "return valid tail rest")
    t.assertTrue(tail("c") == "c", "return valid tail (1-comp)")
    t.assertTrue(select(2, tail("c")) == "", "return valid tail rest (1-comp)")
end)
