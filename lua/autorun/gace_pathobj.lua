
local path_meta = {
	Set = function(self, str)
		table.Empty(self.Parts)
		local spl = str:Split("/")

		for i,s in pairs(spl) do
			-- Skip empty parts
			if s ~= "" then
				table.insert(self.Parts, s)
			end
		end

		return self
	end,
	SetTable = function(self, tbl)
		self.Parts = tbl
		return self
	end,
	GetPart = function(self, idx)
		if idx < 0 then
			-- If negative (e.g. -1) we should start from the end (-1 -> #parts)
			idx = #self.Parts - (math.abs(idx)-1)
		end
		return self.Parts[idx]
	end,

	IsRoot = function(self)
		return #self.Parts == 0
	end,

	GetVFolder = function(self)
		return self:GetPart(1)
	end,
	GetFile = function(self)
		return self:GetPart(-1)
	end,

	Add = function(self, f)
		if type(f) == "table" then -- Assume another path
			return gace.NewPath(self:ToString() .. "/" .. f:ToString())
		end
		-- Assume a string
		return self:Add(gace.NewPath(f))
	end,

	-- Adds together and converts into a string
	Concat = function(self, f)
		return self:Add(f):ToString()
	end,

	Equals = function(self, f)
		return self:ToString() == f:ToString()
	end,

	-- Strips first part
	WithoutVFolder = function(self, f)
		return gace.NewPath(""):SetTable({unpack(self.Parts, 2)})
	end,

	-- Basically gets path one layer up
	WithoutFile = function(self, f)
		return gace.NewPath(""):SetTable({unpack(self.Parts, 1, #self.Parts-1)})
	end,

	ToString = function(self, str)
		return table.concat(self.Parts, "/")
	end
}
path_meta.__index = path_meta
path_meta.__tostring = path_meta.ToString
path_meta.__add = path_meta.Add
path_meta.__concat = path_meta.Concat
path_meta.__eq = path_meta.Equals

function gace.NewPath(s)
	local tbl = {Parts={}}
	setmetatable(tbl, path_meta)
	tbl:Set(s)
	return tbl
end
gace.Path = gace.NewPath -- alias

local gat = gace.AddTest
gat("Paths: Set paths", function(t)
	t.assertTrue(gace.Path(""):ToString() == "", "empty path's string must be empty")
	t.assertTrue(gace.Path("home/test/foo"):ToString() == "home/test/foo", "passing in stripped path")
	t.assertTrue(gace.Path("/home/test/foo"):ToString() == "home/test/foo", "stripping trailing slash")
	t.assertTrue(gace.Path("home/test/foo/"):ToString() == "home/test/foo", "stripping following slash")
	t.assertTrue(gace.Path("/home/test/foo/"):ToString() == "home/test/foo", "stripping trailing+following slash")
end)

gat("Paths: Add paths", function(t)
	t.assertTrue(gace.Path(""):Add("foo"):ToString() == "foo", "adding path to empty path")
	t.assertTrue(gace.Path("bar"):Add("foo"):ToString() == "bar/foo", "adding path to path")
	t.assertTrue(gace.Path("bar"):Add("foo/bar//soap"):ToString() == "bar/foo/bar/soap", "adding paths with empty parts")
	t.assertTrue(gace.Path("soap/seller"):Add(gace.Path("foo/bar")):ToString() == "soap/seller/foo/bar", "adding multi-part paths")
end)

gat("Paths: Operator overloading", function(t)
	t.assertTrue((gace.Path("foo") + gace.Path("bar")):ToString() == "foo/bar", "adding paths using __add")
	t.assertTrue((gace.Path("foo") .. gace.Path("bar")) == "foo/bar", "concatenating paths using __concat")

	t.assertTrue(gace.Path("foo/bar") == gace.Path("foo/bar/"), "testing path equality with __eq")
end)

gat("Paths: Invalid paths", function(t)
	t.assertTrue(gace.Path("/home//foo"):ToString() == "home/foo", "path with an empty part")
end)

gat("Paths: VFolders/Files", function(t)
	t.assertTrue(gace.Path("/home/foo/bar/"):GetVFolder() == "home", "vfolder from a path")
	t.assertTrue(gace.Path("/home/foo/bar/"):GetFile() == "bar", "file from a path")
	t.assertTrue(gace.Path("/home/foo/bar/"):WithoutVFolder():ToString() == "foo/bar", "path without a vfolder")
	t.assertTrue(gace.Path("/home/foo/bar/"):WithoutFile():ToString() == "home/foo", "path without a file")

	t.assertTrue(gace.Path("home"):WithoutVFolder():IsRoot(), "single part path without vfolder must be root")
end)