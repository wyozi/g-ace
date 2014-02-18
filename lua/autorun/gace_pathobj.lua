
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

function gace.NewPath(s)
	local tbl = {Parts={}}
	setmetatable(tbl, path_meta)
	tbl:Set(s)
	return tbl
end
gace.Path = gace.NewPath -- alias

local gat = gace.AddTest
gat("Paths: Set paths", function()
	assert(gace.Path(""):ToString() == "", "empty path's tostring not empty")
	assert(gace.Path("home/test/foo"):ToString() == "home/test/foo", "didn't strip trailing/following slashes")
	assert(gace.Path("/home/test/foo"):ToString() == "home/test/foo", "didn't strip trailing/following slashes")
	assert(gace.Path("/home/test/foo/"):ToString() == "home/test/foo", "didn't strip trailing/following slashes")
end)

gat("Paths: Add paths", function()
	assert(gace.Path(""):Add("foo"):ToString() == "foo", "invalid result from Add")
	assert(gace.Path("bar"):Add("foo"):ToString() == "bar/foo", "invalid result from Add")
	assert(gace.Path("bar"):Add("foo/bar//soap"):ToString() == "bar/foo/bar/soap", "invalid result from Add")
	assert(gace.Path("soap/seller"):Add(gace.Path("foo/bar")):ToString() == "soap/seller/foo/bar", "invalid result from Add")
end)

gat("Paths: Operator overloading", function()
	assert((gace.Path("foo") + gace.Path("bar")):ToString() == "foo/bar", "invalid result from Add")
	assert((gace.Path("foo") .. gace.Path("bar")) == "foo/bar", "invalid result from Concat")
end)

gat("Paths: Invalid paths", function()
	assert(gace.Path("/home//foo"):ToString() == "home/foo", "didn't skip empty part")
end)

gat("Paths: VFolders/Files", function()
	assert(gace.Path("/home/foo/bar/"):GetVFolder() == "home", "didn't return correct vfolder")
	assert(gace.Path("/home/foo/bar/"):GetFile() == "bar", "didn't return correct file")
	assert(gace.Path("/home/foo/bar/"):WithoutVFolder():ToString() == "foo/bar", "didn't return correct path")
	assert(gace.Path("/home/foo/bar/"):WithoutFile():ToString() == "home/foo", "didn't return correct path")
end)