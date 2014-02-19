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

gat("VFolder file access rights", function()

	local fake_ply = CreateFakePly()

	assert(not gace.TestAccess("admin", fake_ply), "access granted when IsAdmin is false")

	fake_ply.is_admin = true
	assert(gace.TestAccess("admin", fake_ply), "access not granted when IsAdmin is true")

	assert(not gace.TestAccess("superadmin", fake_ply), "access granted when IsSuperAdmin is false (but IsAdmin true)")

	fake_ply.is_admin = false
	fake_ply.is_superadmin = true
	assert(gace.TestAccess("admin", fake_ply), "access not granted when IsSuperAdmin is true and access string is admin")

	assert(gace.TestAccess("user", fake_ply), "access not granted when usergroup is equal")

	assert(gace.TestAccess(function() return true end, fake_ply), "access not granted when given a true function")
	assert(not gace.TestAccess(function() return false end, fake_ply), "access granted when given a false function")

	assert(not gace.TestAccess("blabla", fake_ply), "access granted when given an invalid string")

	fake_ply.is_valid = false
	assert(gace.TestAccess("blabla", fake_ply), "access not granted when given an invalid string (but console)")

end)

gat("Virtual folder functions", {
	after = function(tbl)
		gace.RemoveVFolder("@@@TESTING@@@")
	end,
	runner = function(tbl)
		gace.SetupSimpleVFolder("@@@TESTING@@@", {
			["abc.txt"] = "Hello, this is abc",
			["file2.txt"] = "File 2 is da best",
			["foo"] = {
				["bar.txt"] = "Bars n' soap, we be rollin"
			}
		}, "admin")

		local fake_ply = CreateFakePly()

		assert(gace.MakeRecursiveListResponse(fake_ply, "").err == nil, "failed to recur-list root")
		assert(gace.ShallowEquals(gace.MakeRecursiveListResponse(fake_ply, "").tree.fol["@@@TESTING@@@"], {}), "listed vfolder with no access")
		assert(gace.MakeRecursiveListResponse(fake_ply, "@@@TESTING@@@").err == "No access", "listed vfolder folders with no access")

		fake_ply.is_admin = true

		assert(not gace.ShallowEquals(gace.MakeRecursiveListResponse(fake_ply, "").tree.fol["@@@TESTING@@@"], {}), "didn't list vfolder with access")
		assert(not gace.ShallowEquals(gace.MakeRecursiveListResponse(fake_ply, "@@@TESTING@@@").tree.fol, {}), "didn't list vfolder folders with access")
		assert(not gace.ShallowEquals(gace.MakeRecursiveListResponse(fake_ply, "@@@TESTING@@@").tree.fil, {}), "didn't list vfolder files with access")

		assert(gace.DeepEquals(
			gace.MakeListResponse(fake_ply, "@@@TESTING@@@"),
			{
				ret = "Success",
				type = "folder",
				files = {"abc.txt", "file2.txt"},
				folders = {"foo"}
			}
		), "list response doesn't match expected")

		assert(gace.DeepEquals(
			gace.MakeListResponse(fake_ply, "@@@TESTING@@@/foo"),
			{
				ret = "Success",
				type = "folder",
				files = {"bar.txt"},
				folders = {}
			}
		), "list response doesn't match expected")

		assert(gace.DeepEquals(
			gace.MakeListResponse(fake_ply, "@@@TESTING@@@/bar"),
			{
				err = "Doesn't exist"
			}
		), "list response doesn't match expected")

	end
})