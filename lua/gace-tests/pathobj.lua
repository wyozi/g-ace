local gat = gace.AddTest

gat("Path object: set paths", function(t)
	t.assertTrue(gace.Path(""):ToString() == "", "empty path's string must be empty")
	t.assertTrue(gace.Path("home/test/foo"):ToString() == "home/test/foo", "passing in stripped path")
	t.assertTrue(gace.Path("/home/test/foo"):ToString() == "home/test/foo", "stripping leading slash")
	t.assertTrue(gace.Path("home/test/foo/"):ToString() == "home/test/foo", "stripping trailing slash")
	t.assertTrue(gace.Path("/home/test/foo/"):ToString() == "home/test/foo", "stripping leading+trailing slash")
end)

gat("Path object: add paths", function(t)
	t.assertTrue(gace.Path(""):Add("foo"):ToString() == "foo", "adding path to empty path")
	t.assertTrue(gace.Path("bar"):Add("foo"):ToString() == "bar/foo", "adding path to path")
	t.assertTrue(gace.Path("bar"):Add("foo/bar//soap"):ToString() == "bar/foo/bar/soap", "adding paths with empty parts")
	t.assertTrue(gace.Path("soap/seller"):Add(gace.Path("foo/bar")):ToString() == "soap/seller/foo/bar", "adding multi-part paths")
end)

gat("Path object: operator overloading", function(t)
	t.assertTrue((gace.Path("foo") + gace.Path("bar")):ToString() == "foo/bar", "adding paths using __add")
	t.assertTrue((gace.Path("foo") .. gace.Path("bar")) == "foo/bar", "concatenating paths using __concat")

	t.assertTrue(gace.Path("foo/bar") == gace.Path("foo/bar/"), "testing path equality with __eq")
end)

gat("Path object: invalid paths", function(t)
	t.assertTrue(gace.Path("/home//foo"):ToString() == "home/foo", "path with an empty part")
	t.assertTrue(gace.Path("/home/../foo"):ToString() == "home/foo", "path with periods")
end)

gat("Path object: vfolders/files", function(t)
	t.assertTrue(gace.Path("/home/foo/bar/"):GetVFolder() == "home", "vfolder from a path")
	t.assertTrue(gace.Path("/home/foo/bar/"):GetFile() == "bar", "file from a path")
	t.assertTrue(gace.Path("/home/foo/bar/"):WithoutVFolder():ToString() == "foo/bar", "path without a vfolder")
	t.assertTrue(gace.Path("/home/foo/bar/"):WithoutFile():ToString() == "home/foo", "path without a file")

	t.assertTrue(gace.Path("home"):WithoutVFolder():IsRoot(), "single part path without vfolder must be root")
end)
