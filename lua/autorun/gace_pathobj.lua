
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
	GetVFolder = function(self)
		return self:GetPart(1)
	end,
	GetFile = function(self)
		return self:GetPart(-1)
	end,

	Add = function(self, f)
		-- Doesn't matter if there are extra slashes; they'll get stripped anyway
		return gace.NewPath(self:ToString() .. f)
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

function gace.NewPath(s)
	local tbl = {Parts={}}
	setmetatable(tbl, path_meta)
	tbl:Set(s)
	return tbl
end

local gat = gace.AddTest
gat("Paths: Set paths", function()
	assert(gace.NewPath(""):ToString() == "", "empty path's tostring not empty")
	assert(gace.NewPath("home/test/foo"):ToString() == "home/test/foo", "didn't strip trailing/following slashes")
	assert(gace.NewPath("/home/test/foo"):ToString() == "home/test/foo", "didn't strip trailing/following slashes")
	assert(gace.NewPath("/home/test/foo/"):ToString() == "home/test/foo", "didn't strip trailing/following slashes")
end)

gat("Paths: Invalid paths", function()
	assert(gace.NewPath("/home//foo"):ToString() == "home/foo", "didn't skip empty part")
end)

gat("Paths: VFolders/Files", function()
	assert(gace.NewPath("/home/foo/bar/"):GetVFolder() == "home", "didn't return correct vfolder")
	assert(gace.NewPath("/home/foo/bar/"):GetFile() == "bar", "didn't return correct file")
	assert(gace.NewPath("/home/foo/bar/"):WithoutVFolder():ToString() == "foo/bar", "didn't return correct path")
	assert(gace.NewPath("/home/foo/bar/"):WithoutFile():ToString() == "home/foo", "didn't return correct path")
end)