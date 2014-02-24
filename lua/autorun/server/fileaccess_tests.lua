local gat = gace.AddTest

local function CreateFakePly()
	return {
		is_admin = false, is_superadmin = false, is_valid = true, group = "user",
		IsSuperAdmin = function(self) return self.is_superadmin end,
		IsAdmin = function(self) return self.is_admin end,
		IsUserGroup = function(self, x) return x == self.group end,
		IsValid = function(self) return self.is_valid end
	}
end

gat("VFolder file access rights", function(t)

	local fake_ply = CreateFakePly()

	t.assertTrue(not gace.TestAccess("admin", fake_ply), "access granted when IsAdmin is false")

	fake_ply.is_admin = true
	t.assertTrue(gace.TestAccess("admin", fake_ply), "access not granted when IsAdmin is true")

	t.assertTrue(not gace.TestAccess("superadmin", fake_ply), "access granted when IsSuperAdmin is false (but IsAdmin true)")

	fake_ply.is_admin = false
	fake_ply.is_superadmin = true
	t.assertTrue(gace.TestAccess("admin", fake_ply), "access not granted when IsSuperAdmin is true and access string is admin")

	t.assertTrue(gace.TestAccess("user", fake_ply), "access not granted when usergroup is equal")

	t.assertTrue(gace.TestAccess(function() return true end, fake_ply), "access not granted when given a true function")
	t.assertTrue(not gace.TestAccess(function() return false end, fake_ply), "access granted when given a false function")

	t.assertTrue(not gace.TestAccess("blabla", fake_ply), "access granted when given an invalid string")

	fake_ply.is_valid = false
	t.assertTrue(gace.TestAccess("blabla", fake_ply), "access not granted when given an invalid string (but console)")

end)

gat("Virtual folder functions", {
	after = function()
		gace.RemoveVFolder("@@@TESTING@@@")
	end,
	runner = function(t)
		gace.SetupSimpleVFolder("@@@TESTING@@@", {
			["abc.txt"] = "Hello, this is abc",
			["file2.txt"] = "File 2 is da best",
			["foo"] = {
				["bar.txt"] = "Bars n' soap, we be rollin"
			}
		}, "admin")

		local fake_ply = CreateFakePly()

		t.assertTrue(gace.MakeRecursiveListResponse(fake_ply, "").err == nil, "recursively list root")
		--t.assertTrue(gace.ShallowEquals(gace.MakeRecursiveListResponse(fake_ply, "").tree.fol["@@@TESTING@@@"], {}), "see test vfolder in recursive root list")
		--t.assertTrue(gace.MakeRecursiveListResponse(fake_ply, "@@@TESTING@@@").err == "No access", "access denied to list test vfolder")

		fake_ply.is_admin = true

		--t.assertNonEqual(gace.MakeRecursiveListResponse(fake_ply, "").tree.fol["@@@TESTING@@@"], {}, "rec. list test vfolder in rec. root list")
		--t.assertNonEqual(gace.MakeRecursiveListResponse(fake_ply, "@@@TESTING@@@").tree.fol, {}, "rec. list vfolder folders")
		--t.assertNonEqual(gace.MakeRecursiveListResponse(fake_ply, "@@@TESTING@@@").tree.fil, {}, "rec. list vfolder files")

		t.assertDeepEquals(gace.MakeListResponse(fake_ply, "@@@TESTING@@@"),
			{
				ret = "Success",
				type = "folder",
				files = {"abc.txt", "file2.txt"},
				folders = {"foo"}
			},
		"list test vfolder")

		t.assertDeepEquals(
			gace.MakeListResponse(fake_ply, "@@@TESTING@@@/foo"),
			{
				ret = "Success",
				type = "folder",
				files = {"bar.txt"},
				folders = {}
			},
		"list subfolder in test vfolder")

		t.assertDeepEquals(
			gace.MakeListResponse(fake_ply, "@@@TESTING@@@/bar"),
			{
				err = "Doesn't exist"
			},
		"try to list nonexistent folder")

		t.assertDeepEquals(
			gace.MakeFetchResponse(fake_ply, "@@@TESTING@@@/abc.txt"),
			{
				ret = "Success",
				type = "file",
				content = "Hello, this is abc"
			},
		"fetch file contents")

		fake_ply.is_admin = false

		t.assertDeepEquals(
			gace.MakeFetchResponse(fake_ply, "@@@TESTING@@@/abc.txt"),
			{
				err = "No access"
			},
		"try to fetch with no access")

	end
})

gat("Virtual folder abuse", {
	after = function()
		gace.RemoveVFolder("@@@TESTING@@@")
	end,
	runner = function(t)
		local tbl = {}
		tbl.inception = tbl

		gace.SetupSimpleVFolder("@@@TESTING@@@", tbl, "admin")

		local fake_ply = CreateFakePly()
		fake_ply.is_admin = true

		--[[t.assertDeepEquals(gace.MakeRecursiveListResponse(fake_ply, "").tree.fol["@@@TESTING@@@"], {
			fol = {
				inception=  {
					fol = {
						inception=  {
							fol = {
								inception=  {
									fol = {
										inception=  {
											fil = {"ERR: TOO DEEP"}
										}
									}
								}
							}
						}
					}
				}
			}
		}, "recursivity limit")]]
	end
})