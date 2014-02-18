
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
	ToString = function(self, str)
		return table.concat(self.Parts, "/")
	end
}
path_meta.__index = path_meta
path_meta.__tostring = path_meta.ToString

function gace.NewPath(s)
	local tbl = {Parts={}}
	setmetatable(tbl, path_meta)
	if s then tbl:Set(s) end
	return tbl
end

local gat = gace.AddTest
gat("Paths: Set paths", function()
	local path = gace.NewPath()
	assert(path:ToString() == "", "new path's tostring not empty")

	path:Set("home/test/foo")
	assert(path:ToString() == "home/test/foo", "path didn't strip trailing/following slashes")

	path:Set("/home/test/foo")
	assert(path:ToString() == "home/test/foo", "path didn't strip trailing/following slashes")

	path:Set("/home/test/foo/")
	assert(path:ToString() == "home/test/foo", "path didn't strip trailing/following slashes")

	path:Set("/home/test/foo/")
	assert(path:ToString() == "home/test/foo", "path didn't strip trailing/following slashes")
end)

gat("Paths: Invalid paths", function()
	local path = gace.NewPath()

	path:Set("/home//foo")
	assert(path:ToString() == "home/foo", "path didn't skip empty part")

end)