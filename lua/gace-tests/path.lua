local gat = gace.AddTest

gat("Path library: validation", function(t)
    local gpv = gace.path.validate

	t.assertTrue(gpv("file"), "extensionless name")
    t.assertTrue(gpv("file.txt"), "normal name")
	t.assertTrue(gpv(".git"), "dot file")
    t.assertTrue(gpv("file-name.txt"), "name with a dash")
    t.assertTrue(gpv("file_name.txt"), "name with an underscore")

    t.assertTrue(gpv("path/file.txt"), "file path")
    t.assertTrue(not gpv("path\\file.txt"), "backwards slash")

    t.assertTrue(not gpv("äää.txt"), "name with non-ASCII")
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
